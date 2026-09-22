provider "aws" {
  region = "ap-south-2"
}

resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
  depends_on = [ aws_s3_bucket.my_bucket ]
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "veera7104"
  force_destroy = true
}
