# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


variable "scp_statements" {
  description = "The statements of the SCPs."
  type        = map(string) # key: statement_id, value: statement-json
}

variable "scp_specifications" {
  description = "The statements of the SCPs."
  # key: scp_id, value: specified object 
  type = map(object({
    policy_name : string
    description : optional(string, null)
    statement_ids : list(string)
    tags : optional(map(string), {})
  }))
}

variable "scp_assignments" {
  description = "The assignements of SCPs."
  type = object({
    ou_assignments : optional(map(list(string)), {})      # key: ou-path, value: list of scp_ids to be assinged
    account_assignments : optional(map(list(string)), {}) # key: account_id, value: list of scp_ids to be assinged
  })
  default = null
}

variable "org_mgmt_reader_role_arn" {
  description = "ARN to be assumed by the Python, to read the OU structure. Only required, if the provisioning pipeline is not in the context of the Org-Mgmt account."
  type        = string
  default     = ""
}

variable "resource_tags" {
  description = "A map of default tags to assign to the SCPs."
  type        = map(string)
  default     = {}
}
