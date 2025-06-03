output "website_url" {
  value = "https://${aws_s3_bucket.frontend.bucket}.s3.${data.aws_region.current.name}.amazonaws.com"
}