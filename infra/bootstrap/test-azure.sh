#!/usr/bin/env bash

set -euo pipefail

SUBSCRIPTION="b4ad081f-0372-41c5-8b0f-cb32aee8027e"

echo "=== Azure CLI ==="
command -v az
az version

echo
echo "=== Before set ==="
az account show \
  --query '{id:id,name:name,tenant:tenantId,user:user.name}' \
  -o table

echo
echo "=== Setting subscription ==="
az account set --subscription "$SUBSCRIPTION"

echo
echo "=== After set ==="
az account show \
  --query '{id:id,name:name,tenant:tenantId,user:user.name}' \
  -o table

echo
echo "=== Testing ARM operation ==="
az group list \
  --subscription "$SUBSCRIPTION" \
  --output table