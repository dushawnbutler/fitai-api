data "archive_file" "import_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda-import.zip"
}

resource "aws_cloudwatch_log_group" "import_lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-import"
  retention_in_days = 14
}

resource "aws_lambda_function" "import_dataset" {
  function_name    = "${var.project_name}-${var.environment}-import"
  filename         = data.archive_file.import_lambda.output_path
  source_code_hash = data.archive_file.import_lambda.output_base64sha256
  role             = aws_iam_role.import_lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.13"
  timeout          = 30

  environment {
    variables = {
      DATASET_ARN = awscc_personalize_dataset.workout_interactions.dataset_arn
      ROLE_ARN    = aws_iam_role.personalize_import.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.import_lambda,
    aws_iam_role_policy.lambda_import,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.personalize_s3,
    aws_s3_bucket_policy.data
  ]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowDatasetUploads"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.import_dataset.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data.arn
}

resource "aws_s3_bucket_notification" "dataset_uploads" {
  bucket = aws_s3_bucket.data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.import_dataset.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "datasets/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
