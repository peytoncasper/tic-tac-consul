resource "google_compute_firewall" "consul-in" {
  name    = "consul-firewall-in"
  network = google_compute_network.consul.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "consul-out" {
  name    = "consul-firewall-out"
  network = google_compute_network.consul.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_network" "consul" {
  name = "tic-tac-consul-network"
}