/*

Infrastructure for running nextflow jobs on AWS Batch

*/

terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 6.47.0"
        }
    }

    required_version = ">= 1.15.3"

    backend "s3" {}
}

provider "aws" {
    region  = var.region
}