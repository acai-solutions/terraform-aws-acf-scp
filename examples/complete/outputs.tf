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

output "ou_structure_paths" {
  description = "ou_structure_paths"
  value       = module.ou_structure.organizational_units_paths_ids
}

output "scp_management" {
  description = "scp_management"
  value       = module.scp_management
}

output "test_success" {
  description = "test_success"
  value = (
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root <- top_level") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_CoreAccounts <- core_accounts") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts <- workload") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts/BusinessUnit_1 <- workload_class1") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts/BusinessUnit_1/Prod <- workload_prod") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts/BusinessUnit_2/NonProd <- workload_non_prod") &&
    contains(keys(module.scp_management.aws_organizations_policy_ou_attachment), "/root/SCP_WorkloadAccounts/BusinessUnit_3/NonProd <- workload_non_prod") &&
    contains(keys(module.scp_management.aws_organizations_policy_account_attachment), "590183833356 <- deny_vpc")
  )
}
