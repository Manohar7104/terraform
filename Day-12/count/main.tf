variable "aws_region" {
  type        = string
  nullable    = false
  default     = "ap-south-2" 
  validation {
    condition = var.aws_region == "ap-south-1" || var.aws_region == "ap-south-2"
    error_message = "The variable 'aws_region' must be one of the following regions: ap-south-1, ap-south-2"
  }
}



provider "aws" {
  region = var.aws_region 
 }

 resource "aws_s3_bucket" "dev" {
    bucket = "veera7104"  
 }

variable "environment" {
  type    = string
  default = "prod"
}

resource "aws_instance" "example" {
  count         = var.environment == "dev" ? 3 : 1
  ami           = "ami-0ef742f2f600ff2fb"
  instance_type = "t3.micro"
}
