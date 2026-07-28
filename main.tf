terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC

resource "aws_vpc" "dr_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Fly91-DR-VPC"
  }
}


# Internet Gateway


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dr_vpc.id

  tags = {
    Name = "Fly91-DR-IGW"
  }
}


# Public Subnet


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}


# Private Subnet 1


resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.100.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Private-Subnet-1"
  }
}


# Private Subnet 2


resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.100.3.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Private-Subnet-2"
  }
}


# Public Route Table


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.dr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}


# Security Group


resource "aws_security_group" "terraform_sg" {
  name        = "terraform-demo-sg"
  description = "Terraform Demo Security Group"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description = "SSH"

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "Terraform-SG"
  }
}
