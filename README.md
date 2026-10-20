# Cosmos MCP Task Server

A small [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server for managing tasks. It runs locally with Python or in Azure Container Apps using the included Docker image and GitHub Actions workflow.

> **Current storage:** tasks are held in memory and reset when the server restarts. The current Terraform configuration deploys Azure Container Apps; it does not yet provision a Cosmos DB account or table.

## What you can do

The MCP server provides these tools:

| Tool | Description |
| --- | --- |
| `list_tasks` | List all tasks |
| `get_task` | Get a task by its ID |
| `create_task` | Create a task with a title and description |
| `toggle_task_complete` | Mark a task complete or incomplete |
| `delete_task` | Delete a task |

The server starts with two sample tasks. Its `/health` endpoint returns a simple health status.

## Run locally

### Requirements

- Python 3.14 or newer
- [uv](https://docs.astral.sh/uv/)

From the repository root, install dependencies and start the server:

```bash
cd src
uv sync
uv run uvicorn main.app:app --host 0.0.0.0 --port 8080
```

The MCP endpoint is `http://localhost:8080/mcp`. To check that the server is running, open another terminal and run:

```bash
curl http://localhost:8080/health
```

The checked-in `.mcp.json` configures an MCP client to connect to the local server. Start the server before connecting with your MCP client.

## Run with Docker

From the repository root:

```bash
docker build -t cosmos-mcp .
docker run --rm -p 8080:8080 cosmos-mcp
```

The container listens on port `8080`; the MCP endpoint and health check are the same as for the local run.

## Deploy to Azure

The deployment uses Terraform for Azure infrastructure and GitHub Actions to build and deploy the application:

1. `infra/terraform/` defines the resource group, Container Apps environment and app, and a user-assigned identity with a GitHub federated credential.
2. `.github/workflows/deploy-to-aca.yaml` runs when code is pushed to `main`. It builds the Docker image, pushes it to GitHub Container Registry, then updates the Azure Container App to use that image.

### Requirements

- An Azure subscription with permission to create the configured resources
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), signed in to the intended tenant and subscription
- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5 or newer
- A GitHub repository with Actions enabled and an Azure federated identity credential configured for that repository and the `main` branch

### Provision infrastructure

The Terraform backend settings are in `infra/terraform/config/config.tf`; input values are in `infra/terraform/variables/terraform.tfvars`. Review both files and update them for your Azure environment before applying. The configured remote state storage account and container must exist before Terraform initialization.

```bash
cd infra/terraform
terraform init -backend-config=config/config.tf
terraform plan -var-file=variables/terraform.tfvars
terraform apply -var-file=variables/terraform.tfvars
```

Review the plan before applying. Terraform outputs the Container App URL and GitHub Actions identity details. Before deploying, ensure the Azure client, tenant, subscription, and federated credential used by the workflow match the identity and repository configuration in your environment.

After infrastructure is ready, push a commit to `main` to trigger the build-and-deploy workflow. Check the **Actions** tab in GitHub for its status. The workflow deploys the application image to the existing Container App.

> The bootstrap script in `infra/bootstrap/` is for preparing Terraform state storage. Review its Azure account and network settings for your environment before running it.

## Project layout

```text
.
├── Dockerfile
├── .github/workflows/deploy-to-aca.yaml
├── infra/
│   ├── bootstrap/       # Azure/Terraform state setup scripts
│   └── terraform/       # Azure Container Apps infrastructure
└── src/
    ├── pyproject.toml   # Python dependencies and version requirement
    └── main/            # FastAPI app, MCP tools, and in-memory task store

```