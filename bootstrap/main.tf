# backend없이 local로 한번 apply

# [0] provider

terraform {
  required_version = ">= 1.5.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# [1] s3 bucket
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "tf-state" {
  bucket        = "my-tf-state-bucket-${random_id.suffix.hex}"
  force_destroy = false
  tags          = { Name = "tf-state" }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enc" {
  bucket = aws_s3_bucket.tf-state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.tf-state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# [2] DynamoDB
resource "aws_dynamodb_table" "tf-lock" {
  name         = "my-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = { Name = "tf-lock" }
}
