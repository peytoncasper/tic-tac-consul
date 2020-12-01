<h1 align="center">Tic-Tac-Consul</h1>

<p align="center">
    <img align="center" src="docs/tic-tac-consul.png" alt="Screenshot of the Tic Tac Consul Web UI"/>
</p>

# What is this and Why?


# Setup

Given that this is a multi-cloud demo, there is some additional setup required. Namely, we are going to need credentials for all three cloud providers and unfortunately they are all a bit different.

### AWS Credentials

We're going to be leveraging a set of AWS Access Keys and Secret Keys for authentication.

1. Generate the Access Key and Secret Key for your Terraform user

```
aws iam create-access-key --user-name terraform
```

2. Fetch your AWS Account ID

```
aws sts get-caller-identity --query Account --output text
```

3. Copy the terraform.tfvars.template file to terraform.tfvars

```
cp terraform.tfvars.template terraform.tfvars
```

4. Set the TF variables respectively in the terraform.tfvars file

```
aws_access_key="..."
aws_secret_key="..."
aws_account_id="..."
...
```

### GCP Credentials

For GCP we're going to leverage a Service Account key.

1. Generate Service Account key and save it to the credentials folder 

```
gcloud iam service-accounts keys create  --iam-account [SERVICE_ACCOUNT_EMAIL_ADDRESS_GOES_HERE] credentials/creds.json
```

2. Get your GCP Project ID

```
gcloud config get-value project
```

3. Set the TF variables respectively in the terraform.tfvars file

```
...
gcp_project_id="..."
gcp_credentials_path="credentials/creds.json"
```

### Azure Credentials

Currently Azure credentials are based off the Azure CLI authentication method. As a result, you simply need to be authenticated with `az`

### Terraform Apply

Run Terraform Apply and let it configure the necessary resources.

```
terraform apply
```