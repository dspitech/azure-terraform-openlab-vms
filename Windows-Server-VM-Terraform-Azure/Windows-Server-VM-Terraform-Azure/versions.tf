terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}

  # Laisser à null : la valeur est lue depuis ARM_SUBSCRIPTION_ID
  # (déjà définie dans Azure Cloud Shell) ou depuis le terraform.tfvars.
  subscription_id = var.subscription_id
}
