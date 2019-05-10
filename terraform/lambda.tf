# Install dependencies for local tasks and development
resource "null_resource" "install_dependencies" {
  triggers {
    # To force the refresh of packages at every run,
    # uncomment the following line
    # uuid = "${uuid()}"
    requirements_dev = "${base64sha256(file("../lambda/requirements-dev.txt"))}"
  }

  provisioner "local-exec" {
    working_dir = "../lambda/"
    command = "pip install -r requirements-dev.txt"
  }
}

# Install dependencies for the Lambda function and prepare the bundle
resource "null_resource" "prepare_release" {
  triggers {
    # To force the repackaging at every run,
    # uncomment the following line
    # uuid = "${uuid()}"
    main         = "${base64sha256(file("../lambda/main.py"))}"
    requirements = "${base64sha256(file("../lambda/requirements.txt"))}"
  }

  provisioner "local-exec" {
    working_dir = "../lambda/"
    command     = "shovel package nozip"
  }

  depends_on = ["null_resource.install_dependencies"]
}

# Package the code and dependencies bundle
data "archive_file" "lambda_release" {
  type        = "zip"
  source_dir  = "${path.module}/../.deploy"
  output_path = "${path.module}/../.deploy.zip"

  depends_on = ["null_resource.prepare_release"]
}

# Define the AssumeRole policy document
data "aws_iam_policy_document" "assume_lambda_role_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Create a Role for the Lambda function
resource "aws_iam_role" "iam_role_for_lambda" {
  name = "${var.solution_tag}_lambda_exec_role"
  description = "AssumeRole and Execution permissions for the ${var.solution_name} Lambda function"
  assume_role_policy = "${data.aws_iam_policy_document.assume_lambda_role_doc.json}"

  tags = {
    Name = "${var.solution_tag}"
  }
}

# Define a Policy document for the Lambda function
data "aws_iam_policy_document" "lambda_role_doc" {

  # Allow Lambda to create logging group and write logs to the group
  statement {
    sid = "AllowLogging"

    actions = [
      # "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    sid = "AllowS3RW"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }

  statement {
    sid = "AllowS3R"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}",
    ]
  }

  statement {
    sid = "AllowRekognitionUse"

    actions = [
      "rekognition:CompareFaces",
      "rekognition:DetectFaces",
      "rekognition:DetectLabels",
      "rekognition:ListCollections",
      "rekognition:ListFaces",
      "rekognition:SearchFaces",
      "rekognition:SearchFacesByImage"
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowSESSendMail"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]

    # See: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/control-user-access.html
    resources = ["*"]
  }
}

# Create a Policy for the Lambda function
resource "aws_iam_policy" "iam_policy_for_lambda" {
  name = "${var.solution_tag}_lambda_role"
  path = "/"
  description = "IAM policy for lambda function of ${var.solution_name}"

  policy = "${data.aws_iam_policy_document.lambda_role_doc.json}"
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "iam_role_for_lambda" {
  role = "${aws_iam_role.iam_role_for_lambda.name}"
  policy_arn = "${aws_iam_policy.iam_policy_for_lambda.arn}"
}

# Create the Lambda function
resource "aws_lambda_function" "lambda" {
  filename         = "${path.module}/../.deploy.zip"
  function_name    = "${var.solution_tag}_processor"
  description      = "${var.solution_name} Lambda function to process incoming messages"
  role             = "${aws_iam_role.iam_role_for_lambda.arn}"
  handler          = "main.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_release.output_base64sha256}"
  runtime          = "python3.7"
  memory_size      = "${var.lambda_memory}"
  timeout          = "${var.lambda_timeout}"

  environment {
    variables = {
      LOG_LEVEL = "${var.lambda_log_level}",
      BUCKET_NAME = "${aws_s3_bucket.bucket.bucket}",
      NOTIFICATION_RECIPIENT = "${var.notification_email_recipient}",
      SENDER_ADDRESS = "${var.email_username}@${var.email_domain}",
      REKOGNITION_OBJECTS_ENABLED = "${var.rekognition_objects_enabled}",
      REKOGNITION_OBJECTS_ALERT_ON_DETECTED = "${var.rekognition_objects_alert_on_detected}",
      REKOGNITION_OBJECTS_TRIGGERS = "${join(",", var.rekognition_objects_triggers)}",
      REKOGNITION_OBJECTS_MIN_CONFIDENCE = "${var.rekognition_objects_min_confidence}"
    }
  }

  lifecycle {
    ignore_changes = ["source_code_hash"]
  }

  tags = {
    Name = "${var.solution_tag}"
  }

  depends_on = ["aws_s3_bucket.bucket"]
}

# Create the Log Group for the Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = "${var.log_retention_days}"
}

# Give API Gateway permission to invoke the function
resource "aws_lambda_permission" "lambda_permission_api_gateway" {
  statement_id   = "AllowExecutionFromAPIGateway"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.lambda.function_name}"
  principal      = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_deployment.deployment_production.execution_arn}/*/*"
}

# Give SES permission to invoke the function
resource "aws_lambda_permission" "lambda_permission_ses" {
  statement_id   = "AllowExecutionFromSES"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.lambda.function_name}"
  principal      = "ses.amazonaws.com"
  source_account = "${data.aws_caller_identity.current.account_id}"
}
