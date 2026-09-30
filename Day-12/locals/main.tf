locals {
  region = "ap-south-2"
  instance_type = "t3.micro"
  ami_id = "ami-0ef742f2f600ff2fb"
}

resource "aws_instance" "manohar-ec2" {
    ami = local.ami_id
    instance_type = local.instance_type
}