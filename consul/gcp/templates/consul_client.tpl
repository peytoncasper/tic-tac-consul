#!/usr/bin/env bash

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    unzip 

sudo apt update
sudo apt install apt-transport-https gnupg2 curl lsb-release
curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/getenvoy.list
sudo apt update
sudo apt-get install -y getenvoy-envoy=1.14.5.p0.gfa0371e-1p69.ga5345f6



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
sudo mv /tmp/gcp-client-consul-${id}.pem /etc/consul.d/gcp-client-consul-${id}.pem
sudo mv /tmp/gcp-client-consul-${id}-key.pem /etc/consul.d/gcp-client-consul-${id}-key.pem

# Setup config

sudo tee -a /etc/consul.d/consul.hcl > /dev/null <<EOT
datacenter = "${datacenter}"
server = ${enable_consul_server}
node_name = "${node_name}"
data_dir = "/opt/consul"
encrypt = "${encryption_key}"
bootstrap = false

primary_datacenter = "azure"

translate_wan_addrs = true

retry_join = [ "${local_consul_server_ip}" ]

bind_addr = "{{ GetAllInterfaces | include \"name\" \"^ens\" | attr \"address\" }}"
advertise_addr_wan = "${public_ip}"
client_addr = "0.0.0.0"

ui = true

enable_central_service_config = true

connect {
  enabled = true
}
ports {
  grpc = 8502
}

ca_file = "/etc/consul.d/consul-agent-ca.pem"
cert_file = "/etc/consul.d/gcp-client-consul-${id}.pem"
key_file = "/etc/consul.d/gcp-client-consul-${id}-key.pem"

EOT

sudo service consul enable
sudo service consul start

echo "Consul Started."


# Wait for Consul to Start
until $(curl --output /dev/null --silent --head --fail http://localhost:8500); do
    printf '.'
    sleep 5
done

# Wait for the Cluster to finish connecting

sleep 360

export PRIVATE_IP=$(ifconfig | grep -A7 --no-group-separator '^ens' | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
export PUBLIC_IP=$(curl https://ipinfo.io/ip)

echo -e "\nDNS=127.0.0.1\nDomains=~consul" | sudo tee -a /etc/systemd/resolved.conf

sudo service systemd-resolved restart

sudo iptables -t nat -A OUTPUT -d localhost -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600

if [[ ${client_type} == "ingress" ]]
then
sudo tee -a /etc/consul.d/config/gcp-function-ingress.hcl > /dev/null <<EOT
Kind = "ingress-gateway"
Name = "gcp-ingress-gateway"

Listeners = [
{
  Port = 8080
  Protocol = "http"
  Services = [
    {
      Name = "aws-function"
      Hosts = ["${aws_function_domain}"]
    },{
      Name = "azure-function"
      Hosts = ["${azure_function_domain}"]
    },{
      Name = "gcp-function"
      Hosts = ["${gcp_function_domain}"]
    }
  ]
}
]
EOT

sleep 10

consul config write /etc/consul.d/config/gcp-function-ingress.hcl

sudo nohup consul connect envoy -gateway=ingress -register -service gcp-ingress-gateway -admin-bind "127.0.0.1:19200" -address "$PRIVATE_IP:19201" &
else

sudo tee -a /etc/consul.d/config/gcp-function-terminating.json > /dev/null <<EOT
{
  "Node": "gcp_function_node",
  "Address": "${gcp_function_domain}",
  "NodeMeta": {
    "external-node": "true",
    "external-probe": "true"
  },
  "Service": {
    "ID": "gcp-function-id",
    "Service": "gcp-function",
    "Port": 443
  }, 
  "Checks": [
    {
      "Name": "http-check",
      "status": "passing",
      "Definition": {
        "http": "https://${gcp_function_domain}/tic-tac-consul-function/run",
        "interval": "30s"
      }
    }
  ]
}
EOT

sudo tee -a /etc/consul.d/config/gcp-terminating-gateway.hcl > /dev/null <<EOT
Kind = "terminating-gateway"
Name = "gcp-terminating-gateway"
Services = [
{
  Name = "gcp-function"
  CAFile = "/etc/ssl/certs/ca-certificates.crt"
}
]
EOT

sleep 10

curl --request PUT --data @/etc/consul.d/config/gcp-function-terminating.json localhost:8500/v1/catalog/register
consul config write /etc/consul.d/config/gcp-terminating-gateway.hcl

sudo nohup consul connect envoy -gateway=terminating -register -service gcp-terminating-gateway -admin-bind "127.0.0.1:19200" -address "$PRIVATE_IP:19201" &
fi


