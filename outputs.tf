################################################################################
# API Gateway Outputs (REST)
################################################################################

output "api_id" {
  description = "The ID of the REST API"
  value       = try(aws_api_gateway_rest_api._[0].id, null)
}

output "api_arn" {
  description = "The ARN of the REST API"
  value       = try(aws_api_gateway_rest_api._[0].arn, null)
}

output "api_execution_arn" {
  description = "The execution ARN to use in Lambda permissions (source_arn)"
  value       = try(aws_api_gateway_rest_api._[0].execution_arn, null)
}

output "api_root_resource_id" {
  description = "The root resource ID of the REST API"
  value       = try(aws_api_gateway_rest_api._[0].root_resource_id, null)
}
