variable "solution_name" {
  description = "The full name of the solution (will be used in some comments)"
  default = "IPCam AI Retrofit"
}

variable "solution_tag" {
  description = "The name tag for the solution (will be used in tags)"
  default = "ipcam_ai_retrofit"
}

variable "notification_email_recipient" {
  description = "E-Mail address to forward notifications to"
}

variable "email_service" {
  description = "E-Mail service to receive inbound e-mails and send notifications (SES=0, SendGrid=1)"
  default = 0
}

variable "ses_domain" {
  description = "The Internet Domain Name for inbound e-mails managed by SES (if enabled)"
}

variable "ses_mail_username" {
  description = "User name part for the SES inbound e-mail address (username@...)"
}

variable "ses_inbound_server" {
  # see: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/regions.html#region-endpoints-receiving
  description = "SES inbound server to add as an MX record value"
  default = "inbound-smtp.__aws_region__.amazonaws.com"
}

variable "log_retention_days" {
  description = "Period of retention of the log info"
  default = 30
}

variable "lambda_log_level" {
  description = "Lambda logger level (in Python format, as string: https://docs.python.org/3/library/logging.html#levels)"
  default = "INFO"
}

variable "rekognition_objects_enabled" {
  description = "Enable or disable object detection with Rekognition"
  default = 1
}

variable "rekognition_objects_alert_on_detected" {
  description = "Determines if objects detected by Rekognition should trigger a notification (value=1) or suppress the alert (value=0)"
  default = 1
}

variable "rekognition_objects_triggers" {
  type = "list"
  description = "Rekognition labels (object types) to search for in an image"
  default = [
    "human",
    "person",
    "people",
    "persons",
    "humans",
    "man",
    "men",
    "woman",
    "women"
  ]
}

variable "rekognition_objects_min_confidence" {
  description = "The minimum confidence threshold for Rekognition to consider an object as detected"
  default = 55
}
