output "azure_function_hostname" {
    value = module.functions.azure_function_domain
}

output "gcp_function_hostname" {
    value = trimsuffix(trimprefix(module.functions.gcp_function_domain, "https://"), "tic-tac-consul-function")
}

output "aws_function_name" {
    value = trimsuffix(trimprefix(module.functions.aws_function_domain, "https://"), "/dev")
}