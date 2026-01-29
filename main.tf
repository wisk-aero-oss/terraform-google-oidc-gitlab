/**
 * # terraform-google-oidc-gitlab
 *
 * [![Releases](https://img.shields.io/github/v/release/wisk-aero-oss/terraform-google-oidc-gitlab)](https://github.com/wisk-aero-oss/terraform-google-oidc-gitlab/releases)
 *
 * [Terraform Module Registry](https://registry.terraform.io/modules/wisk-aero-oss/oidc-gitlab/google)
 *
 * Template for creating a Terraform module for Google
 *
 * ## Features
 *
 * - base terraform files
 * - pre-commit setup
 * - GitHub actions setup
 *
 */

# WIF in 1 project
# Multiple services accounts in projects/folders with multiple roles
#   Create, grant roles, grant attributes
#   service account
#       project
#       bindings
#         resource_id
#         resource_type ["folder", "organization", "project"]
#         roles = []
#       attributes
#
# Support restricting by: GitLab group, project, person, ?

#GCP OIDC
#https://gitlab.com/guided-explorations/gcp/configure-openid-connect-in-gcp/-/blob/main/main.tf
#https://github.com/notablehealth/terraform-gcp-terrateam-setup/blob/main/main.tf
#https://gitlab.wisk.aero/devops/groups-api/-/blob/main/infra-init/main.tf
#Look at combining to support GitLab (SaaS & on-site) & GitHub as a generic module
#GitLab pipelines, Secret Manager access,
#- write access data or url to GitLab variable for GCP_ID_TOKEN
#- https://docs.gitlab.com/ci/secrets/gcp_secret_manager/
#Create: terraform-google-oidc-gitlab
#1 pool and provider
#Loop (any amount): service account, service_account_iam_member (WIF principal, permissions)
#Permissions by GitLab: group, project, user email,
#sub: project_path:{group}/{project}:ref_type:{type}:ref:{branch_name}
#
#https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs
#gitlab_group_variable
#gitlab_project_variable
#- Project/Settings/CICD/Variables
#- I don't have access to see group ones?? Need to be group owner
#
#gitlab_integration_slack
#gitlab_service_slack
## make GitLab slack app
#data "gitlab_group"
#data "gitlab_project"
#
#https://github.com/saidsef/terraform-gcp-terraform-cloud-oidc
#https://github.com/saidsef/terraform-gcp-github-oidc
#https://github.com/solidblocks/terraform-google-circleci-oidc
#https://registry.terraform.io/modules/c0x12c/github-oidc/gcp
#https://github.com/terraform-google-modules/terraform-google-github-actions-runners/tree/main/modules/gh-oidc
#https://github.com/terraform-google-modules/terraform-google-github-actions-runners/tree/main/examples/oidc-simple


#locals {
#  tmpl_pool_name     = "projects/${var.project_id}/locations/global/workloadIdentityPools/$${pool}"
#  tmpl_provider_name = "projects/${var.project_id}/locations/global/workloadIdentityPools/$${pool}/providers/$${provider}"
#}
#output "result" {
#  value = templatestring(local.tmpl_, { pool = "POOL", provider = "PROVIDER" })
#}

resource "google_iam_workload_identity_pool" "main" {
  for_each                  = var.wif_pools
  project                   = var.project_id
  workload_identity_pool_id = each.key
  display_name              = each.value.display_name
  description               = each.value.description
  disabled                  = false
}
# FIX: whitespace always changes
data "http" "jwk" {
  count = var.private_server ? 1 : 0
  url   = "${var.issuer_uri}/oauth/discovery/keys"
}

#trivy:ignore:AVD-GCP-0068
resource "google_iam_workload_identity_pool_provider" "main" {
  for_each = merge(flatten([ # convert to colasped map
    for poolkey, pool in var.wif_pools :
    { for providerkey, provider in pool.providers :
      "${poolkey}::${providerkey}" => provider
    }
  ])...)

  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.main[split("::", each.key)[0]].workload_identity_pool_id
  workload_identity_pool_provider_id = split("::", each.key)[1]
  display_name                       = each.value.display_name
  description                        = each.value.description
  attribute_condition                = each.value.attribute_condition
  # attribute_condition = "assertion.namespace_path.startsWith(\"${var.gitlab_namespace_path}\")"
  attribute_mapping = var.attribute_mapping
  oidc {
    allowed_audiences = var.private_server ? [] : var.allowed_audiences
    issuer_uri        = var.issuer_uri
    jwks_json         = var.private_server ? data.http.jwk[0].response_body : ""
  }
}

###---------------------------------------
### WIF Identity permissions
###---------------------------------------
# Grant permissions to WIF identity
#   GitLab GCP Secret Manager integration uses it this way
locals {
  ## attibute::role -> pool::attibute::role
  wif_identity_roles = flatten([
    for identity in var.wif_identity_roles : [
      for role in identity.roles :
      "${identity.pool}::${identity.attribute}::${role}"
    ]
  ])
  # FIX: Can't do this for multiple pools - could do template
  #wif_principle_path = "://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/"
}
# ADD: support for conditions or convert to use iam-members
resource "google_project_iam_member" "wif_identity" {
  for_each = toset(local.wif_identity_roles)
  project  = var.project_id
  # TODO: need to dynamically build?
  member = (length(regexall("^subject", split("::", each.value)[1])) > 0 ?
    "principal://iam.googleapis.com/${google_iam_workload_identity_pool.main[split("::", each.value)[0]].name}/${split("::", each.value)[1]}" :
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main[split("::", each.value)[0]].name}/${split("::", each.value)[1]}"
  )
  #member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/${split("::", each.value)[0]}"
  # principalSet://iam.googleapis.com/projects/890158812569/locations/global/workloadIdentityPools/gitlab/attribute.project_path/devops/terraform
  role = "roles/${split("::", each.value)[2]}"
}

