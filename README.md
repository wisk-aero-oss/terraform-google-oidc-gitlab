
<!-- BEGIN_TF_DOCS -->
# terraform-google-module-template

[![Releases](https://img.shields.io/github/v/release/wisk-aero-oss/terraform-google-module-template)](https://github.com/wisk-aero-oss/terraform-google-module-template/releases)

[Terraform Module Registry](https://registry.terraform.io/modules/wisk-aero-oss/module-template/google)

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
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.7 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sample_output"></a> [sample\_output](#output\_sample\_output) | output value description |

<!-- END_TF_DOCS -->
