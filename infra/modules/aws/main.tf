locals {
  role_name = "snowflake_access_role"
  policy_name = "snowflake_access_policy"
}

resource "aws_iam_policy" "snowflake_access_policy" {
  name        = local.policy_name
  path        = "/"
  description = "Allow Snowflake users to access S3 bucket."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
            "Effect": "Allow",
            "Action": [
                "kms:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role" "snowflake_access_role" {
  depends_on = [aws_iam_policy.snowflake_access_policy]
  name = local.role_name
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Action" : "sts:AssumeRole"
        "Effect" : "Allow"
        "Principal" : {
          "AWS" : var.storage_aws_iam_user_arn
        }
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : var.storage_aws_external_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "snowflake_access_policy_to_snowflake_access_role" {
  depends_on = [aws_iam_policy.snowflake_access_policy, aws_iam_role.snowflake_access_role]
  role       = aws_iam_role.snowflake_access_role.name
  policy_arn = aws_iam_policy.snowflake_access_policy.arn
}
