
variable "project_id" {
  type        = string
  description = "The project id to create Workload Identity Pool"
}

variable "pool_id" {
  type        = string
  description = "Workload Identity Pool ID"
}

variable "pool_display_name" {
  type        = string
  description = "Workload Identity Pool display name"
  default     = null
}

variable "pool_description" {
  type        = string
  description = "Workload Identity Pool description"
  default     = "Workload Identity Pool managed by Terraform"
}

variable "provider_id" {
  type        = string
  description = "Workload Identity Pool Provider id"
}

variable "issuer_uri" {
  type        = string
  description = "Workload Identity Pool Issuer URL"
  default     = "https://gitlab.com"
}

variable "provider_display_name" {
  type        = string
  description = "Workload Identity Pool Provider display name"
  default     = null
}

variable "provider_description" {
  type        = string
  description = "Workload Identity Pool Provider description"
  default     = "Workload Identity Pool Provider managed by Terraform"
}

variable "attribute_condition" {
  type        = string
  description = "Workload Identity Pool Provider attribute condition expression. [More info](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#attribute_condition)"
  default     = null
}

variable "attribute_mapping" {
  type        = map(any)
  description = "Workload Identity Pool Provider attribute mapping. [More info](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#attribute_mapping)"
  default = {
    "google.subject" = "assertion.sub", # Required
    "attribute.aud"  = "assertion.aud",
    # ci_pipeline_id or pipeline_id
    # ci_job_id or job_id
    "attribute.project_path"   = "assertion.project_path", # group/project
    "attribute.project_id"     = "assertion.project_id",
    "attribute.namespace_id"   = "assertion.namespace_id", # Group
    "attribute.namespace_path" = "assertion.namespace_path",
    "attribute.user_email"     = "assertion.user_email",
    "attribute.ref"            = "assertion.ref",
    "attribute.ref_type"       = "assertion.ref_type", # branch,
  }
}

variable "allowed_audiences" {
  type        = list(string)
  description = "Workload Identity Pool Provider allowed audiences."
  default     = []
}
variable "service_accounts" {
  description = "Service account to manage and link to WIF"
  type = map(object({
    # WIF provider attributes. If attribute is set to `*` all identities in the pool are granted access to SAs.
    attributes = list(string)
    bindings = list(object({
      resource_id   = string
      resource_type = string
      roles         = list(string)
    }))
    description  = string
    display_name = string
    project      = string
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
}
