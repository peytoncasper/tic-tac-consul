output "vpc_id" {
    value = aws_vpc.consul.id
}

output "consul_subnet_id" {
    value = aws_subnet.consul.id
}

output "aws_security_group_id" {
    value = aws_security_group.consul.id
}


output "azure_virtual_network_name" {
    value = azurerm_virtual_network.consul.name
}