variable "vpc_id" {
    type = string
}

variable "subnet_id" {
    type = string
}

variable "security_group_id" {
    type = string
}

variable "bootstrap_ip" {
    
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