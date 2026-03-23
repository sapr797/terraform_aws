variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_az" {
  description = "AWS availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "aws_key_name" {
  description = "Name of existing EC2 Key Pair"
  type        = string
}
