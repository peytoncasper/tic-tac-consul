data "aws_security_groups" "consul" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "ami-id"
#     values = ["ami-010bb5f550c901adb"]
#   }

#   owners = ["679593333241"]
# }

resource "aws_key_pair" "consul" {
  key_name   = "tic-tac-consul-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_network_interface" "consul" {
  subnet_id   = var.subnet_id
}

resource "aws_eip" "consul" {
  vpc  = true
}

resource "aws_eip_association" "consul" {
  instance_id   = aws_instance.consul.id
  allocation_id = aws_eip.consul.id

  network_interface_id = aws_network_interface.consul.id
}


resource "aws_instance" "consul" {
  # ami           = data.aws_ami.ubuntu.id
  ami = "ami-010bb5f550c901adb"
  instance_type = "t3.small"

  associate_public_ip_address = true

  subnet_id = var.subnet_id

  key_name = aws_key_pair.consul.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile(
    "${path.module}/templates/consul.tpl",
    {
      consul_version = "1.8.8",
      enable_consul_server = true,
      bootstrap_ip = var.bootstrap_ip,
      datacenter = "aws",
      node_name = "server-0",
      encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU="
      public_ip = aws_eip.consul.public_ip
      aws_function_domain = var.aws_function_domain
      azure_function_domain = var.azure_function_domain
      gcp_function_domain = var.gcp_function_domain
    }
  )

  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }

  provisioner "file" {
    source      = "certs/aws-server-consul-0.pem"
    destination = "/tmp/aws-server-consul-0.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }

  provisioner "file" {
    source      = "certs/aws-server-consul-0-key.pem"
    destination = "/tmp/aws-server-consul-0-key.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }
}

///
/// Client 1
/// 

resource "aws_network_interface" "consul_client_0" {
  subnet_id   = var.subnet_id
}

resource "aws_eip" "consul_client_0" {
  vpc  = true
}

resource "aws_eip_association" "consul_client_0" {
  instance_id   = aws_instance.consul_client_0.id
  allocation_id = aws_eip.consul_client_0.id

  network_interface_id = aws_network_interface.consul_client_0.id
}


resource "aws_instance" "consul_client_0" {
  # ami           = data.aws_ami.ubuntu.id
  ami = "ami-010bb5f550c901adb"
  instance_type = "t3.small"

  associate_public_ip_address = true

  subnet_id = var.subnet_id

  key_name = aws_key_pair.consul.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile(
    "${path.module}/templates/consul_client.tpl",
    {
      id = "0"
      consul_version = "1.8.8",
      enable_consul_server = false,
      datacenter = "aws",
      node_name = "client-0",
      encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU="
      public_ip = aws_eip.consul_client_0.public_ip
      aws_function_domain = var.aws_function_domain
      azure_function_domain = var.azure_function_domain
      gcp_function_domain = var.gcp_function_domain

      local_consul_server_ip = aws_eip.consul.public_ip

      client_type = "terminating"
    }
  )

  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }

  provisioner "file" {
    source      = "certs/aws-client-consul-0.pem"
    destination = "/tmp/aws-client-consul-0.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }

  provisioner "file" {
    source      = "certs/aws-client-consul-0-key.pem"
    destination = "/tmp/aws-client-consul-0-key.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }
}

///
/// Client 2
/// 

resource "aws_network_interface" "consul_client_1" {
  subnet_id   = var.subnet_id
}

resource "aws_eip" "consul_client_1" {
  vpc  = true
}

resource "aws_eip_association" "consul_client_1" {
  instance_id   = aws_instance.consul_client_1.id
  allocation_id = aws_eip.consul_client_1.id

  network_interface_id = aws_network_interface.consul_client_1.id
}


resource "aws_instance" "consul_client_1" {
  # ami           = data.aws_ami.ubuntu.id
  ami = "ami-010bb5f550c901adb"
  instance_type = "t3.small"

  associate_public_ip_address = true

  subnet_id = var.subnet_id

  key_name = aws_key_pair.consul.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile(
    "${path.module}/templates/consul_client.tpl",
    {
      id = "1"
      consul_version = "1.8.8",
      enable_consul_server = false,
      datacenter = "aws",
      node_name = "client-1",
      encryption_key = "l+JRvav1izAQcPlrlnkT1LENhaNrlWXVIUAtEnmXdIU="
      public_ip = aws_eip.consul_client_1.public_ip
      aws_function_domain = var.aws_function_domain
      azure_function_domain = var.azure_function_domain
      gcp_function_domain = var.gcp_function_domain


      local_consul_server_ip = aws_eip.consul.public_ip

      client_type = "ingress"
    }
  )

  provisioner "file" {
    source      = "certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }

  provisioner "file" {
    source      = "certs/aws-client-consul-1.pem"
    destination = "/tmp/aws-client-consul-1.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }

  provisioner "file" {
    source      = "certs/aws-client-consul-1-key.pem"
    destination = "/tmp/aws-client-consul-1-key.pem"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host     = self.public_ip
    }
  }
}