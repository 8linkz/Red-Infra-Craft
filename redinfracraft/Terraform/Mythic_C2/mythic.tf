terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
  }
}


# AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

variable "access_key" {
  description = "AWS Access Key ID"
}

variable "secret_key" {
  description = "AWS Secret Access Key"
}

data "http" "my_ip" {
  url = "https://api.ipify.org?format=text"
}

locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}


# Key Pair
resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa-4096.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.rsa-4096.private_key_pem
  filename = var.key_name
}


# EC2 Instance
resource "aws_instance" "Mythic_EC2" {
  ami           = "ami-080e1f13689e07408"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.key_pair.key_name
  security_groups = [var.security_group]
  availability_zone = "us-east-1e"

  root_block_device {
    volume_size = 20  
    delete_on_termination = true
  }

  user_data = <<EOF
#!/bin/bash

sudo mkdir -p /home/ubuntu/access
cd /home/ubuntu/access

sudo apt-get update
sudo apt-get install -y git

sudo git clone https://github.com/its-a-feature/Mythic

cd /home/ubuntu/access/Mythic

sudo ./install_docker_ubuntu.sh

sudo apt-get install -y make
sudo make

sudo /home/ubuntu/access/Mythic/mythic-cli install github https://github.com/MythicC2Profiles/http
sudo -E /home/ubuntu/access/Mythic/mythic-cli install github https://github.com/MythicAgents/Apollo.git

sudo /home/ubuntu/access/Mythic/mythic-cli start

EOF

  tags = {
    Name = "Mythic_EC2"
  }
}


# Security Group for EC2 Instance
resource "aws_security_group" "Mythic_EC2_sg" {
  name = var.security_group

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# VPC
data "aws_vpc" "default" {
  default = true
}