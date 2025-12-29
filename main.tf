resource "aws_s3_bucket" "tf-test" {
  bucket = "tf-test-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}
