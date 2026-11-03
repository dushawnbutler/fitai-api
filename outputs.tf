output "https_api_url" {
  description = "API Gateway HTTPS endpoint; workout routes require IAM"
  value       = trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")
}

output "instance_id" {
  description = "Use this ID with Systems Manager Session Manager."
  value       = aws_instance.app_server.id
}

output "database_endpoint" {
  value = aws_db_instance.fitness_db.address
}

output "s3_bucket_name" {
  value = aws_s3_bucket.data.id
}

output "personalize_dataset_arn" {
  value = awscc_personalize_dataset.workout_interactions.dataset_arn
}

output "personalize_import_role_arn" {
  value = aws_iam_role.personalize_import.arn
}
