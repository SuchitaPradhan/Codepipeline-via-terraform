output "artifact_bucket_name" {
  value = aws_s3_bucket.codepipeline_artifact_bucket.bucket
}
