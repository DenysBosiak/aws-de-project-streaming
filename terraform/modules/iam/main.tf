resource "aws_iam_role" "lambda_exec" {
  name = "p1-lambda-exec-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "p1-lambda-policy-${var.env}"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "redshift-serverless:GetCredentials",
        ]
        Effect   = "Allow"
        Resource = "*"
      },      
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },      
      {
        Action = [
          "sqs:SendMessage"
        ]
        Effect   = "Allow"
        Resource = "*"
      }  
    ]
  })
}

resource "aws_iam_role" "firehose" {
  name = "p1-firehose-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "p1-firehose-policy-${var.env}"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = ["${var.raw_bucket_arn}", "${var.raw_bucket_arn}/*"]
      },
      {
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}