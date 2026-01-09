terraform {
  backend "s3" {
    bucket         = "my-tf-state-bucket-97c4f7e9"
    key            = "envs/prod/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "my-tf-lock"
    encrypt        = true
  }
}