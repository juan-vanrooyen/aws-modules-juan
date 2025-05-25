resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = element(var.azs, count.index)
  tags                    = merge(var.tags, { Name = "${var.name}-public-${count.index}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# CloudWatch Log Group for flow logs (if needed)
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" && var.flow_log_cloudwatch_log_group_name == null ? 1 : 0
  name              = "${var.name}-vpc-flow-logs"
  retention_in_days = 30
}

module "flow_logs_bucket" {
  # checkov:skip=CKV_TF_1: Local module, commit hash not applicable
  # checkov:skip=CKV_TF_2: Local module, version pin not applicable
  source      = "../terragrunt/live/modules/s3"
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

resource "aws_default_security_group" "restrict_all" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  tags = merge(var.tags, { Name = "${var.name}-default-sg" })
}
