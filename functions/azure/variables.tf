variable "resource_group" {
    type = string
    default = "tic-tac-consul"
}

variable "virtual_network_name" {
    type = string
    default = "tic-tac-consul-network"
}

variable "function_subnet_name" {
    type = string
    default = "azure-function-subnet"
}

variable "consul_subnet_name" {
    type = string
    default = "consul-subnet"
}