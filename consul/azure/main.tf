data "azurerm_resource_group" "consul" {
  name     = var.resource_group
}

data "azurerm_virtual_network" "consul" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.consul.name
}

data "azurerm_subnet" "function" {
  name                 = "azure-function-subnet"
  virtual_network_name = var.virtual_network_name
  resource_group_name  = data.azurerm_resource_group.consul.name
}

data "azurerm_subnet" "consul" {
  name                 = "consul-subnet"
  virtual_network_name = var.virtual_network_name
  resource_group_name  = data.azurerm_resource_group.consul.name
}

resource "azurerm_network_security_group" "consul" {
  name                = "consul"
  location            = data.azurerm_resource_group.consul.location
  resource_group_name = data.azurerm_resource_group.consul.name

  security_rule {
    name                       = "consul-inbound-tcp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "consul-inbound-udp"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "consul-outbound-tcp"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "consul-outbound-udp"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "consul" {
  network_interface_id      = azurerm_network_interface.consul.id
  network_security_group_id = azurerm_network_security_group.consul.id
}

resource "azurerm_public_ip" "consul" {
  name                    = "consul-pip"
  location                = data.azurerm_resource_group.consul.location
  resource_group_name     = data.azurerm_resource_group.consul.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}


data "azurerm_public_ip" "consul" {
  name                = "consul-pip"
  resource_group_name = data.azurerm_resource_group.consul.name

  depends_on = [azurerm_public_ip.consul]
}

resource "azurerm_network_interface" "consul" {
  name                = "consul-server-nic"
  location            = data.azurerm_resource_group.consul.location
  resource_group_name = data.azurerm_resource_group.consul.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.consul.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.consul.id
  }
}

resource "azurerm_linux_virtual_machine" "consul" {
  name                = "consul-server"
  resource_group_name = data.azurerm_resource_group.consul.name
  location            = data.azurerm_resource_group.consul.location
  size                = "Standard_B1MS"

  admin_username = "peytoncas"

  network_interface_ids = [
    azurerm_network_interface.consul.id,
  ]

  custom_data = base64encode(templatefile(
      "${path.module}/templates/consul.tpl",
      {
        consul_version = "1.8.4",
        enable_consul_server = true,
        datacenter = "azure",
        node_name = "server-0",
        encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU="
        public_ip = data.azurerm_public_ip.consul.ip_address
        aws_function_domain = var.aws_function_domain
        azure_function_domain = var.azure_function_domain
        gcp_function_domain = var.gcp_function_domain
      }
    )
  )

  admin_ssh_key {
    username   = "peytoncas"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  provisioner "file" {
    source      = "certs/azure-server-consul-0.pem"
    destination = "/tmp/azure-server-consul-0.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  provisioner "file" {
    source      = "certs/azure-server-consul-0-key.pem"
    destination = "/tmp/azure-server-consul-0-key.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  depends_on = [data.azurerm_public_ip.consul]
}

///
/// Client 1
///

resource "azurerm_public_ip" "consul_client_0" {
  name                    = "consul-client-0-gateway-pip"
  location                = data.azurerm_resource_group.consul.location
  resource_group_name     = data.azurerm_resource_group.consul.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}


data "azurerm_public_ip" "consul_client_0" {
  name                = "consul-client-0-gateway-pip"
  resource_group_name = data.azurerm_resource_group.consul.name

  depends_on = [azurerm_public_ip.consul_client_0]
}

resource "azurerm_network_interface" "consul_client_0" {
  name                = "consul-client-0-gateway-nic"
  location            = data.azurerm_resource_group.consul.location
  resource_group_name = data.azurerm_resource_group.consul.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.consul.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.consul_client_0.id
  }
}


resource "azurerm_linux_virtual_machine" "consul_client_0" {
  name                = "consul-client-0"
  resource_group_name = data.azurerm_resource_group.consul.name
  location            = data.azurerm_resource_group.consul.location
  size                = "Standard_B1MS"

  admin_username = "peytoncas"

  network_interface_ids = [
    azurerm_network_interface.consul_client_0.id,
  ]

  custom_data = base64encode(templatefile(
      "${path.module}/templates/consul_client.tpl",
      {
        id = "0"
        consul_version = "1.8.4",
        enable_consul_server = false,
        datacenter = "azure",
        node_name = "client-0",
        encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU="
        public_ip = data.azurerm_public_ip.consul_client_0.ip_address

        aws_function_domain = var.aws_function_domain
        azure_function_domain = var.azure_function_domain
        gcp_function_domain = var.gcp_function_domain

        local_consul_server_ip = data.azurerm_public_ip.consul.ip_address

        client_type = "terminating"
      }
    )
  )

  admin_ssh_key {
    username   = "peytoncas"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }


  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  provisioner "file" {
    source      = "certs/azure-client-consul-0.pem"
    destination = "/tmp/azure-client-consul-0.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  provisioner "file" {
    source      = "certs/azure-client-consul-0-key.pem"
    destination = "/tmp/azure-client-consul-0-key.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  depends_on = [data.azurerm_public_ip.consul_client_0]
}

///
/// Client 2
///

resource "azurerm_public_ip" "consul_client_1" {
  name                    = "consul-client-1-gateway-pip"
  location                = data.azurerm_resource_group.consul.location
  resource_group_name     = data.azurerm_resource_group.consul.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}


data "azurerm_public_ip" "consul_client_1" {
  name                = "consul-client-1-gateway-pip"
  resource_group_name = data.azurerm_resource_group.consul.name

  depends_on = [azurerm_public_ip.consul_client_1]
}

resource "azurerm_network_interface" "consul_client_1" {
  name                = "consul-client-1-gateway-nic"
  location            = data.azurerm_resource_group.consul.location
  resource_group_name = data.azurerm_resource_group.consul.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.consul.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.consul_client_1.id
  }
}


resource "azurerm_linux_virtual_machine" "consul_client_1" {
  name                = "consul-client-1"
  resource_group_name = data.azurerm_resource_group.consul.name
  location            = data.azurerm_resource_group.consul.location
  size                = "Standard_B1MS"

  admin_username = "peytoncas"

  network_interface_ids = [
    azurerm_network_interface.consul_client_1.id,
  ]

  custom_data = base64encode(templatefile(
      "${path.module}/templates/consul_client.tpl",
      {
        id = "1"
        consul_version = "1.8.4",
        enable_consul_server = false,
        datacenter = "azure",
        node_name = "client-1",
        encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU="
        public_ip = data.azurerm_public_ip.consul_client_0.ip_address

        aws_function_domain = var.aws_function_domain
        azure_function_domain = var.azure_function_domain
        gcp_function_domain = var.gcp_function_domain

        local_consul_server_ip = data.azurerm_public_ip.consul.ip_address

        client_type = "ingress"
      }
    )
  )

  admin_ssh_key {
    username   = "peytoncas"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }


  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  provisioner "file" {
    source      = "certs/azure-client-consul-1.pem"
    destination = "/tmp/azure-client-consul-1.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  provisioner "file" {
    source      = "certs/azure-client-consul-1-key.pem"
    destination = "/tmp/azure-client-consul-1-key.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip_address
    }
  }

  depends_on = [data.azurerm_public_ip.consul_client_1]
}