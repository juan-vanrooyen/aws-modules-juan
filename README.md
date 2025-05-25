# AWS Terraform Modules (Juan)

This repository contains reusable Terraform modules for AWS infrastructure. These modules are designed to be used as building blocks in your own Terraform or Terragrunt projects.

## Structure

- `s3/` - S3 bucket module
- `vpc/` - VPC module
- Additional modules can be added as needed

## Usage

Reference these modules in your Terraform or Terragrunt configurations. Example usage:

```
module "s3_bucket" {
  source = "git::https://github.com/<your-org>/aws-modules-juan.git//s3"
  # ...module variables...
}
```

## Requirements

- [Terraform](https://www.terraform.io/) >= 1.0
- [Terragrunt](https://terragrunt.gruntwork.io/) (optional)

## Pre-commit Hooks

This repo uses [pre-commit](https://pre-commit.com/) for code quality checks. To set up:

```
pre-commit install
```

## Contributing

Feel free to open issues or submit pull requests for improvements or new modules.

---

*Maintained by Juan van Rooyen.*
