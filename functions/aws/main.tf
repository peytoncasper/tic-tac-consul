data "archive_file" "function" {
  type        = "zip"
  source_dir = "${path.module}/code"
  output_path = "${path.module}/code.zip"
}

data "aws_subnet_ids" "function" {
  vpc_id = var.vpc_id
}

data "aws_security_groups" "function" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "random_id" "id" {
  byte_length = 8

  keepers = {
    hash = data.archive_file.function.output_md5
  }
}


// TODO: Add IAM Policy AWSLambdaBasicExecutionRole

resource "aws_iam_role_policy" "function" {
  name = "lambda_vpc_access"
  role = aws_iam_role.function.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
  }
  EOF
}


resource "aws_iam_role" "function" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_vpc_endpoint" "function" {
    vpc_id       = var.vpc_id
    service_name = "com.amazonaws.us-east-1.execute-api"

    vpc_endpoint_type   = "Interface"
    private_dns_enabled = true

    subnet_ids = data.aws_subnet_ids.function.ids
    security_group_ids = data.aws_security_groups.function.ids
}

resource "aws_lambda_function" "function" {
  filename      = "${path.module}/code.zip"
  function_name = "main"
  role          = aws_iam_role.function.arn
  handler       = "main.run"

  source_code_hash = data.archive_file.function.output_base64sha256
  runtime = "python3.7"

  timeout = 25

  vpc_config {
      subnet_ids = data.aws_subnet_ids.function.ids
      security_group_ids = data.aws_security_groups.function.ids
  }

  depends_on = [
      data.archive_file.function
  ]
}

resource "aws_api_gateway_rest_api" "function" {
  name = "tic-tac-consul-api"

  endpoint_configuration {
    types = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.function.id]
  }

    policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": "*",
                "Action": "execute-api:Invoke",
                "Resource": [
                    "execute-api:/*"
                ]
            },
            {
                "Effect": "Deny",
                "Principal": "*",
                "Action": "execute-api:Invoke",
                "Resource": [
                    "execute-api:/*"
                ],
                "Condition" : {
                    "StringNotEquals": {
                        "aws:SourceVpce": "${aws_vpc_endpoint.function.id}"
                    }
                }
            }
        ]
    }
    EOF
}

resource "aws_api_gateway_resource" "function" {
  rest_api_id = aws_api_gateway_rest_api.function.id
  parent_id   = aws_api_gateway_rest_api.function.root_resource_id
  path_part   = "run"
}

# Example: request for GET /hello
resource "aws_api_gateway_method" "function" {
  rest_api_id   = aws_api_gateway_rest_api.function.id
  resource_id   = aws_api_gateway_resource.function.id
  http_method   = "POST"
  authorization = "NONE"
}

# Example: GET /hello => POST lambda
resource "aws_api_gateway_integration" "function" {
  rest_api_id = aws_api_gateway_rest_api.function.id
  resource_id = aws_api_gateway_resource.function.id
  http_method = aws_api_gateway_method.function.http_method
  type        = "AWS"
  uri         = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.aws_account_id}:function:${aws_lambda_function.function.function_name}/invocations"

  # AWS lambdas can only be invoked with the POST method
  integration_http_method = "POST"
}

# lambda => GET response
resource "aws_api_gateway_method_response" "function" {
  rest_api_id = aws_api_gateway_rest_api.function.id
  resource_id = aws_api_gateway_resource.function.id
  http_method = aws_api_gateway_integration.function.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Response for: GET /hello
resource "aws_api_gateway_integration_response" "function" {
  rest_api_id = aws_api_gateway_rest_api.function.id
  resource_id = aws_api_gateway_resource.function.id
  http_method = aws_api_gateway_method_response.function.http_method
  status_code = aws_api_gateway_method_response.function.status_code

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  function_name = aws_lambda_function.function.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.aws_account_id}:${aws_api_gateway_rest_api.function.id}/*/${aws_api_gateway_method.function.http_method}${aws_api_gateway_resource.function.path}"
}

resource "aws_api_gateway_deployment" "function" {
  depends_on  = [aws_api_gateway_integration.function]
  rest_api_id = aws_api_gateway_rest_api.function.id
  stage_name  = "dev"
}
