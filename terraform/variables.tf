variable "region" {
  type        = string
  default     = "us-east-1" # Can be overriden by spec'ing new value in terraform.tfvars (also update main terraform block)
  description = "The AWS region to deploy to"
}

variable "web_assets_bucket" {
  type        = string
  default     = "secure-static-website"
  description = "The name of the website assets S3 bucket"
}

# The below secrets are read from secrets file *.auto.tfvars file (kept out of source control) 
# Ensure you should define this file and add relevant values to it

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