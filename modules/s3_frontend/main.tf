resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-${var.environment}-frontend"
  force_destroy = true
}

data "aws_region" "current" {}

resource "aws_s3_bucket_public_access_block" "frontend_block" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid = "PublicReadGetObject",
      Effect = "Allow",
      Principal = "*",
      Action = "s3:GetObject",
      Resource = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_website_configuration" "frontend_site" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

locals {
  rendered_script = templatefile("${var.source_dir}/script.template.js", {
    api_url = var.api_url
  })
}

resource "aws_s3_object" "script_js" {
  bucket = aws_s3_bucket.frontend.id
  key = "script.js"
  content = local.rendered_script
  content_type = "application/javascript"
  etag = md5(local.rendered_script)
}

resource "aws_s3_object" "site_files" {
  for_each = {
    for file in fileset(var.source_dir, "**") : file => file
    if file != "script.js" && file != "script.template.js"
  }

  bucket = aws_s3_bucket.frontend.id
  key = each.key
  source = "${var.source_dir}/${each.key}"
  etag = filemd5("${var.source_dir}/${each.key}")
  content_type = lookup(var.mime_types, regex("[^.]+$", each.key), "text/plain")
}