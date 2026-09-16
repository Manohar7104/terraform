terraform {
  backend "s3" {
    bucket = "veera-manohar"
    key    = "terraform-statefile/terraform.tfstate"
    region = "ap-south-2"
  }
}