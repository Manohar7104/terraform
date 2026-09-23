terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.66.0"
    }

    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "aws" {
  region = "ap-south-2"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-provisioner-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  filename        = "${path.module}/terraform-provisioner-key.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}

resource "aws_vpc" "provisioner_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "provisioner-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.provisioner_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "provisioner-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.provisioner_vpc.id

  tags = {
    Name = "provisioner-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.provisioner_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "provisioner-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ssh" {
  name   = "provisioner-ssh"
  vpc_id = aws_vpc.provisioner_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "provisioner-ssh"
  }
}

resource "aws_instance" "server" {
  ami                         = "ami-0f84e72ee2b9c3a09"
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  associate_public_ip_address = true

  tags = {
    Name = "provisioner-server"
  }

  connection {
  type        = "ssh"
  user        = "ec2-user"
  private_key = tls_private_key.ssh_key.private_key_pem
  host        = self.public_ip
  timeout     = "5m"
}

provisioner "file" {
  source      = "${path.module}/message.txt"
  destination = "/tmp/message.txt"
}

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from Terraform remote-exec' | sudo tee /tmp/provisioner-test.txt",
      "hostname",
      "whoami"
    ]
  }
}

resource "null_resource" "copy_message" {

  depends_on = [
    aws_instance.server
  ]

  triggers = {
    message_file = filemd5("${path.module}/message.txt")
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = aws_instance.server.public_ip
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/message.txt"
    destination = "/tmp/message.txt"
  }
}