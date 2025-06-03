#!/bin/bash
set -e

echo "== VPN App Cleanup =="

read -p "Enter AWS region [default: us-east-1]: " REGION
REGION=${REGION:-us-east-1}

# Derive backend names from region
BACKEND_CONFIG_FILE="infra/backend-$REGION.auto.tfbackend"

# Extract values from backend config
BUCKET=$(grep -E '^bucket *= *"' "$BACKEND_CONFIG_FILE" | cut -d'"' -f2)
REGION=$(grep -E '^region *= *"' "$BACKEND_CONFIG_FILE" | cut -d'"' -f2)
LOCK_TABLE=$(grep -E '^dynamodb_table *= *"' "$BACKEND_CONFIG_FILE" | cut -d'"' -f2)

# Optional: echo for debug
echo "✅ Parsed from $BACKEND_CONFIG_FILE"
echo "🪣 BUCKET: $BUCKET"
echo "🌍 REGION: $REGION"
echo "📦 LOCK_TABLE: $LOCK_TABLE"

echo
echo "⚠️ WARNING: You are about to optionally delete the Terraform backend:"
echo "   S3 bucket: $BUCKET"
echo "   DynamoDB table: $LOCK_TABLE"
echo "   🚨 This backend may be shared across multiple projects!"
echo "   🔥 Deleting it will wipe ALL project state files and locks in this region."
echo

read -p "Do you want to delete the Terraform backend? [y/N]: " CONFIRM_BACKEND
CONFIRM_BACKEND=$(echo "$CONFIRM_BACKEND" | tr '[:upper:]' '[:lower:]')  # to lowercase

if [[ "$CONFIRM_BACKEND" == "y" || "$CONFIRM_BACKEND" == "yes" ]]; then
  if [[ ! -f "$BACKEND_CONFIG_FILE" ]]; then
    echo "❌ Backend config $BACKEND_CONFIG_FILE not found. Run setup first."
    exit 1
  fi

  echo "🧨 Destroying ALL Terraform projects in region: $REGION"
  cd infra

  for VAR_FILE in *"${REGION}"*.tfvars; do
    if [[ -f "$VAR_FILE" ]]; then
      echo "⚙️ Running destroy for $VAR_FILE..."

      # Extract ENV, REGION, and PROJECT_NAME from the filename: format is ENV_REGION_PROJECT.tfvars
      BASENAME=$(basename "$VAR_FILE" .tfvars)
      ENV_PART=$(echo "$BASENAME" | cut -d'_' -f1)
      REGION_PART=$(echo "$BASENAME" | cut -d'_' -f2)
      PROJECT_PART=$(echo "$BASENAME" | cut -d'_' -f3-)

      STATE_KEY="$PROJECT_PART/$ENV_PART/main.tfstate"

      rm -rf .terraform
      terraform init \
        -backend-config="bucket=$BUCKET" \
        -backend-config="region=$REGION_PART" \
        -backend-config="dynamodb_table=$LOCK_TABLE" \
        -backend-config="encrypt=true" \
        -backend-config="key=$STATE_KEY" \
        -reconfigure

      terraform destroy -auto-approve -var-file="$VAR_FILE"
      rm -f "$VAR_FILE"
    fi
  done

  echo "🧹 Deleting backend config file..."
  rm -f "$(basename "$BACKEND_CONFIG_FILE")"

  echo "🧹 Emptying and deleting S3 bucket: $BUCKET..."
  aws s3 rm "s3://$BUCKET" --recursive || true
  aws s3api delete-bucket --bucket "$BUCKET" --region "$REGION" || true

  echo "🧹 Deleting DynamoDB lock table: $LOCK_TABLE..."
  aws dynamodb delete-table --table-name "$LOCK_TABLE" --region "$REGION" || true

  # Extract from infra/backend-config.auto.tfbackend if exists
  if [[ -f "backend-config.auto.tfbackend" ]]; then
    CONFIG_REGION=$(grep -E '^region *= *"' "backend-config.auto.tfbackend" | cut -d'"' -f2)

    # Logic to decide deletion
    if [[ "$CONFIG_REGION" == "$REGION" ]]; then
      echo "🗑️ Deleting infra/backend-config.auto.tfbackend (matches region)"
      rm -f "backend-config.auto.tfbackend"
    else
      echo "⚠️ Not deleting backend-config.auto.tfbackend (different region set)"
    fi
  fi

  cd ..

  echo "✅ Full backend and region-wide cleanup complete!"
else
  # Ask only if user did NOT opt for full backend wipe
  read -p "Enter environment to destroy (dev or prod): " ENV
  if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
    echo "❌ Invalid environment. Must be 'dev' or 'prod'."
    exit 1
  fi

  read -p "Enter the project name: " PROJECT_NAME
  VARS_FILE="${ENV}_${REGION}_${PROJECT_NAME}.tfvars"

  if [[ ! -f "infra/$VARS_FILE" ]]; then
    echo "❌ Variables file $VARS_FILE not found in infra/"
    exit 1
  fi

  echo "⚙️ Destroying Terraform resources for project=$PROJECT_NAME, env=$ENV, region=$REGION"
  cd infra

  STATE_KEY="$PROJECT_NAME/$ENV/main.tfstate"

  rm -rf .terraform
  terraform init -backend-config="bucket=$BUCKET" \
                 -backend-config="region=$REGION" \
                 -backend-config="dynamodb_table=$LOCK_TABLE" \
                 -backend-config="encrypt=true" \
                 -backend-config="key=$STATE_KEY" \
                 -reconfigure
  terraform destroy -auto-approve -var-file="$VARS_FILE"
  rm -f "$VARS_FILE"

  if [[ -f "backend-config.auto.tfbackend" ]]; then
    CONFIG_REGION=$(grep -E '^region *= *"' "backend-config.auto.tfbackend" | cut -d'"' -f2)
    CONFIG_KEY=$(grep -E '^key *= *"' "backend-config.auto.tfbackend" | cut -d'"' -f2)
    # Logic to decide deletion
    if [[ "$CONFIG_REGION" == "$REGION" ]]; then
      if [[ "$CONFIG_KEY" == "$PROJECT_NAME/$ENV/main.tfstate" ]]; then
        echo "🗑️ Deleting backend-config.auto.tfbackend (matches region and key)"
        rm -f "backend-config.auto.tfbackend"
      else
        echo "⚠️ Not deleting backend-config.auto.tfbackend (key and/or region do not match)"
      fi
    fi
  fi

  cd ..
  echo "✅ Terraform resources destroyed for $PROJECT_NAME (backend left intact)."
fi