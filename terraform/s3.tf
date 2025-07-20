resource "aws_s3_bucket" "codepipeline_artifact_bucket" {
  bucket = "codepipeline-project-artifacts-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "CodePipeline Artifact Bucket"
    Environment = var.environment
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.codepipeline_artifact_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
