resource "aws_iam_role" "lambda_exec" {
    name = "${var.project_name}-${var.environment}-${var.function_name}-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })

}

resource "aws_iam_role_policy" "lambda_dynamodb_access" {
    name = "${var.project_name}-${var.environment}-${var.function_name}-dynamodb-access"
    role = aws_iam_role.lambda_exec.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "dynamodb:GetItem"
                ]
                Resource = var.dynamodb_table_arn
            }
        ]
    })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
    name = "${var.project_name}-${var.environment}-${var.function_name}-policy"
    roles = [aws_iam_role.lambda_exec.name]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
    function_name = "${var.project_name}-${var.environment}-${var.function_name}"
    runtime = var.runtime
    handler = var.handler
    role = aws_iam_role.lambda_exec.arn

    filename = "${path.module}/../../backend/get_user_config/function.zip"

    environment {
        variables = var.environment_variables
    }

    tags = {
        Environment = var.environment
        Project = var.project_name
    }

}
