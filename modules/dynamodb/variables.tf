variable "table_name" {
    type = string
    description = "Name of the DynamoDB table containing VPN configurations of users"
}

variable "environment" {
    type = string
    description = "Environment name (dev/prod)"
}

variable "project_name" {
    type = string
    description = "Project name"
}