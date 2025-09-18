# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


data "aws_iam_policy_document" "deny_regions_prod" {
  statement {
    sid       = "DenyServicesOutsideEuc1Use2"
    effect    = "Deny"
    resources = ["*"]

    not_actions = [
      "a4b:*",
      "access-analyzer:*",
      "acm:*",
      "aws-marketplace-management:*",
      "aws-marketplace:*",
      "aws-portal:*",
      "awsbillingconsole:*",
      "budgets:*",
      "ce:*",
      "chime:*",
      "cloudfront:*",
      "cloudformation:List*",
      "cloudformation:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "config:*",
      "cur:*",
      "directconnect:*",
      "ec2:DescribeRegions",
      "ec2:DescribeTransitGateways",
      "ec2:DescribeVpnGateways",
      "fms:*",
      "globalaccelerator:*",
      "grafana:*",
      "health:*",
      "iam:*",
      "importexport:*",
      "kms:*",
      "mobileanalytics:*",
      "networkmanager:*",
      "organizations:*",
      "pricing:*",
      "route53:*",
      "route53domains:*",
      "route53resolver:Get*",
      "route53resolver:List*",
      "s3:*",
      "shield:*",
      "sts:*",
      "support:*",
      "sns:*",
      "trustedadvisor:*",
      "waf-regional:*",
      "waf:*",
      "wafv2:*",
      "wellarchitected:*",
      "cloudtrail:*",
      "account:Get*",
      "cost-optimization-hub:*",
      "compute-optimizer:*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"

      values = [
        "eu-central-1",
        "us-east-2"
      ]
    }
  }
}
