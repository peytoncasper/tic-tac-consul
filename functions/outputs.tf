output "azure_function_domain" {
    value = module.azure.azure_function_domain
}

output "gcp_function_domain" {
    value = module.gcp.gcp_function_domain
}

output "aws_function_domain" {
    value = module.aws.aws_function_domain
}