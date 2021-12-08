provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "s3" {
  bucket = "${var.bucket_name}"
  acl    = "${var.acl_value}"
  versioning {
    enabled = false
  }
  tags = {
    Environment = "Test"
  }
}
