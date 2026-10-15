resource "aws_s3_bucket" "demo" {
  bucket = "srush-terraform-demo-2026-unique"

  tags = {
    Name        = "Terraform Demo"
    Environment = "Learning"
  }
}
