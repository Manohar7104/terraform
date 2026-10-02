provider "aws" {
  region = "ap-south-2"
}

resource "aws_s3_bucket" "jenkins_test" {
  bucket = "veera-jenkins-script-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}