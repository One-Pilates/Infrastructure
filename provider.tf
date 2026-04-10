# ============================================================
# Provider Configuration - OnePilates AWS Infrastructure
# ============================================================
# Para teste local com LocalStack: use_localstack = true (padrão)
# Para deploy real na AWS:        use_localstack = false
# ============================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "use_localstack" {
  description = "Se true, usa LocalStack para testes locais (não sobe nada na AWS)"
  type        = bool
  default     = true
}

provider "aws" {
  region = var.aws_region

  # Credenciais fictícias para LocalStack
  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  # Pular validações que não funcionam no LocalStack
  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack

  # Endpoints do LocalStack (localhost:4566)
  endpoints {
    ec2 = var.use_localstack ? "http://localhost:4566" : null
    s3  = var.use_localstack ? "http://s3.localhost.localstack.cloud:4566" : null
    iam = var.use_localstack ? "http://localhost:4566" : null
    sts = var.use_localstack ? "http://localhost:4566" : null
  }
}
