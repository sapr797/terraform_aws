# Политика доверия для EC2 (что EC2 может использовать эту роль)
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Создание IAM роли
resource "aws_iam_role" "ec2_s3_role" {
  name               = "ec2-s3-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Политика, позволяющая записывать объекты в S3 бакет
resource "aws_iam_role_policy" "s3_write_policy" {
  name = "s3-write-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.web_bucket.arn,
          "${aws_s3_bucket.web_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Instance profile (чтобы привязать роль к EC2)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-profile"
  role = aws_iam_role.ec2_s3_role.name
}
