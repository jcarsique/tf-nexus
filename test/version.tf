# Terraform v0.12.3
# + provider.aws v2.15.0
# + provider.http v1.1.1
# + provider.kubernetes v1.8.1

terraform {
  required_version = ">= 0.12.3"
  required_providers {
    aws        = "~> 2.15.0"
    http       = "~> 1.1"
    kubernetes = "~> 1.8"
  }
}
