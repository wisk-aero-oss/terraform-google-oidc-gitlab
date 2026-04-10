
variables {
  project_id = "test-project"
  wif_pools = {
    "gitlab" = {
      display_name = "GitLab Pool"
      description  = "GitLab Pool Description"
      providers = {
        "gitlab" = {
          display_name = "GitLab Provider"
          description  = "GitLab Provider Description"
        }
      }
    }
  }
  wif_identity_roles = [
    {
      attribute = "attribute.project_path/devops/terraform"
      pool      = "gitlab"
      provider  = "gitlab"
      roles     = ["viewer"]
    }
  ]
  service_accounts = {
    "test-sa" = {
      display_name = "Test SA"
      description  = "Test SA Description"
      project      = "test-project"
      attributes   = []
      bindings = [
        {
          resource_id   = "test-project"
          resource_type = "project"
          roles         = ["roles/viewer"]
          # No location specified
        },
        {
          resource_id   = "test-project"
          resource_type = "project"
          location      = "us-central1"
          roles = [
            "roles/compute.viewer",
            "artifact-registry:roles/artifactregistry.reader:my-repo"
          ]
        }
      ]
    }
  }
}

run "verify_sa_permissions_logic" {
  command = plan

  variables {
    location = "global"
  }

  # Test that the binding without location inherits the global location
  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::roles/viewer::"].default_location == "global"
    error_message = "Binding without location should inherit global location"
  }

  # Test that the binding with location overrides the global location
  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::roles/compute.viewer::us-central1"].default_location == "us-central1"
    error_message = "Binding with location should override global location"
  }

  assert {
    condition     = contains(keys(local.sa_permissions_config), "test-sa::project::test-project::artifact-registry:roles/artifactregistry.reader:my-repo::us-central1")
    error_message = "sa_permissions_config should contain the artifact registry role with explicit location"
  }

  # Verify the role location as well
  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::roles/viewer::"].members[0].roles[0].location == "global"
    error_message = "Role location should inherit global location"
  }

  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::roles/compute.viewer::us-central1"].members[0].roles[0].location == "us-central1"
    error_message = "Role location should override global location"
  }

  # Verify artifact registry resource role construction
  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::artifact-registry:roles/artifactregistry.reader:my-repo::us-central1"].members[0].roles[0].resource == "artifact-registry:my-repo"
    error_message = "Artifact registry resource role should be correctly constructed"
  }

  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::artifact-registry:roles/artifactregistry.reader:my-repo::us-central1"].members[0].roles[0].role == "roles/artifactregistry.reader"
    error_message = "Artifact registry role name should be correctly extracted"
  }
}

run "verify_sa_permissions_no_global_location" {
  command = plan

  variables {
    location = null
  }

  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::roles/viewer::"].default_location == null
    error_message = "Default location should be null if not provided globally or in binding"
  }

  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::roles/viewer::"].members[0].roles[0].role == "roles/viewer"
    error_message = "Role should be viewer"
  }

  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::roles/viewer::"].members[0].roles[0].location == null
    error_message = "Role location should be null"
  }

  assert {
    condition     = local.sa_permissions_config["test-sa::project::test-project::roles/compute.viewer::us-central1"].members[0].roles[0].location == "us-central1"
    error_message = "Role location should be set"
  }
}

run "verify_wif_identity_project_membership" {
  command = plan

  # This resource doesn't use location yet, but it verifies our pool indexing is correct
  assert {
    condition     = google_project_iam_member.wif_identity["gitlab::attribute.project_path/devops/terraform::viewer"].role == "roles/viewer"
    error_message = "WIF identity role should be viewer"
  }
}
