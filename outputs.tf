# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "ou_root_id" {
  value = local.root_ou_id
}

output "ou_paths_with_id" {
  value = local.ou_paths_with_id
}

output "scp_policies_details" {
  value = {
    for key, policy in aws_organizations_policy.scp_policies : key => {
      name          = policy.name
      arn           = policy.arn
      scp_id        = policy.id
      policy_length = length(policy.content)
    }
  }
}

output "aws_organizations_policy_ou_attachment" {
  value = aws_organizations_policy_attachment.ou_attachment
}

output "aws_organizations_policy_account_attachment" {
  value = aws_organizations_policy_attachment.account_attachment
}