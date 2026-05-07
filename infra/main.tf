# --- Provider Configuration ---
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# --- Variables & Locals ---
variable "location" {
  type    = string
  default = "eastus"
}

variable "project_name" {
  type    = string
  default = "cloud-resume"
}

locals {
  # Clean naming convention for resources
  prefix       = "ha" # Initials/Identifier
  env          = "prod"
  base_name    = "${local.prefix}-${var.project_name}-${local.env}"
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

# --- Telemetry Layer (Observability) ---
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

# --- Frontend (Static Website) ---
resource "azurerm_storage_account" "frontend" {
  name                     = "${local.storage_name}web"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Enabling the static website feature
  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = local.common_tags
}

# --- Backend API (Function App) ---
resource "azurerm_storage_account" "func_backend" {
  name                     = "${local.storage_name}func"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "func_plan" {
  name                = "asp-${local.base_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption tier
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
    application_insights_key               = azurerm_application_insights.telemetry.instrumentation_key
    
    cors {
      # Restricts API calls to your specific frontend URL
      allowed_origins = [trimsuffix(azurerm_storage_account.frontend.primary_web_endpoint, "/")]
    }
  }

  # Security Implementation: Managed Identity
  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "WORKSPACE_ID" = azurerm_log_analytics_workspace.telemetry.workspace_id
  }

  tags = local.common_tags
}

# --- Security: RBAC Assignment ---
# Grants the Function App permission to query the Log Analytics Workspace 
# without needing a connection string or API keys.
resource "azurerm_role_assignment" "telemetry_reader" {
  scope                = azurerm_log_analytics_workspace.telemetry.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_linux_function_app.api.identity[0].principal_id
}

# --- Outputs ---
output "frontend_url" {
  description = "The static website endpoint"
  value       = azurerm_storage_account.frontend.primary_web_endpoint
}

output "api_hostname" {
  description = "The hostname of the Function App API"
  value       = azurerm_linux_function_app.api.default_hostname
}
