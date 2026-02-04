
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
        project_id =
        service_accounts =
        wif_identity_roles =
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
| <a name="provider_google"></a> [google](#provider\_google) | 7.18.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_sa_permissions"></a> [sa\_permissions](#module\_sa\_permissions) | wisk-aero-oss/iam-members/google | 0.2.2 |

## Resources

| Name | Type |
|------|------|
| [google_iam_workload_identity_pool.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_project_iam_member.wif_identity](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.sa-sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_service_account_iam_member.wif-sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [http_http.jwk](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_audiences"></a> [allowed\_audiences](#input\_allowed\_audiences) | Workload Identity Pool Provider allowed audiences. | `list(string)` | <pre>[<br/>  "https://gitlab.com"<br/>]</pre> | no |
| <a name="input_attribute_mapping"></a> [attribute\_mapping](#input\_attribute\_mapping) | Workload Identity Pool Provider attribute mapping. [More info](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#attribute_mapping) | `map(any)` | <pre>{<br/>  "attribute.aud": "assertion.aud",<br/>  "attribute.namespace_id": "assertion.namespace_id",<br/>  "attribute.namespace_path": "assertion.namespace_path",<br/>  "attribute.project_id": "assertion.project_id",<br/>  "attribute.project_path": "assertion.project_path",<br/>  "attribute.project_reftype_ref": "assertion.project_path + assertion.ref_type + assertion.ref",<br/>  "attribute.ref": "assertion.ref",<br/>  "attribute.ref_type": "assertion.ref_type",<br/>  "attribute.user_email": "assertion.user_email",<br/>  "google.subject": "assertion.sub"<br/>}</pre> | no |
| <a name="input_issuer_uri"></a> [issuer\_uri](#input\_issuer\_uri) | Workload Identity Pool Issuer URL | `string` | `"https://gitlab.com"` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | GCP Organization ID for access to custom organization roles | `string` | `""` | no |
| <a name="input_private_server"></a> [private\_server](#input\_private\_server) | Provider (GitLab) server is private? | `bool` | `true` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project id to create Workload Identity Pool | `string` | n/a | yes |
| <a name="input_service_accounts"></a> [service\_accounts](#input\_service\_accounts) | Service account to manage and link to WIF | <pre>map(object({<br/>    # WIF provider attributes. If attribute is set to `*` all identities in the pool are granted access to SAs.<br/>    #attributes = list(string)<br/>    attributes = list(object({<br/>      attribute = string<br/>      pool      = string<br/>      provider  = string<br/>    }))<br/>    bindings = list(object({<br/>      resource_id   = string<br/>      resource_type = string<br/>      roles         = list(string)<br/>    }))<br/>    can_impersonate = optional(list(string), [])<br/>    description     = string<br/>    display_name    = string<br/>    #pool = string<br/>    project = string<br/>  }))</pre> | n/a | yes |
| <a name="input_wif_identity_roles"></a> [wif\_identity\_roles](#input\_wif\_identity\_roles) | Roles to grant to WIF identities | <pre>list(object({<br/>    attribute = string<br/>    pool      = string<br/>    provider  = string<br/>    roles     = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_wif_pools"></a> [wif\_pools](#input\_wif\_pools) | Workload Identity Federation Pools | <pre>map(object({<br/>    # key = pool ID<br/>    description  = string<br/>    display_name = string<br/>    providers = map(object({<br/>      # key provider ID<br/>      description         = string<br/>      display_name        = string<br/>      attribute_condition = optional(string, "")<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pool_name"></a> [pool\_name](#output\_pool\_name) | Pool name |
| <a name="output_provider_name"></a> [provider\_name](#output\_provider\_name) | Provider name |
| <a name="output_sa_emails"></a> [sa\_emails](#output\_sa\_emails) | Service Account emails |
| <a name="output_sa_mappings"></a> [sa\_mappings](#output\_sa\_mappings) | WIF service account attribute mappings |
| <a name="output_sa_roles"></a> [sa\_roles](#output\_sa\_roles) | Roles to bind to service accounts |

<!-- END_TF_DOCS -->
