resource "aws_vpc" "name" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "vpc_tag"
  }
}

resource "aws_subnet" "dev" {
  cidr_block = var.subnet_cidr
  vpc_id     = aws_vpc.name.id

  tags = {
    Name = "subnet_tag"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0f84e72ee2b9c3a09"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.dev.id

  tags = {
    Name = "web-server"
  }
}

resource "aws_subnet" "rds" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.name.id

  availability_zone = "ap-south-2b"

  tags = {
    Name = "rds-subnet"
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for MySQL RDS"
  vpc_id      = aws_vpc.name.id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_db_subnet_group" "mysql" {
  name = "mysql-subnet-group"

  subnet_ids = [
    aws_subnet.dev.id,
    aws_subnet.rds.id
  ]

  tags = {
    Name = "mysql-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "terraform-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp3"
  publicly_accessible = false
  skip_final_snapshot = true

  db_name  = "terraformdb"
  username = "admin"
  password = "Terraform12345!"
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Name = "terraform-mysql"
  }
}