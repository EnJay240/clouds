provider "aws" {
    access_key = "***"
    secret_key = "***"
    region = "us-east-2"
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "Lab7_VPC"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"


  tags = {
    "Name" = "Lab7_Subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2b"
  


  tags = {
    "Name" = "Lab7_Subnet2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Lab7_Gateway"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Lab7_Route_Table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.r.id
}

resource "aws_network_acl" "acl" {
  vpc_id   = "vpc-806fc7eb"

  ingress {
    protocol   = -1
    rule_no    = 200
    action     = "deny"
    cidr_block = "50.31.252.0/24"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_security_group" "db_sg" {
  name   = "Lab7_RDS_SG"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab7_RDS_SG"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "subnet_group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "Lab7_DB_Subnet_group"
  }
}

resource "aws_db_instance" "rds_db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "dbtest"
  username               = "testuser"
  password               = "4e7stwghnpso"
  publicly_accessible    = true
  skip_final_snapshot = true
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
}