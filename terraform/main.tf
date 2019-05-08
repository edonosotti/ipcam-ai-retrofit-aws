provider "aws" {}

data "aws_caller_identity" "current" {}

# =====================================
# UNCOMMENT and CHANGE VARIABLES to
# your preferred settings to
# ENABLE REMOTE TERRAFORM STATE storage
# =====================================
# terraform {
#   backend "s3" {
#     encrypt = true
#     bucket = "ipcam-ai-retrofit"
#     dynamodb_table = "ipcam-ai-retrofit"
#     region = "eu-west-1"
#     key = "ipcam-ai-retrofit.tfstate"
#   }
# }
