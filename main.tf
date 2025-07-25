terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

locals {
  project = "module_workspace"

  region_map = {
    dev = var.dev_region
    stg = var.stg_region
    prd = var.prd_region
  }

  az_1_map = {
    dev = var.dev_az_1
    stg = var.stg_az_1
    prd = var.prd_az_1
  }

  az_2_map = {
    dev = var.dev_az_2
    stg = var.stg_az_2
    prd = var.prd_az_2
  }
}

provider "aws" {
  region = lookup(local.region_map, terraform.workspace, var.dev_region)
}

module "vpc" {
  source         = "./modules/vpc"
  vpc_cidr       = "172.168.0.0/16"
  vpc_tags       = { Name = "${local.project}-main_vpc-${terraform.workspace}" }
  sub_1-cidr     = "172.168.0.0/24"
  az-1           = lookup(local.az_1_map, terraform.workspace, var.dev_az_1)
  sub-1_tags     = { Name = "${local.project}-main_subnet-1-${terraform.workspace}" }
  sub_2-cidr     = "172.168.1.0/24"
  az-2           = lookup(local.az_2_map, terraform.workspace, var.dev_az_2)
  sub-2_tags     = { Name = "${local.project}-main_subnet-2-${terraform.workspace}" }
  IGW_tags       = { Name = "${local.project}-main_IGW-${terraform.workspace}" }
  route_ip       = "0.0.0.0/0"
  sg_id          = [module.security_group.sg_id]
  rt_tags        = { Name = "${local.project}-main_rt-${terraform.workspace}" }
  app-1_eip_tags = { Name = "${local.project}-app-1_eip-${terraform.workspace}" }
  app-2_eip_tags = { Name = "${local.project}-app-2_eip-${terraform.workspace}" }
}

module "security_group" {
  source      = "./modules/security_group"
  vpc_id      = module.vpc.vpc_id
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  tags        = { Name = "${local.project}-main_security_group-${terraform.workspace}" }
}

data "aws_ami" "ec2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

resource "tls_private_key" "generate_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main_key" {
  key_name   = "main_key"
  public_key = tls_private_key.generate_key.public_key_openssh

  tags = {
    Name = "${local.project}-main_key-${terraform.workspace}"
  }
}

module "app-1" {
  source         = "./modules/app-1"
  ami_id         = data.aws_ami.ec2_ami.id
  instance_type  = "t2.micro"
  key_name       = aws_key_pair.main_key.key_name
  app-1_nic_id   = module.vpc.app-1_nic_id
  app_1_userdata = <<-EOF
                     #!/bin/bash
                     yum update -y
                     amazon-linux-extras install nginx1 -y
                     systemctl enable nginx
                     systemctl start nginx
                     mkdir -p /usr/share/nginx/html/app-1
                     echo "This is app-1" > /usr/share/nginx/html/app-1/index.html
                EOF
  tags           = { Name = "${local.project}-app-1_ec2-${terraform.workspace}" }
}

module "app-2" {
  source         = "./modules/app-2"
  ami_id         = data.aws_ami.ec2_ami.id
  instance_type  = "t2.micro"
  key_name       = aws_key_pair.main_key.key_name
  app-2_nic_id   = module.vpc.app-2_nic_id
  app_2_userdata = <<-EOF
                     #!/bin/bash
                     yum update -y
                     amazon-linux-extras install nginx1 -y
                     systemctl enable nginx
                     systemctl start nginx
                     mkdir -p /usr/share/nginx/html/app-1
                     echo "This is app-2" > /usr/share/nginx/html/app-1/index.html
                   EOF
  tags           = { Name = "${local.project}-app-2_ec2-${terraform.workspace}" }
}

module "alb" {
  source        = "./modules/alb"
  internal      = true
  lb_type       = "application"
  sg_id         = module.security_group.sg_id
  sub_1_id      = module.vpc.sub_1_id
  sub_2_id      = module.vpc.sub_2_id
  lb_tags       = { Name = "${local.project}-main_alb-${terraform.workspace}" }
  vpc_id        = module.vpc.vpc_id
  app-1_tg_tags = { Name = "${local.project}-app-1_tg-${terraform.workspace}" }
  app-1_id      = module.app-1.app-1_id
  app-2_tg_tags = { Name = "${local.project}-app-1_tg-${terraform.workspace}" }
  app-2_id      = module.app-2.app-2_id
}
