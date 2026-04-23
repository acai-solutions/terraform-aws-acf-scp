# AWS Service Control Policy (SCP) - ACF Terraform Module

<!-- LOGO -->
<a href="https://acai.gmbh">    
  <img src="https://github.com/acai-solutions/acai.public/raw/main/logo/logo_github_readme.png" alt="acai logo" title="ACAI" align="right" height="75" />
</a>

<!-- SHIELDS -->
[![Maintained by acai.gmbh][acai-shield]][acai-url]
[![documentation][acai-docs-shield]][acai-docs-url]  
![module-version-shield]  
![terraform-tested-shield]
![opentofu-tested-shield]  
![aws-tested-shield]
![aws-esc-tested-shield]  
![trivy-shield]
![checkov-shield]

<!-- BEGIN_ACAI_DOCS -->
[Terraform][terraform-url] module to provision and assign Service Control Policies (SCPs) to Organization Units or AWS accounts.
For SCP statements have a look at this repository: [terraform-aws-acf-scp-statements](https://github.com/acai-solutions/terraform-aws-acf-scp-statements)

![architecture]

### Features

- Provisions SCPs based on specified statements.
- Supports the use of wildcards in OU-Paths.

Must have Python3 and boto3 installed at the worker.

## Usage

Consider an AWS Organization with the following OU structure:

```text
/root
/root/CoreAccounts
/root/CoreAccounts/Connectivity
/root/CoreAccounts/Management
/root/CoreAccounts/Security
/root/SandboxAccounts
/root/WorkloadAccounts
/root/WorkloadAccounts/BusinessUnit_1
/root/WorkloadAccounts/BusinessUnit_1/CICD
/root/WorkloadAccounts/BusinessUnit_1/NonProd
/root/WorkloadAccounts/BusinessUnit_1/Prod
/root/WorkloadAccounts/BusinessUnit_2
/root/WorkloadAccounts/BusinessUnit_2/CICD
/root/WorkloadAccounts/BusinessUnit_2/NonProd
/root/WorkloadAccounts/BusinessUnit_2/Prod
/root/WorkloadAccounts/BusinessUnit_3
/root/WorkloadAccounts/BusinessUnit_3/CICD
/root/WorkloadAccounts/BusinessUnit_3/NonProd
/root/WorkloadAccounts/BusinessUnit_3/Prod
```

### Specifying SCP Statements

The module expects SCP specifications as a map. 

Each specification contains a policy_name and a list of statement_ids that correspond to entries in your SCP statements map.

For example, you can pull in SCP statements from the following repository:

For sample SCP statements have a look at this repository: [terraform-aws-acf-scp-statements](https://github.com/acai-solutions/terraform-aws-acf-scp-statements)

```hcl
module "scp_statements" {
  source = "git::https://github.com/acai-solutions/terraform-aws-acf-scp-statements.git?ref=1.0.0"
}

locals {
  scp_specifications = {
    "top_level" = {
      policy_name = "top_level"
      statement_ids = [
        "deny_root_user"
      ]
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
```

### Specifying SCP Assignments

SCPs can be assigned at both the OU and account levels.

The ou_assignments map pairs OU paths (which are case-sensitive) with lists of SCP policy names.
Accepts both formats: '/root/a/b' and '/root/a/b/'

!!! note "Information"
    The OU-Names are case-sensitive.

```hcl
  scp_assignments = {
    ou_assignments = {
      "/root/"                                 = ["top_level"]
      "/root/CoreAccounts"                     = ["core_accounts"]
      "/root/CoreAccounts/Management/"         = ["deny_vpc"]
      "/root/SandboxAccounts/"                 = []
      "/root/WorkloadAccounts/"                = ["workload"]
      "/root/WorkloadAccounts/BusinessUnit_1/" = ["workload_class1"]
      "/root/WorkloadAccounts/BusinessUnit_2/" = ["workload_class1"]
      "/root/WorkloadAccounts/BusinessUnit_3/" = ["workload_class2"]
      "/root/WorkloadAccounts/*/Prod/"         = ["workload_prod"]
      "/root/WorkloadAccounts/*/NonProd/"      = ["workload_non_prod"]
    }
    account_assignments = {
      "590183833356" = ["deny_vpc"] # core_logging
    }
  }
}
```

### Deploy SCP Assignments

Once you’ve defined your SCP statements, specifications, and assignments, deploy the ACF module as shown below:

```hcl
module "scp_management" {
  source = "git::https://github.com/acai-solutions/terraform-aws-acf-scp.git?ref=1.0.5"

  scp_statements     = module.scp_statements.scp_statements
  scp_specifications = local.scp_specifications
  scp_assignments    = local.scp_assignments
  providers = {
    aws = aws.org_mgmt_euc1
  }
}
```
<!-- END_ACAI_DOCS -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.47 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.47 |
| <a name="provider_external"></a> [external](#provider\_external) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_organizations_policy.scp_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.account_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.ou_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_ssm_parameter.module_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_iam_policy_document.scp_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_organizational_units.organization_inits](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [external_external.get_ou_ids](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_scp_specifications"></a> [scp\_specifications](#input\_scp\_specifications) | The statements of the SCPs. | <pre>map(object({<br/>    policy_name : string<br/>    description : optional(string, null)<br/>    statement_ids : list(string)<br/>    tags : optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_scp_statements"></a> [scp\_statements](#input\_scp\_statements) | The statements of the SCPs. | `map(string)` | n/a | yes |
| <a name="input_org_mgmt_reader_role_arn"></a> [org\_mgmt\_reader\_role\_arn](#input\_org\_mgmt\_reader\_role\_arn) | ARN to be assumed by the Python, to read the OU structure. Only required, if the provisioning pipeline is not in the context of the Org-Mgmt account. | `string` | `""` | no |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | A map of default tags to assign to the SCPs. | `map(string)` | `{}` | no |
| <a name="input_scp_assignments"></a> [scp\_assignments](#input\_scp\_assignments) | The assignements of SCPs. | <pre>object({<br/>    ou_assignments : optional(map(list(string)), {})      # key: ou-path, value: list of scp_ids to be assinged<br/>    account_assignments : optional(map(list(string)), {}) # key: account_id, value: list of scp_ids to be assinged<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_organizations_policy_account_attachment"></a> [aws\_organizations\_policy\_account\_attachment](#output\_aws\_organizations\_policy\_account\_attachment) | n/a |
| <a name="output_aws_organizations_policy_ou_attachment"></a> [aws\_organizations\_policy\_ou\_attachment](#output\_aws\_organizations\_policy\_ou\_attachment) | n/a |
| <a name="output_ou_paths_with_id"></a> [ou\_paths\_with\_id](#output\_ou\_paths\_with\_id) | n/a |
| <a name="output_ou_root_id"></a> [ou\_root\_id](#output\_ou\_root\_id) | n/a |
| <a name="output_scp_policies_details"></a> [scp\_policies\_details](#output\_scp\_policies\_details) | n/a |
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors

This module is maintained by [ACAI GmbH][acai-url].

<!-- LICENSE -->
## License

See [LICENSE][license-url] for full details.

<!-- COPYRIGHT -->
<br />
<br />
<p align="center">Copyright ACAI GmbH</p>

<!-- MARKDOWN LINKS & IMAGES -->
[acai-shield]: https://img.shields.io/badge/maintained_by-acai.gmbh-CB224B?style=flat
[acai-url]: https://acai.gmbh
[acai-docs-shield]: https://img.shields.io/badge/documentation-docs.acai.gmbh-CB224B?style=flat
[acai-docs-url]: https://docs.acai.gmbh/solution-acf/10_overview/
[module-version-shield]: https://img.shields.io/badge/module_version-1.2.0-CB224B?style=flat
[module-release-url]: ./releases
[terraform-tested-shield]: https://img.shields.io/badge/terraform-%3E%3D1.5.7_tested-844FBA?style=flat&logo=terraform&logoColor=white
[opentofu-tested-shield]: https://img.shields.io/badge/opentofu-%3E%3D1.6_tested-FFDA18?style=flat&logo=opentofu&logoColor=black
[aws-tested-shield]: https://img.shields.io/badge/AWS-%E2%9C%93_tested-FF9900?style=flat&logo=amazonaws&logoColor=white
[aws-esc-tested-shield]: https://img.shields.io/badge/AWS_ESC-%E2%9C%93_tested-003399?style=flat&logo=amazonaws&logoColor=white
[trivy-shield]: https://img.shields.io/badge/trivy-passed-green
[checkov-shield]: https://img.shields.io/badge/checkov-passed-green
[architecture]: ./docs/terraform-aws-acf-scp.png
[license-url]: ./LICENSE.md
[terraform-url]: https://www.terraform.io
[aws-url]: https://aws.amazon.com
