#!/bin/bash
set -e

BACKEND_FILE="infra/backend-config.auto.tfbackend"

if [[ ! -f "$BACKEND_FILE" ]]; then
  echo "❌ Required backend config file $BACKEND_FILE not found."
  echo "👉 Please run init-project.sh first."
  exit 1
fi

# Extract ENV, REGION, PROJECT_NAME from backend config file
PROJECT_NAME=$(grep -E '^key *= *"' "$BACKEND_FILE" | cut -d'"' -f2 | cut -d'/' -f1)
ENV=$(grep -E '^key *= *"' "$BACKEND_FILE" | cut -d'"' -f2 | cut -d'/' -f2)
REGION=$(grep -E '^region *= *"' "$BACKEND_FILE" | cut -d'"' -f2)

# Validate extracted values
if [[ -z "$PROJECT_NAME" || -z "$ENV" || -z "$REGION" ]]; then
  echo "❌ Failed to extract PROJECT_NAME, ENV, or REGION from $BACKEND_FILE"
  exit 1
fi

cd infra
VARS_FILE="${ENV}_${REGION}_${PROJECT_NAME}.tfvars"

if [[ ! -f "$VARS_FILE" ]]; then
  echo "❌ Variables file $VARS_FILE not found"
  exit 1
fi

echo "🧠 Using tfvars: $VARS_FILE"
echo "🌍 REGION=$REGION | ENV=$ENV | PROJECT=$PROJECT_NAME"

echo "🚀 Phase 1: Deploy S3 Frontend..."
rm -rf .terraform
terraform init -backend-config=backend-config.auto.tfbackend -reconfigure
terraform apply -target=module.frontend -auto-approve -var-file="$VARS_FILE"

echo "🧠 Templating + Zipping Lambda..."
# Capture terraform output cleanly and extract just the URL
origin=$(terraform output -raw website_url | grep -Eo 'https://[^:]+' | head -n1 | tr -d '\r\n')
if [ $? -ne 0 ] || [ -z "$origin" ]; then
  echo "❌ Failed to get website_url from terraform output"
  exit 1
fi

echo "$origin" > ../backend/get_user_config/origin.txt
cd ../backend/get_user_config

echo "🌐 Using allowed origin: $origin"

export allowed_origin="$origin"
envsubst < index.template.js > index.js

npm install
zip function.zip index.js node_modules package.json

echo "🚀 Phase 2: Deploy Lambda + rest..."
cd ../../infra
terraform apply -auto-approve -var-file="$VARS_FILE"