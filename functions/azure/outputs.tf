output "azure_function_domain" {
    value = azurerm_function_app.function.default_hostname
}