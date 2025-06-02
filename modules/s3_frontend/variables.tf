variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "source_dir" {
  type = string
}

variable "mime_types" {
  type = map(string)
  default = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
  }
}

variable "api_url" {
  type = string
  description = "The base URL of the API Gateway"
}