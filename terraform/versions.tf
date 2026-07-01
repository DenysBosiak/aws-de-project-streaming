terraform {
    required_version = ">= 1.5"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 6.0"
        }
    }
    backend "s3" {
        key = "p1-streaming/terraform.tfstate"
        region = "eu-north-1"
        use_lockfile = true
        encrypt = true
    }
}

provider "aws" {
    region = "eu-north-1"
    default_tags {
        tags = {
            Environment = "dev"
            Project = "p1-streaming"
            ManagedBy = "terraform"
        }
    }
}