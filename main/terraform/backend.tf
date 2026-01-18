terraform {
  backend "s3" {
    bucket         = "my-tf-state-bucket-134e2df8"
    key            = "envs/prod/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "my_tf_lock"
    encrypt        = true
  }
}