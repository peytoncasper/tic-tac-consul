output "Tic-Tac-Consul-Web-UI" {
    value = "http://${module.gcp.web_ui}"
}

output "Consul-UI" {
    value = "http://${module.gcp.web_ui}:8500"
}
