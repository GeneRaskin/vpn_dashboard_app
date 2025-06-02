variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_name" {
  type = string
  description = "Name of the Lambda function to invoke"
}

variable "lambda_arn" {
  type = string
  description = "ARN of the Lambda function to invoke"
}

variable "allowed_origin" {
  type = string
  description = "Allowed origin for CORS"
}