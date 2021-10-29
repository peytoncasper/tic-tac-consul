resource "null_resource" "consul_ca" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls ca create
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm consul-agent-ca.pem
    rm consul-agent-ca-key.pem
    EOD
  }
}

/// Generate GCP DC Consul Certs

resource "null_resource" "consul_gcp_server_0" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=gcp -node=server-0 -server
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm gcp-server-consul-0.pem
    rm gcp-server-consul-0-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca
  ]
}

resource "null_resource" "consul_gcp_client_1" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=gcp -client
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm gcp-client-consul-0.pem
    rm gcp-client-consul-0-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca
  ]
}


resource "null_resource" "consul_gcp_client_2" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=gcp -client
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm gcp-client-consul-1.pem
    rm gcp-client-consul-1-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca,
    null_resource.consul_gcp_client_1
  ]
}

/// Generate Azure DC Consul Certs

resource "null_resource" "consul_azure_server_0" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=azure -node="server-0" -server
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm azure-server-consul-0.pem
    rm azure-server-consul-0-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca
  ]
}

resource "null_resource" "consul_azure_client_1" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=azure -client
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm azure-client-consul-0.pem
    rm azure-client-consul-0-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca

  ]
}


resource "null_resource" "consul_azure_client_2" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=azure -client
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm azure-client-consul-1.pem
    rm azure-client-consul-1-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca,
    null_resource.consul_azure_client_1
  ]
}


/// Generate AWS DC Consul Certs

resource "null_resource" "consul_aws_server_0" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=aws -node="server-0" -server
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm aws-server-consul-0.pem
    rm aws-server-consul-0-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca
  ]
}

resource "null_resource" "consul_aws_client_1" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=aws -client
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm aws-client-consul-0.pem
    rm aws-client-consul-0-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca
  ]
}


resource "null_resource" "consul_aws_client_2" {
  provisioner "local-exec" {
    working_dir = "${path.module}"
    command = <<-EOD
    consul tls cert create -dc=aws -client
    EOD
  }

  provisioner "local-exec" {
    when    = destroy
    working_dir = "${path.module}"
    command = <<-EOD
    rm aws-client-consul-1.pem
    rm aws-client-consul-1-key.pem
    EOD
  }
  depends_on = [
    null_resource.consul_ca,
    null_resource.consul_aws_client_1

  ]
}

