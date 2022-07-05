from prefect import Flow, task, Parameter
from prefect.client import Secret
from prefect.tasks.snowflake import SnowflakeQuery

from main_data_generator import generate_sample_data, exportDataToS3

# set Secret parameters in ~/.prefect/config.toml, refer to
snowflake_query = SnowflakeQuery(
    account=Secret("SNOWFLAKE_ACCOUNT").get(),
    user=Secret("SNOWFLAKE_USER").get(),
    password=Secret("SNOWFLAKE_PASSWORD").get(),
    warehouse="COMPUTE_WH",
    database="CONVEX_TEST",
    schema="PUBLIC"
)

insert_customers_data_query = """
            INSERT INTO
                CUSTOMERS
            SELECT
                t.$1,
                t.$2
            FROM
                @S3_stage_csv (
                    file_format => 'CSV_FORMAT',
                    pattern => '.*customers.csv'
                ) t;
            """

insert_products_data_query = """
            INSERT INTO
                CONVEX_TEST.PUBLIC.PRODUCTS
            SELECT
                t.$1,
                t.$2,
                t.$3
            FROM
                @S3_stage_csv (
                    file_format => 'CSV_FORMAT',
                    pattern => '.*products.csv'
                ) t;
            """

insert_transactions_data_query = """
            COPY INTO CONVEX_TEST.PUBLIC.RAW_TRANSACTIONS
            FROM
                @S3_stage_json pattern = '.*transactions.json';
            """

insert_customer_transactions_data_query = """
            INSERT INTO
                CUSTOMER_TRANSACTIONS
            SELECT
                t."v":customer_id::string,
                flatten_basket.value:product_id::string,
                flatten_basket.value:price::number,
                t."v":date_of_purchase::timestamp
            FROM
                RAW_TRANSACTIONS t,
                table(flatten(t."v":basket)) flatten_basket;
            """

@task
def generate_and_upload_sample_data():
    generate_sample_data()
    exportDataToS3()

with Flow("load-data-flow") as flow:
    generate_and_upload_sample_data_result = generate_and_upload_sample_data()
    snowflake_query(query=insert_customers_data_query, upstream_tasks=[generate_and_upload_sample_data_result])
    snowflake_query(query=insert_products_data_query, upstream_tasks=[generate_and_upload_sample_data_result])
    insert_transactions_data_result = snowflake_query(query=insert_transactions_data_query, upstream_tasks=[generate_and_upload_sample_data_result])
    snowflake_query(query=insert_customer_transactions_data_query, upstream_tasks=[insert_transactions_data_result])

flow.run()
