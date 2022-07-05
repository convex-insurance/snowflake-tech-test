terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.35"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

resource "snowflake_database" "CONVEX_TEST" {
  name     = "CONVEX_TEST"
}

resource "snowflake_table" "CUSTOMERS" {
  depends_on = [snowflake_database.CONVEX_TEST]
  database            = "CONVEX_TEST"
  schema              = "PUBLIC"
  name                = "CUSTOMERS"

  column {
    name     = "customer_id"
    type     = "string"
    nullable = true
  }

  column {
    name     = "loyalty_score"
    type     = "number"
    nullable = true

  }
}

resource "snowflake_table" "PRODUCTS" {
  depends_on = [snowflake_database.CONVEX_TEST]
  database            = "CONVEX_TEST"
  schema              = "PUBLIC"
  name                = "PRODUCTS"

  column {
    name     = "product_id"
    type     = "string"
    nullable = true
  }

  column {
    name     = "product_description"
    type     = "string"
    nullable = true
  }

  column {
    name     = "product_category"
    type     = "string"
    nullable = true
  }
}

resource "snowflake_table" "RAW_TRANSACTIONS" {
  depends_on = [snowflake_database.CONVEX_TEST]
  database            = "CONVEX_TEST"
  schema              = "PUBLIC"
  name                = "RAW_TRANSACTIONS"

  column {
    name     = "v"
    type     = "variant"
    nullable = true
  }
}

resource "snowflake_table" "CUSTOMER_TRANSACTIONS" {
  depends_on = [snowflake_database.CONVEX_TEST]
  database            = "CONVEX_TEST"
  schema              = "PUBLIC"
  name                = "CUSTOMER_TRANSACTIONS"

  column {
    name     = "customer_id"
    type     = "string"
    nullable = true
  }

  column {
    name     = "product_id"
    type     = "string"
    nullable = true
  }

  column {
    name     = "price"
    type     = "number"
    nullable = true
  }

  column {
    name     = "date_of_purchase"
    type     = "timestamp"
    nullable = true
  }
}

resource "snowflake_view" "CUSTOMER_PRODUCT_COUNT" {
  depends_on = [snowflake_database.CONVEX_TEST, snowflake_table.CUSTOMER_TRANSACTIONS, snowflake_table.CUSTOMERS, snowflake_table.PRODUCTS]
  database            = "CONVEX_TEST"
  schema              = "PUBLIC"
  name                = "CUSTOMER_PRODUCT_COUNT"

  statement  = <<-SQL
    SELECT c."customer_id", c."loyalty_score", p."product_id", p."product_category", count(*) as purchase_count
    FROM CONVEX_TEST.PUBLIC.CUSTOMER_TRANSACTIONS ct
    JOIN CONVEX_TEST.PUBLIC.CUSTOMERS c ON c."customer_id" = ct."customer_id"
    JOIN CONVEX_TEST.PUBLIC.PRODUCTS p ON p."product_id" = ct."product_id"
    GROUP BY c."customer_id", c."loyalty_score", p."product_id", p."product_category";
SQL
  or_replace = true
  is_secure  = false
}

resource "snowflake_file_format" "csv_format" {
  depends_on = [snowflake_database.CONVEX_TEST]
  name                = "CSV_FORMAT"
  database            = "CONVEX_TEST"
  schema              = "PUBLIC"
  format_type         = "CSV"
  field_delimiter     = ","
  skip_header         = 1
  empty_field_as_null = true
  validate_utf8 = true
}

resource "snowflake_file_format" "json_format" {
  depends_on = [snowflake_database.CONVEX_TEST]
  name              = "JSON_FORMAT"
  database          = "CONVEX_TEST"
  schema            = "PUBLIC"
  format_type       = "JSON"
  strip_outer_array = true
}

data "aws_caller_identity" "current" {}

locals {
  role_name = "snowflake_access_role"
  policy_name = "snowflake_access_policy"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name}"
}

resource snowflake_storage_integration S3_INTEGRATION {
  depends_on = [snowflake_database.CONVEX_TEST]
  name    = "S3_INTEGRATION"
  type    = "EXTERNAL_STAGE"

  enabled = true

  storage_allowed_locations = ["s3://convexbucket/"]

  storage_provider         = "S3"
  storage_aws_role_arn = local.role_arn
}

resource "snowflake_stage" "S3_STAGE_CSV" {
  depends_on = [snowflake_storage_integration.S3_INTEGRATION, snowflake_file_format.csv_format]
  name        = "S3_STAGE_CSV"
  url         = "s3://convexbucket/"
  database    = "CONVEX_TEST"
  schema      = "PUBLIC"
  storage_integration = "S3_INTEGRATION"
  file_format = "FORMAT_NAME = CONVEX_TEST.PUBLIC.CSV_FORMAT"
}

resource "snowflake_stage" "S3_STAGE_JSON" {
  depends_on = [snowflake_storage_integration.S3_INTEGRATION, snowflake_file_format.json_format]
  name        = "S3_STAGE_JSON"
  url         = "s3://convexbucket/"
  database    = "CONVEX_TEST"
  schema      = "PUBLIC"
  storage_integration = "S3_INTEGRATION"
  file_format = "FORMAT_NAME = CONVEX_TEST.PUBLIC.JSON_FORMAT"
}
