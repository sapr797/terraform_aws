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

variable "bucket_name" {
  description = "Name of S3 bucket (must be globally unique)"
  type        = string
  default     = "my-unique-bucket-20250325"
}
