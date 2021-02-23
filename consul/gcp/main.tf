data "archive_file" "web" {
  type        = "zip"
  source_dir = "web/"
  output_path = "${path.module}/web.zip"
}

resource "google_compute_address" "consul" {
  name = "consul-pip"
}

resource "google_compute_instance" "consul" {
  name         = "gcp-consul-server"
  machine_type = "e2-medium"
  zone         = "us-east1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "tic-tac-consul-network"

    access_config {
      nat_ip = google_compute_address.consul.address
    }
  }

  metadata_startup_script = templatefile(
    "${path.module}/templates/consul.tpl",
    {
      consul_version = "1.8.8",
      bootstrap_ip = var.bootstrap_ip
      enable_consul_server = true,
      datacenter = "gcp",
      node_name = "server-0",
      encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU=",
      public_ip = google_compute_address.consul.address
      aws_function_domain = var.aws_function_domain
      azure_function_domain = var.azure_function_domain
      gcp_function_domain = var.gcp_function_domain
    }
  )

  metadata = {
    ssh-keys = "peytoncas:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "file" {
    source      = "${path.module}/web.zip"
    destination = "/tmp/web.zip"
    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "file" {
    source      = "certs/gcp-server-consul-0.pem"
    destination = "/tmp/gcp-server-consul-0.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "file" {
    source      = "certs/gcp-server-consul-0-key.pem"
    destination = "/tmp/gcp-server-consul-0-key.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }


  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

///
/// Client 1
///

resource "google_compute_address" "consul_client_0" {
  name = "consul-client-0-pip"
}

resource "google_compute_instance" "consul_client_0" {
  name         = "gcp-consul-client-0"
  machine_type = "e2-small"
  zone         = "us-east1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "tic-tac-consul-network"

    access_config {
      nat_ip = google_compute_address.consul_client_0.address
    }
  }
  metadata_startup_script = templatefile(
    "${path.module}/templates/consul_client.tpl",
    {
      id = "0"
      consul_version = "1.8.8",
      enable_consul_server = false,
      datacenter = "gcp",
      node_name = "client-0",
      encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU=",
      public_ip = google_compute_address.consul_client_0.address
      aws_function_domain = var.aws_function_domain
      azure_function_domain = var.azure_function_domain
      gcp_function_domain = var.gcp_function_domain

      local_consul_server_ip = google_compute_instance.consul.network_interface.0.network_ip

      client_type = "terminating"
    }
  )

  metadata = {
    ssh-keys = "peytoncas:${file("~/.ssh/id_rsa.pub")}"
  }


  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "file" {
    source      = "certs/gcp-client-consul-0.pem"
    destination = "/tmp/gcp-client-consul-0.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "file" {
    source      = "certs/gcp-client-consul-0-key.pem"
    destination = "/tmp/gcp-client-consul-0-key.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

///
/// Client 2
///

resource "google_compute_address" "consul_client_1" {
  name = "consul-client-1-pip"
}

resource "google_compute_instance" "consul_client_1" {
  name         = "gcp-consul-client-1"
  machine_type = "e2-small"
  zone         = "us-east1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "tic-tac-consul-network"

    access_config {
      nat_ip = google_compute_address.consul_client_1.address
    }
  }
  metadata_startup_script = templatefile(
    "${path.module}/templates/consul_client.tpl",
    {
      id = "1"
      consul_version = "1.8.8",
      enable_consul_server = false,
      datacenter = "gcp",
      node_name = "client-1",
      encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU=",
      public_ip = google_compute_address.consul_client_1.address
      aws_function_domain = var.aws_function_domain
      azure_function_domain = var.azure_function_domain
      gcp_function_domain = var.gcp_function_domain

      local_consul_server_ip = google_compute_instance.consul.network_interface.0.network_ip

      client_type = "ingress"
    }
  )

  metadata = {
    ssh-keys = "peytoncas:${file("~/.ssh/id_rsa.pub")}"
  }


  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "file" {
    source      = "certs/gcp-client-consul-1.pem"
    destination = "/tmp/gcp-client-consul-1.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "file" {
    source      = "certs/gcp-client-consul-1-key.pem"
    destination = "/tmp/gcp-client-consul-1-key.pem"

    connection {
      type     = "ssh"
      user     = "peytoncas"
      private_key = file("~/.ssh/id_rsa")
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }


  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}