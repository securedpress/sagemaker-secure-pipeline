resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  # no public IP assignment — all jobs run with private IPs only
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix}-private-subnet"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# --- security group ---
# allows HTTPS outbound to VPC endpoints only
# no inbound rules — SageMaker jobs initiate all connections

resource "aws_security_group" "sagemaker" {
  name        = "${var.prefix}-sagemaker-sg"
  description = "SageMaker pipeline jobs — HTTPS to VPC endpoints only"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS to VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "${var.prefix}-sagemaker-sg"
  }
}

# --- S3 gateway endpoint ---
# routes S3 traffic through AWS backbone — no internet egress

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.prefix}-s3-endpoint"
  }
}

# --- SageMaker API interface endpoint ---
# control plane calls never leave the AWS network

resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.sagemaker.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.sagemaker.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.prefix}-sagemaker-api-endpoint"
  }
}

# --- SageMaker runtime interface endpoint ---

resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.sagemaker.runtime"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.sagemaker.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.prefix}-sagemaker-runtime-endpoint"
  }
}

# --- route table ---
# private subnet routes — no 0.0.0.0/0 default route (no internet gateway)

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

data "aws_region" "current" {}
