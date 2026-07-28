terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-south-2"
}

########################################
# VPC
########################################

resource "aws_vpc" "dr_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Fly91-DR-VPC"
  }
}

########################################
# Internet Gateway
########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dr_vpc.id

  tags = {
    Name = "Fly91-DR-IGW"
  }
}

########################################
# Public Subnet
########################################

resource "aws_subnet" "public" {

  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}

########################################
# Private Subnet 1
########################################

resource "aws_subnet" "private1" {

  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.100.2.0/24"
  availability_zone = "ap-south-2a"

  tags = {
    Name = "Private-Subnet-1"
  }
}

########################################
# Private Subnet 2
########################################

resource "aws_subnet" "private2" {

  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.100.3.0/24"
  availability_zone = "ap-south-2b"

  tags = {
    Name = "Private-Subnet-2"
  }
}

########################################
# Public Route Table
########################################

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

########################################
# Security Group
########################################

resource "aws_security_group" "postgres_sg" {

  name   = "postgres-sg"
  vpc_id = aws_vpc.dr_vpc.id

  ingress {
    description = "PostgreSQL"

    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    cidr_blocks = [
      "10.20.0.0/16"
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "Postgres-SG"
  }
}

########################################
# DB Subnet Group
########################################

resource "aws_db_subnet_group" "db_subnet" {

  name = "fly91-dr-db-subnet"

  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]

  tags = {
    Name = "Fly91-DB-Subnet"
  }
}

########################################
# PostgreSQL RDS
########################################

resource "aws_db_instance" "postgres" {

  identifier = "fly91-dr-postgresql"

  engine         = "postgres"
  engine_version = "16.4"

  instance_class = "db.t3.medium"

  allocated_storage = 20
  storage_type       = "gp3"

  db_name  = "fly91dr"
  username = "postgres"
  password = "Password@12345"

  db_subnet_group_name = aws_db_subnet_group.db_subnet.name

  vpc_security_group_ids = [
    aws_security_group.postgres_sg.id
  ]

  publicly_accessible = false

  skip_final_snapshot = true

  tags = {
    Name = "Fly91-DR-PostgreSQL"
  }
}

########################################
# Outputs
########################################

output "vpc_id" {
  value = aws_vpc.dr_vpc.id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}
