terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.114.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "random_string" "rand" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_storage_account" "src" {
  name                     = "${var.prefix}src${random_string.rand.result}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "incoming" {
  name                  = "incoming"
  storage_account_name  = azurerm_storage_account.src.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "dst" {
  name                     = "${var.prefix}dst${random_string.rand.result}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "processed" {
  name                  = "processed"
  storage_account_name  = azurerm_storage_account.dst.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "func" {
  name                     = "${var.prefix}func${random_string.rand.result}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-plan-func-tp4"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "fa" {
  name                       = "${var.prefix}-fa-copy-tp4"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.func.name
  storage_account_access_key = azurerm_storage_account.func.primary_access_key

  site_config {
    application_stack {
      node_version = "20"
    }
  }

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~4"
    FUNCTIONS_WORKER_RUNTIME    = "node"
    AzureWebJobsStorage         = azurerm_storage_account.func.primary_connection_string
    AzureWebJobsSourceStorage   = azurerm_storage_account.src.primary_connection_string
    DEST_CONNECTION             = azurerm_storage_account.dst.primary_connection_string
    DEST_CONTAINER              = "processed"
    WEBSITE_RUN_FROM_PACKAGE    = "1"
  }
}

output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "function_name" {
  value = azurerm_linux_function_app.fa.name
}

output "source_account_name" {
  value = azurerm_storage_account.src.name
}

output "dest_account_name" {
  value = azurerm_storage_account.dst.name
}
