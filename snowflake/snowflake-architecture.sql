CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id string,
    loyalty_score number
);

CREATE OR REPLACE TABLE PRODUCTS (
    product_id string,
    product_description string,
    product_category string
);

CREATE OR REPLACE TABLE RAW_TRANSACTIONS (
    v variant
);

CREATE OR REPLACE TABLE CUSTOMER_TRANSACTIONS(
    customer_id string,
    product_id string,
    price number,
    date_of_purchase timestamp
)

CREATE OR REPLACE STORAGE INTEGRATION S3_integration
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = '<AWS-ROLE-ARN>'
STORAGE_ALLOWED_LOCATIONS = ('s3://convexbucket/');

CREATE OR REPLACE FILE FORMAT csv_format
TYPE = CSV
FIELD_DELIMITER = ','
SKIP_HEADER = 1
NULL_IF = ('NULL', 'null')
EMPTY_FIELD_AS_NULL = true;

CREATE OR REPLACE STAGE S3_STAGE_CSV
STORAGE_INTEGRATION = S3_integration
URL = 's3://convexbucket/'
FILE_FORMAT = csv_format;

CREATE OR REPLACE STAGE S3_STAGE_JSON
STORAGE_INTEGRATION = S3_integration
URL = 's3://convexbucket/'
FILE_FORMAT = json_format;

CREATE OR REPLACE FILE FORMAT json_format
TYPE = 'JSON'
STRIP_OUTER_ARRAY = TRUE;

CREATE OR REPLACE VIEW CUSTOMER_PRODUCT_COUNT AS
SELECT c."customer_id", c."loyalty_score", p."product_id", p."product_category", count(*) as purchase_count
FROM CONVEX_TEST.PUBLIC.CUSTOMER_TRANSACTIONS ct
JOIN CONVEX_TEST.PUBLIC.CUSTOMERS c ON c."customer_id" = ct."customer_id"
JOIN CONVEX_TEST.PUBLIC.PRODUCTS p ON p."product_id" = ct."product_id"
GROUP BY c."customer_id", c."loyalty_score", p."product_id", p."product_category";

