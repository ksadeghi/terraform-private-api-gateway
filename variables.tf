
# Variables for the private API Gateway Lambda setup

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "my-private-lambda"
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "private-lambda-api"
}

variable "stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "prod"
}

variable "vpc_id" {
  description = "VPC ID where the private endpoint will be created"
  type        = string
  # This must be provided when running terraform
}

variable "subnet_ids" {
  description = "List of subnet IDs for the VPC endpoint (should be private subnets)"
  type        = list(string)
  # This must be provided when running terraform
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the private API through the VPC endpoint"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.9"
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 128
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "private-lambda-api"
    ManagedBy   = "terraform"
  }
}
