module "new_account_iam_role" {
  source = "../../"

  assume_role_name       = "data.aws_caller_identity.current.account_id"
  role_name              = "E_READONLY_TEST"
  role_permission_policy = "ReadOnlyAccess"
  trust_policy_json      = local.test_trust_policy_json
}

locals {
  trust_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "AWS": "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
          },
          "Effect": "Allow"
        }
      ]
    }
    EOF

  // This policy doesn't accomplish a trust relationship, but it is valid
  // JSON and doesn't expose an organization account ID.
  test_trust_policy_json = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "AWS": "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
          },
          "Effect": "Allow",
        },
      ]
    }
    EOF

  test_id = data.terraform_remote_state.prereq.outputs.random_string.result
  function_name = "new_account_iam_role_${local.test_id}"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_lambda_invocation" "test_run" {
  function_name = local.function_name

  input = <<JSON
{
  "eventType": "TestRun",
  "source": "aws.organizations",
  "detail-type": "AWS API Call via CloudTrail",
  "detail": {}
}
JSON
}

data "terraform_remote_state" "prereq" {
  backend = "local"
  config  = {
    path = "prereq/terraform.tfstate"
  }
}

resource "aws_iam_role" "this" {
  assume_role_policy = local.trust_policy
}

output "result_entry" {
  description = "String containing JSON with version numbers of python imports"
  value       = jsondecode(data.aws_lambda_invocation.test_run.result)
}
