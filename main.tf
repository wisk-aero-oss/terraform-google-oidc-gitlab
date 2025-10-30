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

# Create pool per GitLab team ??
resource "google_iam_workload_identity_pool" "main" {
  #provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.pool_display_name
  description               = var.pool_description
  disabled                  = false
}

data "http" "jwk" {
  count = var.private_server ? 1 : 0
  url   = "${var.issuer_uri}/oauth/discovery/keys"
}
resource "google_iam_workload_identity_pool_provider" "main" {
  #provider                           = google-beta
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = var.provider_display_name
  description                        = var.provider_description
  attribute_condition                = var.attribute_condition
  # attribute_condition = "assertion.namespace_path.startsWith(\"${var.gitlab_namespace_path}\")"
  attribute_mapping = var.attribute_mapping
  oidc {
    allowed_audiences = var.private_server ? [] : var.allowed_audiences
    issuer_uri        = var.issuer_uri
    jwks_json         = var.private_server ? data.http.jwk[0].response_body : ""
  }
}

locals {
  sa_mappings = flatten([
    for s, sa in var.service_accounts : [
      for attribute in sa.attributes :
      "${s}::${attribute}"
    ]
  ])
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
resource "google_service_account" "sa" {
  for_each     = var.service_accounts
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  project      = each.value.project
}
# Attributes
resource "google_service_account_iam_member" "wif-sa" {
  for_each           = toset(local.sa_mappings)
  service_account_id = google_service_account.sa[split("::", each.value)[0]].id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/${split("::", each.value)[1]}"
  # Grant to GitLab project
  #"principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab-pool.name}/attribute.project_id/${var.gitlab_project_id}"
}
# Permission bindings
resource "google_folder_iam_member" "sa" {
  for_each = toset([for binding in local.sa_roles : binding if "folder" == split("::", binding)[1]])
  folder   = split("::", each.value)[2]
  member   = google_service_account.sa[split("::", each.value)[0]].member
  role     = "roles/${split("::", each.value)[3]}"
}
resource "google_organization_iam_member" "sa" {
  for_each = toset([for binding in local.sa_roles : binding if "organization" == split("::", binding)[1]])
  org_id   = split("::", each.value)[2]
  member   = google_service_account.sa[split("::", each.value)[0]].member
  role     = "roles/${split("::", each.value)[3]}"
}
resource "google_project_iam_member" "sa" {
  for_each = toset([for binding in local.sa_roles : binding if "project" == split("::", binding)[1]])
  project  = split("::", each.value)[2]
  member   = google_service_account.sa[split("::", each.value)[0]].member
  role     = "roles/${split("::", each.value)[3]}"
}

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
