module "azure" {
    source = "./azure"
}

module "aws" {
    source = "./aws"
    vpc_id = var.vpc_id
    aws_account_id = var.aws_account_id
}

module "gcp" {
    source = "./gcp"
}