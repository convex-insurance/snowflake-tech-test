output "storage_aws_iam_user_arn" {
  value = snowflake_storage_integration.S3_INTEGRATION.storage_aws_iam_user_arn
}

output "storage_aws_external_id" {
  value = snowflake_storage_integration.S3_INTEGRATION.storage_aws_external_id
}
