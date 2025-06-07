# CloudWatch Log Group for flow logs (if needed)
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" && var.flow_log_cloudwatch_log_group_name == null ? 1 : 0
  name              = "${var.name}-vpc-flow-logs"
  retention_in_days = 30
}

module "flow_logs_bucket" {
  # checkov:skip=CKV_TF_1: Local module, commit hash not applicable
  # checkov:skip=CKV_TF_2: Local module, version pin not applicable
  source      = "../s3"
  bucket_name = "${var.name}-vpc-flow-logs"
  tags        = var.tags
}

# IAM Role for VPC Flow Logs (CloudWatch)
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" && var.flow_log_iam_role_arn == null ? 1 : 0
  name  = "${var.name}-vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "flow_logs" {
  count      = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" && var.flow_log_iam_role_arn == null ? 1 : 0
  role       = aws_iam_role.flow_logs[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# VPC Flow Log resource
resource "aws_flow_log" "this" {
  count                = var.enable_flow_logs ? 1 : 0
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = var.flow_log_destination_type
  log_destination = var.flow_log_destination_type == "cloud-watch-logs" ? (
    var.flow_log_cloudwatch_log_group_name != null ? var.flow_log_cloudwatch_log_group_name : aws_cloudwatch_log_group.flow_logs[0].arn
    ) : (
    var.flow_log_s3_bucket_name != null ? var.flow_log_s3_bucket_name : module.flow_logs_bucket.bucket_arn
  )
  iam_role_arn = var.flow_log_destination_type == "cloud-watch-logs" ? (
    var.flow_log_iam_role_arn != null ? var.flow_log_iam_role_arn : aws_iam_role.flow_logs[0].arn
  ) : null
  depends_on = [aws_vpc.this]
}
