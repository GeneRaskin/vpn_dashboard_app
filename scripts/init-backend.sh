#!/bin/bash
set -e

echo "== Initialize Terraform Backend (Per Region) =="

read -p "Enter AWS region [default: us-east-1]: " REGION
REGION=${REGION:-us-east-1}

read -p "Enter organization name: " ORGANIZATION_NAME

BUCKET="tf-state-${REGION}-${ORGANIZATION_NAME}"
LOCK_TABLE="tf-locks-${REGION}-${ORGANIZATION_NAME}"

echo "📦 Using S3 state backend bucket: $BUCKET"
echo "🔒 Using DynamoDB lock table: $LOCK_TABLE"

# Target backend file path
BACKEND_FILE="infra/backend-$REGION.auto.tfbackend"

# Check for existing backend config
if [[ -f "$BACKEND_FILE" ]]; then
  echo "🚨🔥 WARNING: Backend config already exists at $BACKEND_FILE"
  echo "🚫 If you continue, it will be OVERWRITTEN and any manual changes will be LOST."
  read -p "❓ Do you want to overwrite it? (yes/no): " CONFIRM
  CONFIRM=${CONFIRM,,}  # lowercase

  if [[ "$CONFIRM" != "yes" ]]; then
    echo "🛑 Aborted. Backend config not changed."
    exit 1
  fi
fi

# Create S3 bucket if not exists
echo "🪣 Ensuring S3 bucket exists..."

if [[ "$REGION" == "us-east-1" ]]; then
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" || true
else
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" || true
fi

# Create DynamoDB lock table if not exists
echo "🧱 Ensuring DynamoDB lock table exists..."
aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" || true

# Write backend config
cat > "$BACKEND_FILE" <<EOF
bucket = "$BUCKET"
region = "$REGION"
dynamodb_table = "$LOCK_TABLE"
encrypt = true
EOF

echo "✅ Backend initialized and saved to: $BACKEND_FILE"