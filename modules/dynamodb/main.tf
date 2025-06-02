resource "aws_dynamodb_table" "vpn_users" {
    name = "${var.project_name}-${var.environment}-${var.table_name}"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "email"

    attribute {
        name = "email"
        type = "S"
    }
    
    tags = {
        Environment = var.environment
        Project = var.project_name
    }

}
