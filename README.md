
<!-- BEGIN_TF_DOCS -->
# terraform-google-oidc-gitlab

[![Releases](https://img.shields.io/github/v/release/wisk-aero-oss/terraform-google-oidc-gitlab)](https://github.com/wisk-aero-oss/terraform-google-oidc-gitlab/releases)

[Terraform Module Registry](https://registry.terraform.io/modules/wisk-aero-oss/oidc-gitlab/google)

Template for creating a Terraform module for Google

## Features

- base terraform files
- pre-commit setup
- GitHub actions setup

## Usage

Basic usage of this module is as follows:

```hcl
module "example" {
    source = "wisk-aero-oss/<module-name>/google"
    # Recommend pinning every module to a specific version
    # version = "x.x.x"
    # Required variables
        pool_id =
        project_id =
        provider_id =
        service_accounts =
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.1 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 7.9.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_folder_iam_member.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_iam_workload_identity_pool.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_organization_iam_member.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_project_iam_member.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.wif-sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [http_http.jwk](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_audiences"></a> [allowed\_audiences](#input\_allowed\_audiences) | Workload Identity Pool Provider allowed audiences. | `list(string)` | `[]` | no |
| <a name="input_attribute_condition"></a> [attribute\_condition](#input\_attribute\_condition) | Workload Identity Pool Provider attribute condition expression. [More info](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#attribute_condition) | `string` | `null` | no |
| <a name="input_attribute_mapping"></a> [attribute\_mapping](#input\_attribute\_mapping) | Workload Identity Pool Provider attribute mapping. [More info](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#attribute_mapping) | `map(any)` | <pre>{<br/>  "attribute.aud": "assertion.aud",<br/>  "attribute.namespace_id": "assertion.namespace_id",<br/>  "attribute.namespace_path": "assertion.namespace_path",<br/>  "attribute.project_id": "assertion.project_id",<br/>  "attribute.project_path": "assertion.project_path",<br/>  "attribute.ref": "assertion.ref",<br/>  "attribute.ref_type": "assertion.ref_type",<br/>  "attribute.user_email": "assertion.user_email",<br/>  "google.subject": "assertion.sub"<br/>}</pre> | no |
| <a name="input_issuer_uri"></a> [issuer\_uri](#input\_issuer\_uri) | Workload Identity Pool Issuer URL | `string` | `"https://gitlab.com"` | no |
| <a name="input_pool_description"></a> [pool\_description](#input\_pool\_description) | Workload Identity Pool description | `string` | `"Workload Identity Pool managed by Terraform"` | no |
| <a name="input_pool_display_name"></a> [pool\_display\_name](#input\_pool\_display\_name) | Workload Identity Pool display name | `string` | `null` | no |
| <a name="input_pool_id"></a> [pool\_id](#input\_pool\_id) | Workload Identity Pool ID | `string` | n/a | yes |
| <a name="input_private_server"></a> [private\_server](#input\_private\_server) | Provider (GitLab) server is private? | `bool` | `true` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project id to create Workload Identity Pool | `string` | n/a | yes |
| <a name="input_provider_description"></a> [provider\_description](#input\_provider\_description) | Workload Identity Pool Provider description | `string` | `"Workload Identity Pool Provider managed by Terraform"` | no |
| <a name="input_provider_display_name"></a> [provider\_display\_name](#input\_provider\_display\_name) | Workload Identity Pool Provider display name | `string` | `null` | no |
| <a name="input_provider_id"></a> [provider\_id](#input\_provider\_id) | Workload Identity Pool Provider id | `string` | n/a | yes |
| <a name="input_service_accounts"></a> [service\_accounts](#input\_service\_accounts) | Service account to manage and link to WIF | <pre>map(object({<br/>    # WIF provider attributes. If attribute is set to `*` all identities in the pool are granted access to SAs.<br/>    attributes = list(string)<br/>    bindings = list(object({<br/>      resource_id   = string<br/>      resource_type = string<br/>      roles         = list(string)<br/>    }))<br/>    description  = string<br/>    display_name = string<br/>    project      = string<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pool_name"></a> [pool\_name](#output\_pool\_name) | Pool name |
| <a name="output_provider_name"></a> [provider\_name](#output\_provider\_name) | Provider name |
| <a name="output_sa_mappings"></a> [sa\_mappings](#output\_sa\_mappings) | WIF service account attribute mappings |
| <a name="output_sa_roles"></a> [sa\_roles](#output\_sa\_roles) | Roles to bind to ervice accounts |

<!-- END_TF_DOCS -->
