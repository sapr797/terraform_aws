resource "aws_s3_bucket" "web_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  tags = {
    Name = "WebBucket"
  }
}

# Включение SSE-S3 шифрования для всех объектов в бакете
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.web_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Блокировка публичного доступа (для безопасности)
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.web_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
