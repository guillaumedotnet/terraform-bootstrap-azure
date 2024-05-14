terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "name_prefix" {
  length  = 8
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}-${random_string.name_prefix.result}"
  common_tags = {
    id      = random_string.name_prefix.result
    project = var.project_name
    env     = var.environment
  }

  current_user_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location

  tags = local.common_tags
}

resource "azurerm_storage_account" "tfstate-st" {
  name                     = "${replace(local.name_prefix, "-", "")}tfstatest"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

resource "azurerm_storage_container" "tfstate-st-tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate-st.name
  container_access_type = "private"
}
