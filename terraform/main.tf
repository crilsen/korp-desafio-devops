terraform {
  required_version = ">= 1.5"

  # estado remoto no S3 (nada de .tfstate no repo)
  backend "s3" {
    bucket  = "cn-korp-tfstate-us-east-1"
    key     = "korp-desafio-devops/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
