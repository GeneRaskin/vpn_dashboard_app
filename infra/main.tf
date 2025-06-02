provider "aws" {
    region = var.region
}

module "dynamodb" {
    source = "../modules/dynamodb"
    environment = var.environment
    table_name = "vpn_users"
    project_name = var.project_name
}

module "lambda_get_user_config" {
    source = "../modules/lambda_get_user_config"
    environment = var.environment
    function_name = "get_user_config"
    project_name = var.project_name
    filename = "../backend/get_user_config/index.template.js"
    handler = "index.handler"
    runtime = "nodejs20.x"
    environment_variables = {
        TABLE_NAME = module.dynamodb.table_name
    }
    allowed_origin = module.frontend.website_url
    dynamodb_table_arn = module.dynamodb.dynamodb_table_arn
}

module "apigateway" {
    source = "../modules/apigateway"
    environment = var.environment
    project_name = var.project_name
    lambda_name = module.lambda_get_user_config.lambda_function_name
    lambda_arn  = module.lambda_get_user_config.lambda_function_arn
    allowed_origin = module.frontend.website_url
}

module "frontend" {
  source        = "../modules/s3_frontend"
  project_name  = var.project_name
  environment   = var.environment
  source_dir    = "../frontend"
  api_url       = module.apigateway.api_endpoint
}