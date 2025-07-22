# Sensitive values should ideally be spec'd via
# - secrets.auto.tfvars file for sensitive values like s3 web assets bucket name 
#       (Create that file + add it to gitignore if deploying the terraform config locally using CLI)
# - terraform.tfvars for non-sensitive values
# If spec'ing different region value in terraform.tfvars also update main.tf terraform block

variable "region" {
  type        = string
  default     = "eu-west-1" # Default (fallback) region.
  description = "The AWS region to deploy to"
}

variable "web_assets_bucket" {
  type        = string
  description = "The name of the website assets S3 bucket"
}

variable "hosted_zone" {
  type        = string
  description = "The name your AWS Route 53 hosted zone"
}

variable "domain_name" {
  type        = string
  description = "Your domain name"
}

variable "url_prefix" {
  type        = string
  default     = "simple-website"
  description = "Your domain name"
}