# --- Provider Configuration ---
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

# --- Variables & Locals ---
variable "location" {
  type        = string
  description = "Azure region for resource deployment"
  default     = "eastus"
}

variable "project_name" {
  type        = string
  description = "Base project naming token"
  default     = "cloud-resume"
}

locals {
  prefix       = "ha"
  env          = "prod"
  base_name    = "${local.prefix}-${var.project_name}-${local.env}"
  # Storage accounts allow max 24 lowercase alphanumeric characters
  storage_name = "${local.prefix}${replace(var.project_name, "-", "")}${local.env}"

  common_tags = {
    Project   = "Cloud Resume Challenge"
    ManagedBy = "Terraform"
    Owner     = "Hunter Aiton"
  }
}

# --- Resource Group ---
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.common_tags
}

# --- Telemetry & Observability Layer ---
resource "azurerm_log_analytics_workspace" "telemetry" {
  name                = "log-${local.base_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_application_insights" "telemetry" {
  name                = "appi-${local.base_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.telemetry.id
  application_type    = "web"
  tags                = local.common_tags
}

# --- Frontend (Static Website Hosting) ---
resource "azurerm_storage_account" "frontend" {
  name                     = "${local.storage_name}web"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = local.common_tags
}

# --- Backend API (Python Azure Function) ---
resource "azurerm_storage_account" "func_backend" {
  name                     = "${local.storage_name}func"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.common_tags
}

resource "azurerm_service_plan" "func_plan" {
  name                = "asp-${local.base_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1" # Serverless Consumption Plan
  tags                = local.common_tags
}

resource "azurerm_linux_function_app" "api" {
  name                = "func-${local.base_name}-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.func_backend.name
  storage_account_access_key = azurerm_storage_account.func_backend.primary_access_key
  service_plan_id            = azurerm_service_plan.func_plan.id

  site_config {
    application_insights_connection_string = azurerm_application_insights.telemetry.connection_string

    application_stack {
      python_version = "3.11"
    }

    cors {
      # Permits direct calls from your storage account static web host
      allowed_origins = [
        trimsuffix(azurerm_storage_account.frontend.primary_web_endpoint, "/"),
        "https://portal.azure.com"
      ]
      support_credentials = false
    }
  }

  # Security: System-Assigned Identity used for querying Log Analytics
  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    # Aligns with os.environ.get("LOG_ANALYTICS_WORKSPACE_ID") in __init__.py
    "LOG_ANALYTICS_WORKSPACE_ID" = azurerm_log_analytics_workspace.telemetry.workspace_id
    "APP_REQUESTS_TABLE"         = "AppRequests"
    "ENABLE_ORYX_BUILD"          = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  tags = local.common_tags
}

# --- RBAC Role Assignment ---
# Allows the Function App's Managed Identity to run KQL queries via LogsQueryClient
resource "azurerm_role_assignment" "telemetry_reader" {
  scope                = azurerm_log_analytics_workspace.telemetry.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_linux_function_app.api.identity[0].principal_id
}

# --- Outputs ---
output "frontend_web_endpoint" {
  description = "Static Website primary endpoint URL"
  value       = azurerm_storage_account.frontend.primary_web_endpoint
}

output "function_app_default_hostname" {
  description = "Function App hostname"
  value       = "https://${azurerm_linux_function_app.api.default_hostname}"
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.telemetry.workspace_id
}
