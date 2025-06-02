output "table_name" {
    value = aws_dynamodb_table.vpn_users.name
}

output "dynamodb_table_arn" {
    value = aws_dynamodb_table.vpn_users.arn
}