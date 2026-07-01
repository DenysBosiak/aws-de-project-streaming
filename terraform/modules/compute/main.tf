resource "aws_kinesis_stream" "events" {
    name = "ecommerce-events-${var.env}"
    shard_count = var.env == "prod" ? 4 : 2
    retention_period = 24
}

data "archive_file" "lambda_zip" {
    type = "zip"
    source_dir = "${path.root}/../lambda"
    output_path = "${path.root}/../lambda/lambda_p1.zip"
}

resource "aws_lambda_function" "processor" {
    function_name = "p1-linesis-processor-${var.env}"
    role = var.lambda_role_arn
    handler = "handler.lambda_handler"
    runtime = "python3.11"
    filename = data.archive_file.lambda_zip.output_path
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    timeout = 60
    memory_size = 254
    environment {
        variables = {
            REDSHIFT_WORKGROUP = "analytics-wg-${var.env}"
            DB_NAME = "ecommerce_dwh"
        }
    }
}

resource "aws_sqs_queue" "dlq" {
    name = "p1-lambda-dlq-${var.env}"
    message_retention_seconds = 604800
}

resource "aws_lambda_event_source_mapping" "kinesis" {
    event_source_arn               = aws_kinesis_stream.events.arn
    function_name                  = aws_lambda_function.processor.arn
    starting_position              = "LATEST"
    batch_size                     = 100
    bisect_batch_on_function_error = true
    destination_config {
        on_failure { destination_arn = aws_sqs_queue.dlq.arn }
    }
}

resource "aws_kinesis_firehose_delivery_stream" "raw" {
    name = "p1-events-firehose-${var.env}"
    destination = "extended_s3"
    kinesis_source_configuration {
        kinesis_stream_arn = aws_kinesis_stream.events.arn
        role_arn = var.firehose_role_arn
    }
    extended_s3_configuration {
        role_arn = var.firehose_role_arn
        bucket_arn = "arn:aws:s3:::${var.raw_bucket_id}"
        prefix = "events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
        error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"
        buffering_size = 128
        buffering_interval = 300
        compression_format = "GZIP"
    }
}

resource "aws_apigatewayv2_api" "events" {
    name = "p1-events-api-${var.env}"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
    api_id = aws_apigatewayv2_api.events.id
    name = "$default"
    auto_deploy = true
}