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
# ¦ CREATE PROVISIONER
# ---------------------------------------------------------------------------------------------------------------------
module "create_provisioner" {
  source = "../../cicd-principals/terraform"

  iam_role_settings = {
    name = "scp_cicd_provisioner"
    aws_trustee_arns = [
      "arn:${data.aws_partition.current.partition}:iam::${var.account_ids.org_mgmt}:root",
    ]
  }
  providers = {
    aws = aws.org_mgmt
  }
}

provider "aws" {
  region = var.aws_region
  alias  = "org_mgmt_provisioner"
  assume_role {
    role_arn = module.create_provisioner.iam_role_arn
  }
}
