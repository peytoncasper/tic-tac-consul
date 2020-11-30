resource "aws_vpc" "consul" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "consul" {
  vpc_id     = aws_vpc.consul.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-east-1a"
}

resource "aws_subnet" "function" {
  vpc_id     = aws_vpc.consul.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "us-east-1b"
}

resource "aws_security_group" "consul" {
  name        = "consul"
  description = "Allow Consul Traffic"
  vpc_id      = aws_vpc.consul.id

  ingress {
    description = "Inbound TCP"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Inbound UDP"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_internet_gateway" "consul" {
  vpc_id = aws_vpc.consul.id
}

resource "aws_route_table" "consul" {
  vpc_id = aws_vpc.consul.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.consul.id
  }
}

resource "aws_route_table_association" "consul" {
  subnet_id      = aws_subnet.consul.id
  route_table_id = aws_route_table.consul.id
}

resource "aws_route_table_association" "function" {
  subnet_id      = aws_subnet.function.id
  route_table_id = aws_route_table.consul.id
}