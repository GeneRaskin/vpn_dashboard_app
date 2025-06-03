#!/bin/bash
set -e

echo "== Project Initialization =="

read -p "Enter AWS region (must match existing backend): " REGION
read -p "Enter environment name (dev or prod): " ENV
if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "❌ ENV must be dev or prod"
  exit 1
fi

read -p "Enter project name: " PROJECT_NAME

BACKEND_FILE="infra/backend-$REGION.auto.tfbackend"
if [[ ! -f "$BACKEND_FILE" ]]; then
  echo "❌ Backend config for region not found: $BACKEND_FILE"
  echo "👉 Run scripts/init-backend.sh first"
  exit 1
fi

# Generate state key for this project
STATE_KEY="$PROJECT_NAME/$ENV/main.tfstate"

# Patch backend file with key
BACKEND_WITH_KEY="infra/backend-config.auto.tfbackend"
cp "$BACKEND_FILE" "$BACKEND_WITH_KEY"
echo "key = \"$STATE_KEY\"" >> "$BACKEND_WITH_KEY"

# Create tfvars file
VARS_FILE="infra/${ENV}_${REGION}_${PROJECT_NAME}.tfvars"
cat > "$VARS_FILE" <<EOF
environment = "$ENV"
region = "$REGION"
project_name = "$PROJECT_NAME"
EOF

echo "✅ Project initialized: $VARS_FILE"
echo "👉 Backend config: $BACKEND_WITH_KEY"