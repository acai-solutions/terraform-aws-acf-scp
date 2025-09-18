# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = []
    }
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ CREATE PROVISIONER
# ---------------------------------------------------------------------------------------------------------------------
module "create_provisioner" {
  source = "../../cicd-principals/terraform"

  iam_role_settings = {
    name = "cicd_provisioner"
    aws_trustee_arns = [
      "arn:aws:iam::471112796356:root",
      "arn:aws:iam::471112796356:user/tfc_provisioner"
    ]
  }
  providers = {
    aws = aws.org_mgmt
  }
}

provider "aws" {
  region = "eu-central-1"
  alias  = "org_mgmt_euc1"
  assume_role {
    role_arn = module.create_provisioner.iam_role_arn
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" { provider = aws.org_mgmt_euc1 }
data "aws_caller_identity" "current" { provider = aws.org_mgmt_euc1 }

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # must not make sense from a logical point of view
  scp_specifications = {
    "top_level" = {
      policy_name = "top_level"
      statement_ids = [
        "deny_root_user"
      ]
      tags = {
        "priority" : "high"
      }
    }
    "core_accounts" = {
      policy_name = "core_accounts"
      statement_ids = [
        "deny_iam_users"
      ]
    }
    "core_account_non_connectivity" = {
      policy_name = "core_account_non_connectivity"
      statement_ids = [
        "deny_vpc"
      ]
    }
    "workload" = {
      policy_name = "workload"
      statement_ids = [
        "deny_vpc",
        "protect_security_resources",
      ]
    }
    "workload_class1" = {
      policy_name = "workload_class1"
      statement_ids = [
        "allow_services1",
      ]
    }
    "workload_class2" = {
      policy_name = "workload_class2"
      statement_ids = [
        "allow_services2",
      ]
    }
    "workload_prod" = {
      policy_name = "workload_prod"
      statement_ids = [
        "deny_regions_prod",
        "deny_iam_users",
      ]
    }
    "workload_non_prod" = {
      policy_name = "workload_non_prod"
      statement_ids = [
        "deny_regions_nonprod",
      ]
    }
    "deny_vpc" = {
      policy_name = "deny_vpc"
      statement_ids = [
        "deny_vpc",
      ]
    }
  }

  /*
Demo OU-Structure
/root
/root/SCP_CoreAccounts
/root/SCP_CoreAccounts/Connectivity
/root/SCP_CoreAccounts/Management
/root/SCP_CoreAccounts/Security
/root/SCP_SandboxAccounts
/root/SCP_WorkloadAccounts
/root/SCP_WorkloadAccounts/BusinessUnit_1
/root/SCP_WorkloadAccounts/BusinessUnit_1/CICD
/root/SCP_WorkloadAccounts/BusinessUnit_1/NonProd
/root/SCP_WorkloadAccounts/BusinessUnit_1/Prod
/root/SCP_WorkloadAccounts/BusinessUnit_2
/root/SCP_WorkloadAccounts/BusinessUnit_2/CICD
/root/SCP_WorkloadAccounts/BusinessUnit_2/NonProd
/root/SCP_WorkloadAccounts/BusinessUnit_2/Prod
/root/SCP_WorkloadAccounts/BusinessUnit_3
/root/SCP_WorkloadAccounts/BusinessUnit_3/CICD
/root/SCP_WorkloadAccounts/BusinessUnit_3/NonProd
/root/SCP_WorkloadAccounts/BusinessUnit_3/Prod
*/
  scp_assignments = {
    ou_assignments = {
      "/root"                                     = ["top_level"]
      "/root/SCP_CoreAccounts"                    = ["core_accounts"]
      "/root/SCP_CoreAccounts/Management"         = ["deny_vpc"]
      "/root/SCP_SandboxAccounts"                 = []
      "/root/SCP_WorkloadAccounts"                = ["workload"]
      "/root/SCP_WorkloadAccounts/BusinessUnit_1" = ["workload_class1"]
      "/root/SCP_WorkloadAccounts/BusinessUnit_2" = ["workload_class1"]
      "/root/SCP_WorkloadAccounts/BusinessUnit_3" = ["workload_class2"]
      "/root/SCP_WorkloadAccounts/*/Prod"         = ["workload_prod"]
      "/root/SCP_WorkloadAccounts/*/NonProd"      = ["workload_non_prod"]
    }
    account_assignments = {
      "590183833356" = ["deny_vpc"] # core_logging
    }
  }
}



module "scp_statements" {
  source = "./scp_statements"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ AWS SCP MANAGEMENT
# ---------------------------------------------------------------------------------------------------------------------
module "scp_management" {
  source = "../../"

  scp_statements     = module.scp_statements.scp_statements
  scp_specifications = local.scp_specifications
  scp_assignments    = local.scp_assignments
  providers = {
    aws = aws.org_mgmt_euc1
  }
  depends_on = [
    module.ou_structure,
    module.create_provisioner
  ]
}


