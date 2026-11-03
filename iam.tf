data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.project_name}-${var.environment}-app"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "app" {
  statement {
    sid       = "ReadDatabaseSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.fitness_db.master_user_secret[0].secret_arn]
  }

  statement {
    sid       = "ReadWriteWorkoutMedia"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.data.arn}/media/*"]
  }
}

resource "aws_iam_role_policy" "app" {
  name   = "${var.project_name}-app-access"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-${var.environment}-profile"
  role = aws_iam_role.app.name
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "import_lambda" {
  name               = "${var.project_name}-${var.environment}-import-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.import_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_import" {
  statement {
    sid       = "CreateImportJobs"
    actions   = ["personalize:CreateDatasetImportJob"]
    resources = ["*"]
  }

  statement {
    sid       = "PassOnlyPersonalizeImportRole"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.personalize_import.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["personalize.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lambda_import" {
  name   = "${var.project_name}-create-import"
  role   = aws_iam_role.import_lambda.id
  policy = data.aws_iam_policy_document.lambda_import.json
}

data "aws_iam_policy_document" "personalize_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["personalize.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "personalize_import" {
  name               = "${var.project_name}-${var.environment}-personalize-import"
  assume_role_policy = data.aws_iam_policy_document.personalize_assume.json
}

data "aws_iam_policy_document" "personalize_s3" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.data.arn]
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.data.arn}/datasets/*"]
  }
}

resource "aws_iam_role_policy" "personalize_s3" {
  name   = "${var.project_name}-read-datasets"
  role   = aws_iam_role.personalize_import.id
  policy = data.aws_iam_policy_document.personalize_s3.json
}
