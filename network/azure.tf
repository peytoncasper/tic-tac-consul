data "azurerm_resource_group" "consul" {
  name = var.resource_group
}

resource "azurerm_virtual_network" "consul" {
  name                = "tic-tac-consul-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.consul.location
  resource_group_name = data.azurerm_resource_group.consul.name
}

resource "azurerm_subnet" "consul" {
  name                 = "consul-subnet"
  resource_group_name  = data.azurerm_resource_group.consul.name
  virtual_network_name = azurerm_virtual_network.consul.name
  address_prefixes       = ["10.0.2.0/24"]

  service_endpoints = ["Microsoft.Web"]
}

resource "azurerm_subnet" "function" {
  name                 = "azure-function-subnet"
  resource_group_name  = data.azurerm_resource_group.consul.name
  virtual_network_name = azurerm_virtual_network.consul.name
  address_prefixes       = ["10.0.3.0/24"]


  delegation {
    name = "azurefuncdelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}