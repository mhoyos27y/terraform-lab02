resource "aws_s3_bucket" "s3mauro" {
  count  = 6
  bucket = "totallyti-cloud-${random_string.sufijo[count.index].id}"
  tags = {
    Owner       = "totallyti"
    Environment = "Dev"
    Office      = "Cloud"
  }
}

resource "random_string" "sufijo" {
  count   = 6
  length  = 8
  special = false
  upper   = false
  numeric = false
}
