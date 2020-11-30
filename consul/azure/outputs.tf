output "consul_ip" {
    value = data.azurerm_public_ip.consul.ip_address
}