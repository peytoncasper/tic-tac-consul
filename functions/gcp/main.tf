data "archive_file" "function" {
  type        = "zip"
  source_dir = "${path.module}/code"
  output_path = "${path.module}/code.zip"
}

resource "random_id" "id" {
  byte_length = 8

  keepers = {
    hash = data.archive_file.function.output_md5
  }
}

resource "google_vpc_access_connector" "function" {
  name          = "tic-tac-conn"
  region        = "us-east1"
  ip_cidr_range = "10.8.0.0/28"
  network       = "tic-tac-consul-network"
}


resource "google_cloudfunctions_function" "function" {
  name        = "tic-tac-consul-function"
  description = "Function for Tic-Tac-Consul"
  runtime     = "python37"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.function.name
  source_archive_object = google_storage_bucket_object.function.name
  trigger_http          = true
  entry_point           = "run"

  vpc_connector = google_vpc_access_connector.function.id
  vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"

  ingress_settings = "ALLOW_INTERNAL_ONLY"
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}


///
// Storage Bucket
///

resource "google_storage_bucket" "function" {
  name = "function-bucket-${random_id.id.hex}"
}

resource "google_storage_bucket_object" "function" {
  name   = "code.zip"
  bucket = google_storage_bucket.function.name
  source = "${path.module}/code.zip"
}