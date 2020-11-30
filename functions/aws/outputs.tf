output "aws_function_domain" {
    value = "${aws_api_gateway_rest_api.function.id}-${aws_vpc_endpoint.function.id}.execute-api.${var.region}.amazonaws.com"
}