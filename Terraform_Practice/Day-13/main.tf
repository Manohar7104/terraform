provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# VPC
# -----------------------------

resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
  }
}

# -----------------------------
# SUBNET 1
# Availability Zone: us-east-1a
# -----------------------------

resource "aws_subnet" "sub-1" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-1"
  }
}

# -----------------------------
# SUBNET 2
# Availability Zone: us-east-1c
# -----------------------------

resource "aws_subnet" "sub-2" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "subnet-2"
  }
}

# -----------------------------
# INTERNET GATEWAY
# -----------------------------

resource "aws_internet_gateway" "dev-igw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "dev-igw"
  }
}

# -----------------------------
# PUBLIC ROUTE TABLE
# -----------------------------

resource "aws_route_table" "dev-public-rt" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-igw.id
  }

  tags = {
    Name = "dev-public-rt"
  }
}

# -----------------------------
# ROUTE TABLE ASSOCIATION
# -----------------------------

resource "aws_route_table_association" "sub-1-association" {
  subnet_id      = aws_subnet.sub-1.id
  route_table_id = aws_route_table.dev-public-rt.id
}

resource "aws_route_table_association" "sub-2-association" {
  subnet_id      = aws_subnet.sub-2.id
  route_table_id = aws_route_table.dev-public-rt.id
}

# -----------------------------
# SECURITY GROUP
# -----------------------------

resource "aws_security_group" "dev-sg" {
  name   = "dev-sg"
  vpc_id = aws_vpc.dev.id

  ingress = [
    for port in [3306, 6379] : {
      description      = "inbound rules"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# RDS SUBNET GROUP
# -----------------------------

resource "aws_db_subnet_group" "db-subnet" {
  name = "db-subnet-group"

  subnet_ids = [
    aws_subnet.sub-1.id,
    aws_subnet.sub-2.id
  ]

  tags = {
    Name = "db-subnet-group"
  }
}

# -----------------------------
# REDIS SUBNET GROUP
# -----------------------------

resource "aws_elasticache_subnet_group" "redis-subnet" {
  name = "redis"

  subnet_ids = [
    aws_subnet.sub-1.id,
    aws_subnet.sub-2.id
  ]
}

# -----------------------------
# RDS MYSQL PRIMARY
# -----------------------------

resource "aws_db_instance" "mysql" {
  identifier        = "mysql-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "mydb"
  username = "admin"
  password = "123456789"

  db_subnet_group_name   = aws_db_subnet_group.db-subnet.name
  vpc_security_group_ids = [aws_security_group.dev-sg.id]

  skip_final_snapshot = true
  publicly_accessible = true

  multi_az = true

  # Minimum 1 day as required
  backup_retention_period = 1

  depends_on = [
    aws_db_subnet_group.db-subnet
  ]
}

# -----------------------------
# RDS READ REPLICA
# -----------------------------

resource "aws_db_instance" "replica" {
  identifier          = "mysql-replica"
  replicate_source_db = aws_db_instance.mysql.arn

  instance_class = "db.t3.micro"

  db_subnet_group_name   = aws_db_subnet_group.db-subnet.name
  vpc_security_group_ids = [aws_security_group.dev-sg.id]

  skip_final_snapshot = true
  publicly_accessible = true

  depends_on = [
    aws_db_instance.mysql
  ]
}

# -----------------------------
# REDIS
# -----------------------------

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "redis"
  description          = "redis replication"

  engine         = "redis"
  engine_version = "7.0"

  node_type = "cache.t3.micro"
  port      = 6379

  num_cache_clusters         = 2
  automatic_failover_enabled = true

  subnet_group_name  = aws_elasticache_subnet_group.redis-subnet.name
  security_group_ids = [aws_security_group.dev-sg.id]

  parameter_group_name = "default.redis7"

  depends_on = [
    aws_db_instance.mysql
  ]
}