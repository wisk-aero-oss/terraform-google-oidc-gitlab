
variable "project_id" {
  type        = string
  description = "The project id to create Workload Identity Pool"
}

variable "private_server" {
  description = "Provider (GitLab) server is private?"
  type        = bool
  default     = true
}

variable "issuer_uri" {
  type        = string
  description = "Workload Identity Pool Issuer URL"
  default     = "https://gitlab.com"
}

variable "allowed_audiences" {
  type        = list(string)
  description = "Workload Identity Pool Provider allowed audiences."
  default     = ["https://gitlab.com"]
}

variable "attribute_mapping" {
  type        = map(any)
  description = "Workload Identity Pool Provider attribute mapping. [More info](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#attribute_mapping)"
  default = {                           # GitLab
    "google.subject" = "assertion.sub", # Required
    "attribute.aud"  = "assertion.aud",
    # ci_pipeline_id or pipeline_id
    # ci_job_id or job_id
    "attribute.namespace_id"   = "assertion.namespace_id", # Group number
    "attribute.namespace_path" = "assertion.namespace_path",
    "attribute.project_id"     = "assertion.project_id",   # Project number
    "attribute.project_path"   = "assertion.project_path", # group/project
    "attribute.ref"            = "assertion.ref",
    "attribute.ref_type"       = "assertion.ref_type", # branch,
    "attribute.user_email"     = "assertion.user_email",
    # Seems that to match multiple attributes, need to turn them into 1
    #   https://cloud.google.com/iam/docs/workload-identity-federation#mapping
    # "attribute.env" = "assertion.sub.contains(\":environment:\") ? assertion.environment : \"dev\""
    "attribute.project_reftype_ref" = "assertion.project_path + assertion.ref_type + assertion.ref"
  }
}
# https://gitlab.wisk.aero/help/integration/google_cloud_iam.md#oidc-custom-claims
#attribute.developer_access=assertion.developer_access,\
#attribute.guest_access=assertion.guest_access,\
#attribute.maintainer_access=assertion.maintainer_access,\
#attribute.namespace_id=assertion.namespace_id,\
#attribute.namespace_path=assertion.namespace_path,\
#attribute.owner_access=assertion.owner_access,\
#attribute.project_id=assertion.project_id,\
#attribute.project_path=assertion.project_path,\
#attribute.reporter_access=assertion.reporter_access,\
#attribute.user_access_level=assertion.user_access_level,\
#attribute.user_email=assertion.user_email,\
#attribute.user_id=assertion.user_id,\
#attribute.user_login=assertion.user_login,\
#google.subject=assertion.sub"
variable "organization_id" {
  description = "GCP Organization ID for access to custom organization roles"
  type        = string
  default     = ""
}

variable "service_accounts" {
  description = "Service account to manage and link to WIF"
  type = map(object({
    # WIF provider attributes. If attribute is set to `*` all identities in the pool are granted access to SAs.
    #attributes = list(string)
    attributes = list(object({
      attribute = string
      pool      = string
      provider  = string
    }))
    bindings = list(object({
      resource_id   = string
      resource_type = string
      roles         = list(string)
    }))
    can_impersonate = optional(list(string), [])
    description     = string
    display_name    = string
    #pool = string
    project = string
  }))
  validation {
    condition = alltrue(flatten([
      for sa in keys(var.service_accounts) : [
        for binding in var.service_accounts[sa].bindings :
        contains(["folder", "organization", "project"], binding.resource_type)
      ]
    ]))
    error_message = "Invalid resource_type. Must be one of: folder, organization, project."
  }
  # TODO: Validate can_impersonate are SA formated email addresses
}

variable "wif_identity_roles" {
  description = "Roles to grant to WIF identities"
  type = list(object({
    attribute = string
    pool      = string
    provider  = string
    roles     = list(string)
  }))
}
# Create pool per GitLab team ??
# TODO: add support for multiple pools
variable "wif_pools" {
  description = "Workload Identity Federation Pools"
  type = map(object({
    # key = pool ID
    description  = string
    display_name = string
    providers = map(object({
      # key provider ID
      description         = string
      display_name        = string
      attribute_condition = optional(string, "")
    }))
  }))
  default = {}
}
