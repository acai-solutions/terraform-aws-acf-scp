# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "account_id" {
  description = "AWS Account ID number of the account that owns or contains the calling entity."
  value       = data.aws_caller_identity.current.account_id
}

output "ou_paths_to_ou_id" {
  description = "Mapping of OU paths to their corresponding OU IDs."
  value       = module.ou_structure.ou_paths_to_ou_id
}

output "scp_management" {
  description = "SCP management module output."
  value       = module.scp_management
}

output "test_success" {
  description = "Indicates whether the SCP management test was successful."
  value = (
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root <- top_level") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_CoreAccounts <- core_accounts") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts <- workload") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts/BusinessUnit_1 <- workload_class1") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts/BusinessUnit_1/Prod <- workload_prod") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts/BusinessUnit_2/NonProd <- workload_non_prod") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts/BusinessUnit_3/NonProd <- workload_non_prod") &&
    contains(keys(module.scp_management.aws_organizations_policy_account_attachment), "${var.account_ids.workload} <- deny_vpc")
  )
}
