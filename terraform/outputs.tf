output "api_gateway_base_url" {
  value = "${aws_api_gateway_deployment.deployment_production.invoke_url}"
  description = "Base URL for the API Gateway to the Lambda function (use it for SendGrid Webhook configuration)"
}

output "inbound_email_address" {
  value = "${var.email_username}@${var.email_domain}"
  description = "E-Mail address to send detection events from the sources (IP cameras) to"
}

output "notification_email_address" {
  value = "${var.notification_email_recipient}"
  description = "Recipient E-Mail address to notify events that satisfied the filter criteria"
}

output "s3_bucket" {
  value = "${aws_s3_bucket.bucket.bucket}"
  description = "The S3 bucket where incoming messages will be temporarily stored for processing"
}

output "image_objects_triggers" {
  value = "${join(",", var.rekognition_objects_triggers)}"
  description = "Types of objects that will match the filter criteria"
}
