# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


data "aws_iam_policy_document" "protect_security_resources" {
  statement {
    sid    = "ProtectSecurityResources"
    effect = "Deny"
    resources = [
      "*"
    ]

    actions = [
      "cloudtrail:DeleteTrail",
      "cloudtrail:PutEventSelectors",
      "cloudtrail:StopLogging",
      "securityhub:DisassociateFromMasterAccount",
      "securityhub:DisableSecurityHub",
      "guardduty:Delete*",
      "guardduty:Disassociate*",
      "guardduty:Stop*",
      "guardduty:Update*",
      "config:DeleteConfigurationAggregator",
      "config:PutConfigurationAggregator",
    ]
  }
  statement {
    sid       = "ProtectEbsEncryptionByDefault"
    effect    = "Deny"
    resources = ["*"]
    actions   = ["ec2:DisableEbsEncryptionByDefault"]
  }
}
