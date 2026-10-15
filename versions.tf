terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "tf-state-srush-1792092456"
    key          = "aws-terraform-infra/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
