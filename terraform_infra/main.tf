terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner   = "${var.owner}"
      Project = "${var.project}"
    }
  }
}

module "account_lookup" {
  source = "./modules/account_lookup_module"

}

module "keys" {
  source = "./modules/keys_module"

}

module "vpc" {
  source     = "./modules/vpc_module"
  cidr_block = var.cidr_block
  owner      = var.owner
}

module "hosts" {
  source           = "./modules/hosts_module"
  public_subnet_id = module.vpc.public_subnet_id
  vpc_id           = module.vpc.vpc_id
  account_id       = module.account_lookup.account_id
  project          = var.project
  region           = var.region

}
