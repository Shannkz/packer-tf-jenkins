terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
}

provider "aws" {
  region                  = "eu-central-1"
  shared_credentials_files = ["~/.aws/credentials"]
  # profile                 = "dev"
}

provider "cloudinit" {
  # Configuration options
}

module "vpc" {
    source = "./vpc"
}

module "security_group" {
    source = "./security_groups"
    vpc_id = module.vpc.vpc_id
    depends_on = [
      module.vpc
    ]
}

module "terraform" {
    source = "./terraform"
    vpc_id = module.vpc.vpc_id
    # security_group = module.security_group.sg_id
    # public_subnet = module.vpc.public_subnet_id
    depends_on = [
      module.security_group
    ]
}

/* terraform destroy -var-file="secrets.tfvars" */