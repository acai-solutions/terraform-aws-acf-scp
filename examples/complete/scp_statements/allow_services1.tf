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
data "aws_iam_policy_document" "allow_services1" {
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
}
