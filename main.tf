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
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_organizations_organization" "organization" {}
data "aws_organizations_organizational_units" "organization_inits" {
  parent_id = data.aws_organizations_organization.organization.roots[0].id
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  resource_tags = merge(
    var.resource_tags,
    {
      "module_provider" = "ACAI GmbH",
      "module_name"     = "terraform-aws-acf-scp",
      "module_source"   = "github.com/acai-consulting/terraform-aws-acf-scp",
      "module_version"  = /*inject_version_start*/ "1.1.0" /*inject_version_end*/
    }
  )
  org_id     = data.aws_organizations_organization.organization.id
  root_ou_id = data.aws_organizations_organization.organization.roots[0].id
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "external" "get_ou_ids" {
  program = [
    "python3",
    "${path.module}/python/get_ou_ids.py",
    local.org_id,
    local.root_ou_id,
    jsonencode(var.scp_assignments.ou_assignments),
    var.org_mgmt_reader_role_arn
  ]
}

locals {
  ou_paths_with_id = jsondecode(data.external.get_ou_ids.result["result"])
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ RESOURCES
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "scp_policies" {
  for_each = var.scp_specifications

  source_policy_documents = [for sid in each.value.statement_ids : var.scp_statements[sid]]
}

resource "aws_organizations_policy" "scp_policies" {
  for_each = var.scp_specifications

  name        = each.value.policy_name
  description = each.value.description
  content     = jsonencode(jsondecode(data.aws_iam_policy_document.scp_policies[each.key].json))
  tags        = merge(local.resource_tags, each.value.tags)
}

# Attach to Organizational Units
resource "aws_organizations_policy_attachment" "ou_attachment" {
  for_each = merge([
    for ou_id, ou_info in local.ou_paths_with_id : {
      for scp_name in ou_info.assignments : "${ou_info.path_name} <- ${scp_name}" => {
        "ou_id"    = ou_id,
        "scp_name" = scp_name
      }
    }
  ]...)

  policy_id = aws_organizations_policy.scp_policies[each.value.scp_name].id
  target_id = each.value.ou_id # OU ID is expected here
}

# Attach to Accounts
resource "aws_organizations_policy_attachment" "account_attachment" {
  for_each = merge([
    for acct_id, scps in var.scp_assignments.account_assignments : {
      for scp_name in scps : "${acct_id} <- ${scp_name}" => {
        "acct_id"  = acct_id,
        "scp_name" = scp_name
      }
    }
  ]...)

  policy_id = aws_organizations_policy.scp_policies[each.value.scp_name].id
  target_id = each.value.acct_id # Account ID is expected here
}

