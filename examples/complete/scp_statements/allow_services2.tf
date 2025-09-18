# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


# Never combine two deny not_action statements with disjunct not_actions in single "OU-Hierarchy-Path"
# Specify permitted services in a single statement / SCP. They cannot be accumulated across multiple statements.
data "aws_iam_policy_document" "allow_services2" {
  statement {
    sid       = "AllowServices"
    effect    = "Deny"
    resources = ["*"]

    not_actions = [
      "access-analyzer:*",
      "acm:*",
      "airflow:*",
      "apigateway:*",
      "applicationinsights:*",
      "appmesh:*",
      "aps:*",
      "athena:*",
      "aws-marketplace:Subscribe",
      "aws-marketplace:Unsubscribe",
      "backup:*",
      "backup-storage:*",
      "bedrock:*",
      "ce:*",
      "cloudformation:*",
      "cloudfront:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "codebuild:*",
      "codecommit:*",
      "codedeploy:*",
      "codepipeline:*",
      "codestar:*",
      "codestar-connections:*",
      "codestar-notifications:*",
      "config:t*",
      "cost-optimization-hub:*",
      "dynamodb:*",
      "ec2:*",
      "ecr:*",
      "ecs:*",
      "eks:*",
      "elasticache:*",
      "elasticbeanstalk:*",
      "elasticfilesystem:*",
      "elasticloadbalancing:*",
      "elasticmapreduce:*",
      "es:*",
      "events:*",
      "firehose:*",
      "fsx:*",
      "glue:*",
      "iam:*",
      "kafka:*",
      "kafka-cluster:*",
      "kinesis:*",
      "kms:*",
      "lambda:*",
      "logs:*",
      "mq:*",
      "pricing:*",
      "rds:*",
      "redshift:*",
      "resource-explorer-2:*",
      "route53:*",
      "s3:*",
      "s3-object-lambda:*",
      "sagemaker:*",
      "schemas:*",
      "secretsmanager:*",
      "securityhub:*",
      "servicecatalog:*",
      "ses:*",
      "sns:*",
      "sqs:*",
      "ssm:*",
      "states:*",
      "sts:*",
      "support:*",
      "tag:*",
      "timestream:*",
      "transfer:*",
      "translate:*",
      "trustedadvisor:*",
      "wellarchitected:*",
    ]
  }

  # Deny all marketplace solutions except bedrock ones
  statement {
    sid       = "MarketplaceBedrockOnly"
    effect    = "Deny"
    resources = ["*"]

    actions = [
      "aws-marketplace:Subscribe"
    ]

    condition {
      test     = "ForAllValues:StringNotEqualsIfExists"
      variable = "aws-marketplace:ProductId"

      values = [
        "1d288c71-65f9-489a-a3e2-9c7f4f6e6a85", # Jurassic-2 Mid (Amazon Bedrock Edition)
        "cc0bdd50-279a-40d8-829c-4009b77a1fcc", # Jurassic-2 Ultra (Amazon Bedrock Edition)
        "c468b48a-84df-43a4-8c46-8870630108a7", # Claude (Amazon Bedrock Edition)
        "99d90be8-b43e-49b7-91e4-752f3866c8c7", # Claude (100K) (Amazon Bedrock Edition)
        "b0eb9475-3a2c-43d1-94d3-56756fd43737", # Claude Instant (Amazon Bedrock Edition)
        "d0123e8d-50d6-4dba-8a26-3fed4899f388", # SDXL Beta V0.8 (Amazon Bedrock Edition)
        "a61c46fe-1747-41aa-9af0-2e0ae8a9ce05", # Cohere Generate Model - Command (Amazon Bedrock Edition)
        "216b69fd-07d5-4c7b-866b-936456d68311", # Placeholder for future use
        "b7568428-a1ab-46d8-bab3-37def50f6f6a", # Cohere Embed Model - English (Amazon Bedrock Edition)
        "38e55671-c3fe-4a44-9783-3584906e7cad", # Placeholder for future use
        "prod-ariujvyzvd2qy",                   # Placeholder for future use
        "prod-2c2yc2s3guhqy",                   # Meta Llama 2 Chat 70B (Amazon Bedrock Edition)
        "prod-6dw3qvchef7zy",                   # Anthropic's Claude 3 Sonnet (Amazon Bedrock Edition)
        "prod-ozonys2hmmpeu"                    # Anthropic's Claude 3 Haiku (Amazon Bedrock Edition)
      ]
    }
  }
}
