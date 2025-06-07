variable "name" {
  description = "Name for the VPC and resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}

variable "flow_log_destination_type" {
  description = "The type of destination for the flow logs. Valid values: 'cloud-watch-logs', 's3'"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC flow logs (if using CloudWatch)"
  type        = string
  default     = null
}

variable "flow_log_s3_bucket_name" {
  description = "Name of the S3 bucket for VPC flow logs (if using S3)"
  type        = string
  default     = null
}

variable "flow_log_iam_role_arn" {
  description = "IAM Role ARN for VPC flow logs (required for CloudWatch Logs)"
  type        = string
  default     = null
}
