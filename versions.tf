
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.1"
    }
  }
}

###------------------
### Usage
###------------------

#provider "google" {
#  project     = "my-project-id"
#  region      = "us-central1"
#  zone        = "us-central1-c"
#}

#provider "google-beta" {
#  project = "my-project-id"
#  region  = "us-central1"
#  zone    = "us-central1-c"
#}
