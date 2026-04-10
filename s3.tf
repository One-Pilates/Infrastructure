# ============================================================
# S3 Bucket - image-bucket (Amazon S3) - OnePilates
# ============================================================

resource "aws_s3_bucket" "image_bucket" {
  bucket = "${var.projeto}-image-bucket"

  tags = {
    Name    = "${var.projeto}-image-bucket"
    Projeto = var.projeto
  }
}

# Bloquear acesso público por padrão
resource "aws_s3_bucket_public_access_block" "image_bucket_public_access" {
  bucket = aws_s3_bucket.image_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versionamento habilitado para proteção de dados
resource "aws_s3_bucket_versioning" "image_bucket_versioning" {
  bucket = aws_s3_bucket.image_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia server-side
resource "aws_s3_bucket_server_side_encryption_configuration" "image_bucket_encryption" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------
# IAM Role para EC2 acessar o S3
# -----------------------------------------------
resource "aws_iam_role" "ec2_s3_role" {
  name = "${var.projeto}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.projeto}-ec2-s3-role"
    Projeto = var.projeto
  }
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "${var.projeto}-ec2-s3-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.image_bucket.arn,
          "${aws_s3_bucket.image_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "${var.projeto}-ec2-s3-profile"
  role = aws_iam_role.ec2_s3_role.name
}
