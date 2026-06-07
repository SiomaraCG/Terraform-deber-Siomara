terraform {

required_version = ">= 1.8.0"

required_providers {
aws = {
source  = "hashicorp/aws"
version = "~> 5.50"
}
}
}

provider "aws" {
region = var.aws_region
}

variable "aws_region" {
description = "Region AWS"
type        = string
default     = "us-east-1"
}

variable "environment" {
description = "Ambiente"
type        = string
default     = "academico"
}

variable "instance_type" {
description = "Instancia ARM64"
type        = string
default     = "t4g.micro"
}

resource "aws_vpc" "main" {

cidr_block = "10.0.0.0/16"

tags = {
Name = "vpc-arm64"
}
}

resource "aws_security_group" "server_sg" {

name        = "server-sg"
description = "Grupo de seguridad"
vpc_id      = aws_vpc.main.id

ingress {
from_port   = 22
to_port     = 22
protocol    = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
from_port   = 8000
to_port     = 8000
protocol    = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port   = 0
to_port     = 0
protocol    = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

data "aws_ami" "ubuntu_arm64" {

most_recent = true

owners = ["099720109477"]

filter {
name   = "name"
values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
}

filter {
name   = "architecture"
values = ["arm64"]
}
}

resource "aws_instance" "backend_server" {

ami           = data.aws_ami.ubuntu_arm64.id
instance_type = var.instance_type

vpc_security_group_ids = [
aws_security_group.server_sg.id
]

root_block_device {
volume_size = 30
volume_type = "gp3"
encrypted   = true
}

tags = {
Name         = "backend-arm64"
Architecture = "ARM64"
Processor    = "AWS Graviton"
Environment  = var.environment
}
}

output "instance_id" {
value = aws_instance.backend_server.id
}

output "public_ip" {
value = aws_instance.backend_server.public_ip
}

