data "archive_file" "function" {
  type        = "zip"
  source_dir = "${path.module}/code"
  output_path = "${path.module}/code.zip"
}

resource "random_id" "id" {
  byte_length = 8

  keepers = {
    hash = data.archive_file.function.output_md5
  }
}

locals {
    azure_function_name = "azure-functions-${random_id.id.hex}"
}

data "azurerm_resource_group" "function" {
  name = var.resource_group
}

data "azurerm_subnet" "function" {
  name                 = var.function_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = data.azurerm_resource_group.function.name
}

data "azurerm_subnet" "consul" {
  name                 = var.consul_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = data.azurerm_resource_group.function.name
}

resource "azurerm_app_service_plan" "function" {
  name                = "azure-function-service-plan"
  location            = data.azurerm_resource_group.function.location
  resource_group_name = data.azurerm_resource_group.function.name

  kind = "linux"

  sku {
    tier = "Premium"
    size = "EP1"
  }

  reserved = true
}

resource "azurerm_function_app" "function" {
    name                       = local.azure_function_name
    location                   = data.azurerm_resource_group.function.location
    resource_group_name        = data.azurerm_resource_group.function.name
    app_service_plan_id        = azurerm_app_service_plan.function.id
    storage_account_name       = azurerm_storage_account.function.name
    storage_account_access_key = azurerm_storage_account.function.primary_access_key
    version = "~3"

    site_config {
      ip_restriction = [{
        name = "Allow Consul"
        ip_address = null
        subnet_id = data.azurerm_subnet.consul.id
        virtual_network_subnet_id = data.azurerm_subnet.consul.id
        action = "Allow"
        priority = 100
      }]
    }

    app_settings = {
        https_only = false
        FUNCTIONS_WORKER_RUNTIME = "python"
        FUNCTION_APP_EDIT_MODE = "readonly"
        "AzureWebJobsDisableHomepage" = true
        HASH = data.archive_file.function.output_base64sha256
        WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.function.name}.blob.core.windows.net/${azurerm_storage_container.function.name}/${azurerm_storage_blob.function.name}${data.azurerm_storage_account_sas.function.sas}"
    }
}

resource "azurerm_app_service_virtual_network_swift_connection" "function" {
  app_service_id = azurerm_function_app.function.id
  subnet_id      = data.azurerm_subnet.function.id
}


///
// Function Storage Account for Uploading Code Zip File
///

resource "azurerm_storage_account" "function" {
  name                     = "function${random_id.id.hex}"
  resource_group_name      = data.azurerm_resource_group.function.name
  location                 = data.azurerm_resource_group.function.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "function" {
  name                  = "function"
  storage_account_name  = azurerm_storage_account.function.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "function" {
  name                   = "code.zip"
  storage_account_name   = azurerm_storage_account.function.name
  storage_container_name = azurerm_storage_container.function.name
  type                   = "Block"
  source                 = "${path.module}/code.zip"

  depends_on=[data.archive_file.function]
}

data "azurerm_storage_account_sas" "function" {
    connection_string = azurerm_storage_account.function.primary_connection_string
    https_only = true
    start = "2019-01-01"
    expiry = "2022-12-31"
    resource_types {
        object = true
        container = false
        service = false
    }
    services {
        blob = true
        queue = false
        table = false
        file = false
    }
    permissions {
        read = true
        write = false
        delete = false
        list = false
        add = false
        create = false
        update = false
        process = false
    }
}