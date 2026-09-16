data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.60.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.60.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-b"
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-rt-a" }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-rt-b" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_a.id,
    aws_route_table.private_b.id
  ]

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group da Lambda Consumer"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Permite PostgreSQL apenas a partir da Lambda Consumer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnets"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.project_name}-postgres"
  engine                  = "postgres"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp3"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0

  tags = {
    Name = "${var.project_name}-postgres"
  }
}

resource "aws_s3_bucket" "input" {
  bucket_prefix = "${var.project_name}-input-"
  force_destroy = true
}

resource "aws_s3_bucket" "output" {
  bucket_prefix = "${var.project_name}-output-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "input" {
  bucket                  = aws_s3_bucket.input.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "output" {
  bucket                  = aws_s3_bucket.output.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-pipeline-dlq"
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-pipeline-queue"
  visibility_timeout_seconds = 360

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "data_access" {
  name = "${var.project_name}-data-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.input.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.input.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.output.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.main.arn
      }
    ]
  })
}

resource "aws_lambda_function" "producer" {
  function_name = "${var.project_name}-producer"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  filename         = "${path.module}/../dist/producer.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/producer.zip")

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.main.url
    }
  }
}

resource "aws_lambda_function" "consumer" {
  function_name = "${var.project_name}-consumer"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  filename         = "${path.module}/../dist/consumer.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/consumer.zip")

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST       = aws_db_instance.postgres.address
      DB_PORT       = tostring(aws_db_instance.postgres.port)
      DB_NAME       = var.db_name
      DB_USER       = var.db_username
      DB_PASSWORD   = var.db_password
      OUTPUT_BUCKET = aws_s3_bucket.output.bucket
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "atividade6-s3-input"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.producer.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.input.arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket_notification" "input_notification" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.producer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "eventos/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_event_source_mapping" "consumer_sqs" {
  event_source_arn        = aws_sqs_queue.main.arn
  function_name           = aws_lambda_function.consumer.arn
  batch_size              = 1
  function_response_types = ["ReportBatchItemFailures"]

  depends_on = [
    aws_iam_role_policy_attachment.lambda_sqs,
    aws_iam_role_policy_attachment.lambda_vpc
  ]
}
