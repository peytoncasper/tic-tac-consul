variable "resource_group" {
    type = string
    default = "tic-tac-consul"
}

variable "virtual_network_name" {
    type = string
    default = ""
}

variable "gcp_function_domain" {
    type = string
    default = ""
}

variable "azure_function_domain" {
    type = string
    default = ""
}

variable "aws_function_domain" {
    type = string
    default = ""
}