###---------------------------------------
### Service Accounts for impersonation
###---------------------------------------
# Manage service accounts, WIF identity to service account mappings, and permissions
#   GitLab pipelines impersonate the service account
resource "google_service_account" "sa" {
  for_each     = var.service_accounts
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  project      = each.value.project
}
locals {
  # service_account::service account allowed to impersonate
  sa_impersonations = flatten([
    for s, sa in var.service_accounts : [
      for sa_imp in sa.can_impersonate :
      "${s}::${sa_imp}"
    ]
  ])
  # service_account::attribute -> service_account::pool::attribute
  sa_mappings = flatten([
    for s, sa in var.service_accounts : [
      for attribute in sa.attributes :
      "${s}::${attribute.pool}::${attribute.attribute}"
    ]
  ])
  # service_account::resource_type::resource_id::role
  sa_roles = flatten([
    for s, sa in var.service_accounts :
    [
      for b, binding in sa.bindings : [
        for role in binding.roles :
        "${s}::${binding.resource_type}::${binding.resource_id}::${role}"
      ]
    ]
  ])
}
# Attributes - Grant WIF identity access to impersonate service account
resource "google_service_account_iam_member" "wif-sa" {
  for_each           = toset(local.sa_mappings)
  service_account_id = google_service_account.sa[split("::", each.value)[0]].id
  role               = "roles/iam.workloadIdentityUser"
  member = (length(regexall("^subject", split("::", each.value)[2])) > 0 ?
    #"principal${local.wif_principle_path}${split("::", each.value)[2]}" :
    #"principalSet${local.wif_principle_path}${split("::", each.value)[2]}"
    "principal://iam.googleapis.com/${google_iam_workload_identity_pool.main[split("::", each.value)[1]].name}/${split("::", each.value)[2]}" :
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main[split("::", each.value)[1]].name}/${split("::", each.value)[2]}"
  )

  #member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/${split("::", each.value)[1]}"
  # Grant to GitLab project
  #"principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab-pool.name}/attribute.project_id/${var.gitlab_project_id}"
}
# Grant service account to impersonate other service accounts
resource "google_service_account_iam_member" "sa-sa" {
  for_each           = toset(local.sa_impersonations)
  service_account_id = google_service_account.sa[split("::", each.value)[1]].id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = google_service_account.sa[split("::", each.value)[0]].member
  #  "principal://iam.googleapis.com/${google_iam_workload_identity_pool.main[split("::", each.value)[1]].name}/${split("::", each.value)[2]}"
  # google_service_account.sa[split("::", each.value)[0]].id
}

# Grant service account permissions
module "sa_permissions" {
  #source = "../terraform-google-iam-members"
  source  = "wisk-aero-oss/iam-members/google"
  version = "0.2.1"

  for_each = toset([for binding in local.sa_roles : binding])

  folder_id       = "folder" == split("::", each.value)[1] ? split("::", each.value)[2] : ""
  project_id      = "project" == split("::", each.value)[1] ? split("::", each.value)[2] : ""
  organization_id = "organization" == split("::", each.value)[1] ? split("::", each.value)[2] : ""

  #project_id = module.projects[split("::", each.value)[0]].project_id
  members = [
    {
      member = google_service_account.sa[split("::", each.value)[0]].member
      roles  = [{ role = split("::", each.value)[3] }]
    }
  ]
}

#resource "google_folder_iam_member" "sa" {
#  for_each = toset([for binding in local.sa_roles : binding if "folder" == split("::", binding)[1]])
#  folder   = split("::", each.value)[2]
#  member   = google_service_account.sa[split("::", each.value)[0]].member
#  role     = "roles/${split("::", each.value)[3]}"
#}
#resource "google_organization_iam_member" "sa" {
#  for_each = toset([for binding in local.sa_roles : binding if "organization" == split("::", binding)[1]])
#  org_id   = split("::", each.value)[2]
#  member   = google_service_account.sa[split("::", each.value)[0]].member
#  role     = "roles/${split("::", each.value)[3]}"
#}
#resource "google_project_iam_member" "sa" {
#  for_each = toset([for binding in local.sa_roles : binding if "project" == split("::", binding)[1]])
#  project  = split("::", each.value)[2]
#  member   = google_service_account.sa[split("::", each.value)[0]].member
#  role     = "roles/${split("::", each.value)[3]}"
#}

#resource "google_service_account_iam_member" "sa_" {
#locals {
#  project_roles = merge(flatten([
#    for p, project in var.projects :
#    [
#      for r, role in project.bindings : { "${p}::${role.role}" = role.members }
#    ]
#  ])...)
#  project_members = flatten([for r, role in local.project_roles : [
#    for member in role : "${r}::${member}"
#  ]])
#}
#resource "google_project_iam_member" "projects" {
#  for_each = toset(local.project_members)
#  project  = module.projects[split("::", each.value)[0]].project_id
#  member   = split("::", each.value)[2]
#  role     = "roles/${split("::", each.value)[1]}"
#}
