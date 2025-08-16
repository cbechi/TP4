#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Build zip with function code
( cd function/CopyOnUpload && npm install )
( cd function && zip -r ../functionapp.zip . )

# Read outputs from Terraform to get names
APP_NAME=$(terraform -chdir=infra output -raw function_name)
RG_NAME=$(terraform -chdir=infra output -raw resource_group_name)

# Deploy
az functionapp deployment source config-zip -g "$RG_NAME" -n "$APP_NAME" --src functionapp.zip
echo "Function code deployed."
