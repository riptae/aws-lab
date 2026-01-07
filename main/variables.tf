
#1 : region
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

#2 : project
variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "day-8"
}

#3 : env
variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

#4 :instance_type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

