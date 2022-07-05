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

provider "snowflake" {
  role = "ACCOUNTADMIN"
}

provider "aws" {}



module "snowflake" {
  source = "../modules/snowflake"
}

module "aws" {
  source = "../modules/aws"
  storage_aws_iam_user_arn = module.snowflake.storage_aws_iam_user_arn
  storage_aws_external_id = module.snowflake.storage_aws_external_id
  depends_on = [module.snowflake]
}
