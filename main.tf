provider "azurerm" {
  features {}
}

provider "aws" {
  version = "~> 3.0"
  region  = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "google" {
  project = var.gcp_project_id
  region  = "us-east1"
  credentials = file(var.gcp_credentials_path)
}

module "certs" {
  source = "./certs"
}


resource "azurerm_resource_group" "tic_tac_consul" {
  name     = "tic-tac-consul"
  location = "East US"
}


module "network" {
  source  = "./network"


  depends_on = [
    azurerm_resource_group.tic_tac_consul,
    module.certs
  ]
}

module "functions" {
  source  = "./functions"

  vpc_id = module.network.vpc_id
  aws_account_id = var.aws_account_id
  
  depends_on = [
    module.network
  ]
}

module "azure" {
  source  = "./consul/azure"

  azure_function_domain = module.functions.azure_function_domain
  aws_function_domain = trimsuffix(trimprefix(module.functions.aws_function_domain, "https://"), "/dev")
  gcp_function_domain = trimsuffix(trimprefix(module.functions.gcp_function_domain, "https://"), "tic-tac-consul-function")

  resource_group = azurerm_resource_group.tic_tac_consul.name

  virtual_network_name = module.network.azure_virtual_network_name

  depends_on = [
    # module.network,
    module.functions
  ]
}

module "aws" {
  source  = "./consul/aws"

  vpc_id = module.network.vpc_id
  subnet_id = module.network.consul_subnet_id
  security_group_id = module.network.aws_security_group_id

  bootstrap_ip = module.azure.consul_ip

  azure_function_domain = module.functions.azure_function_domain
  aws_function_domain = trimsuffix(trimprefix(module.functions.aws_function_domain, "https://"), "/dev")
  gcp_function_domain = trimsuffix(trimprefix(module.functions.gcp_function_domain, "https://"), "tic-tac-consul-function")

  depends_on=[module.azure]
  
}

module "gcp" {
  source  = "./consul/gcp"
  bootstrap_ip = module.azure.consul_ip

  azure_function_domain = module.functions.azure_function_domain
  aws_function_domain = trimsuffix(trimprefix(module.functions.aws_function_domain, "https://"), "/dev")
  gcp_function_domain = trimsuffix(trimprefix(module.functions.gcp_function_domain, "https://"), "/tic-tac-consul-function")

  depends_on=[module.azure]
}

