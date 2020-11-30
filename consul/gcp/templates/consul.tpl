#!/usr/bin/env bash

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    unzip 

curl -sL 'https://getenvoy.io/gpg' | sudo apt-key add -

apt-key fingerprint 6FF974DB

sudo add-apt-repository \
    "deb [arch=amd64] https://dl.bintray.com/tetrate/getenvoy-deb \
    $(lsb_release -cs) \
    stable"

sudo apt-get update && sudo apt-get install -y getenvoy-envoy=1.14.4.p0.g923c411-1p67.g2aa564b


curl -s -o consul_${consul_version}_linux_amd64.zip "https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip"

unzip consul_${consul_version}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/

sudo useradd --system --home /etc/consul.d --shell /bin/false consul

sudo mkdir --parents /opt/consul

sudo chown --recursive consul:consul /opt/consul

sudo touch /etc/systemd/system/consul.service

sudo tee -a /etc/systemd/system/consul.service > /dev/null <<EOT
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=exec
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
ExecStop=/usr/local/bin/consul leave
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/consul.hcl
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

sudo mkdir --parents /etc/consul.d/config

while [ ! -f /tmp/consul-agent-ca.pem ] ;
do
      sleep 5
      echo "Waiting for certificates..."
done

sudo mv /tmp/consul-agent-ca.pem /etc/consul.d/consul-agent-ca.pem
sudo mv /tmp/gcp-server-consul-0.pem /etc/consul.d/gcp-server-consul-0.pem
sudo mv /tmp/gcp-server-consul-0-key.pem /etc/consul.d/gcp-server-consul-0-key.pem


# Setup config

sudo tee -a /etc/consul.d/consul.hcl > /dev/null <<EOT
datacenter = "${datacenter}"
server = ${enable_consul_server}
node_name = "${node_name}"
data_dir = "/opt/consul"
encrypt = "${encryption_key}"

primary_datacenter = "azure"

bootstrap_expect = 1

translate_wan_addrs = true

bind_addr = "{{ GetAllInterfaces | include \"name\" \"^ens\" | attr \"address\" }}"
advertise_addr_wan = "${public_ip}"
client_addr = "0.0.0.0"

ui = true

primary_gateways = [ "${bootstrap_ip}:19006" ]

enable_central_service_config = true

connect {
  enabled = true
  enable_mesh_gateway_wan_federation = true
}
ports {
  grpc = 8502
}

ca_file = "/etc/consul.d/consul-agent-ca.pem"
cert_file = "/etc/consul.d/gcp-server-consul-0.pem"
key_file = "/etc/consul.d/gcp-server-consul-0-key.pem"

auto_encrypt {
  allow_tls = true
}
EOT

sudo tee -a /etc/consul.d/config/global-service-defaults.hcl > /dev/null <<EOT
Kind = "service-defaults"
Name = "global"

MeshGateway = {
  Mode = "local"
}
EOT

sudo tee -a /etc/consul.d/config/global-proxy-defaults.hcl > /dev/null <<EOT
Kind = "proxy-defaults"
Name = "global"

MeshGateway = {
  Mode = "local"
}
EOT

sudo tee -a /etc/consul.d/config/gcp-function-defaults.hcl > /dev/null <<EOT
Kind      = "service-defaults"
Name      = "gcp-function"
Protocol  = "http"

MeshGateway = {
  Mode = "local"
}
EOT

sudo tee -a /etc/consul.d/config/gcp-function-resolver.hcl > /dev/null <<EOT
Kind = "service-resolver"
Name = "gcp-function"

Redirect {
  Service    = "gcp-function"
  Datacenter = "gcp"
}
EOT

sudo service consul enable
sudo service consul start

echo "Consul Started."

sleep 15

export PRIVATE_IP=$(ifconfig | grep -A7 --no-group-separator '^ens' | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
export PUBLIC_IP=$(curl https://ipinfo.io/ip)

nohup consul connect envoy -mesh-gateway -register \
    -service "gcp-gateway" \
    -address "$PRIVATE_IP:19006" \
    -wan-address "$PUBLIC_IP:19007"\
    -expose-servers \
    -bind-address=wan_ipv4=0.0.0.0:19007 \
    -bind-address=lan_ipv4=0.0.0.0:19006 \
    -admin-bind 0.0.0.0:19005 & 

echo -e "\nDNS=127.0.0.1\nDomains=~consul" | sudo tee -a /etc/systemd/resolved.conf

sudo service systemd-resolved restart

sudo iptables -t nat -A OUTPUT -d localhost -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600


consul config write /etc/consul.d/config/global-service-defaults.hcl
consul config write /etc/consul.d/config/global-proxy-defaults.hcl
consul config write /etc/consul.d/config/gcp-function-defaults.hcl
consul config write /etc/consul.d/config/gcp-function-resolver.hcl


###
# Setup Web Interface
###

export INGRESS_GATEWAY_IP=$(gcloud compute instances describe gcp-consul-client-0 --zone=us-east1-c --format='get(networkInterfaces[0].networkIP)')

sudo tee -a /tmp/players.json > /dev/null <<EOT
{
  "0": {
      "url": "http://$INGRESS_GATEWAY_IP:8080/api/run",
      "headers": {
          "Host": "${azure_function_domain}"
      }
  },
  "1": {
      "url": "http://$INGRESS_GATEWAY_IP:8080/dev/run",
      "headers": {
          "Host": "${aws_function_domain}"
      }
  },
  "2": {
      "url": "http://$INGRESS_GATEWAY_IP:8080/tic-tac-consul-function/run",
      "headers": {
          "Host": "${gcp_function_domain}"
      }
  }
}

EOT

sudo apt-get install -y python-pip

unzip /tmp/web.zip -d /tmp
pip install -r /tmp/requirements.txt

sed -i -e "s,<meta http-equiv=\"refresh\" content=\"5; URL=http://localhost\">,<meta http-equiv=\"refresh\" content=\"5; URL=http://$PUBLIC_IP\">,g" /tmp/templates/index.jinja2

sudo nohup python /tmp/main.py &

echo "Finsihed!"
