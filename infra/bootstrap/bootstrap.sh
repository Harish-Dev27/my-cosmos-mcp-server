#!/usr/bin/env bash
set -euo pipefail

set -x

# Set these environment variables before running this script.
AZURE_TENANT_ID="df559a91-563a-4230-85e9-fbfb218ff1a2"
AZURE_SUBSCRIPTION_ID="b4ad081f-0372-41c5-8b0f-cb32aee8027e"
AZURE_LOCATION="indiasouthcentral"
TFSTATE_RESOURCE_GROUP="rg-mcp-project-tf"
TFSTATE_STORAGE_ACCOUNT="stmcpservertfshb"
TFSTATE_CONTAINER="tfstate"
MY_PUBLIC_IP="223.181.0.0/16"

required_vars=(
	AZURE_SUBSCRIPTION_ID
	AZURE_TENANT_ID
	TFSTATE_STORAGE_ACCOUNT
	MY_PUBLIC_IP
)

for variable in "${required_vars[@]}"; do
	if [[ -z "${!variable}" ]]; then
		printf 'Error: set the %s environment variable.\n' "$variable" >&2
		exit 1
	fi
done

if ! command -v az >/dev/null 2>&1; then
	printf 'Error: Azure CLI (az) is required.\n' >&2
	exit 1
fi

active_tenant_id="$(az account show --query tenantId --output tsv 2>/dev/null || true)"
if [[ "$active_tenant_id" != "$AZURE_TENANT_ID" ]]; then
	printf 'Error: log in to the configured tenant first: az login --tenant %s\n' \
		"$AZURE_TENANT_ID" >&2
	exit 1
fi

# Set subscription
az account set \
    --subscription "$AZURE_SUBSCRIPTION_ID"

# Verify Azure context
az account show \
    --query '{subscription:id, name:name, tenant:tenantId}' \
    --output table

# Create resource group for the Terraform state storage account
az group create \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --name "$TFSTATE_RESOURCE_GROUP" \
    --location "$AZURE_LOCATION" \
    --output none

# Create storage account
az storage account create \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --name "$TFSTATE_STORAGE_ACCOUNT" \
    --resource-group "$TFSTATE_RESOURCE_GROUP" \
    --location "$AZURE_LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --access-tier Hot \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --output none

# Deny all network traffic by default
az storage account update \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --name "$TFSTATE_STORAGE_ACCOUNT" \
    --resource-group "$TFSTATE_RESOURCE_GROUP" \
    --default-action Deny \
    --bypass None \
    --output none

# Allow traffic only from my public IP
az storage account network-rule add \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --account-name "$TFSTATE_STORAGE_ACCOUNT" \
    --resource-group "$TFSTATE_RESOURCE_GROUP" \
    --ip-address "$MY_PUBLIC_IP" \
    --output none

# Create the blob container
az storage container create \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --name "$TFSTATE_CONTAINER" \
    --account-name "$TFSTATE_STORAGE_ACCOUNT" \
    --auth-mode login \
    --public-access off \
    --output none

printf 'Terraform state storage is ready: %s/%s\n' \
    "$TFSTATE_STORAGE_ACCOUNT" \
    "$TFSTATE_CONTAINER"
