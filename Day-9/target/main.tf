provider "aws" {
  
}

resource "aws_vpc" "dev1" {
  cidr_block = "10.0.0.0/16"
  
}

resource "aws_subnet" "dev1_subnet" {
  vpc_id     = aws_vpc.dev1.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "dev2" {
    ami = "ami-0d810b4169227c0ca"
    instance_type = "t3.micro"
}