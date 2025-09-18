# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


data "aws_iam_policy_document" "deny_vpc" {
  statement {
    sid       = "DenyVpc"
    effect    = "Deny"
    resources = ["*"]
    # not comprehensive, only for demo purposes
    actions = [
      "ec2:CreateVpc",
      "ec2:ModifyVpc",
      "ec2:DeleteVpc",
    ]
  }
}
