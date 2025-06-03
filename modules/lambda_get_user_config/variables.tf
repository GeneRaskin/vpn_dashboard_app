variable "environment" {
    type = string
    description = "Environment name (dev/prod)"
}

variable "project_name" {
    type = string
    description = "Project name"
}

variable "function_name" {
    type = string
    description = "Lambda function name"
}

variable "runtime" {
    type = string
    default = "nodejs20.x"
}

variable "handler" {
    type = string
    default = "index.handler"
}

variable "filename" {
    type = string
    description = "Path to the Lambda .zip file"
}

variable "environment_variables" {
    type = map(string)
    default = {}
}

variable "allowed_origin" {
  type = string
  description = "Allowed origin for CORS headers"
}

variable "dynamodb_table_arn" {
    type = string
}