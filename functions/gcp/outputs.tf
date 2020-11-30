output "gcp_function_domain" {
    value = google_cloudfunctions_function.function.https_trigger_url
}