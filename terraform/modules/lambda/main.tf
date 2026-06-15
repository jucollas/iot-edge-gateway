resource "aws_lambda_function" "sensor_catalog_updater" {

  function_name = "sensor-catalog-updater"

  filename         = "${path.root}/lambda/sensor_catalog_updater.zip"
  source_code_hash = filebase64sha256("${path.root}/lambda/sensor_catalog_updater.zip")

  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  role = var.lab_role_arn

  environment {
    variables = {
      SENSORS_TABLE = var.sensors_table_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sensor_stream" {

  event_source_arn = var.sensor_stream_arn

  function_name = aws_lambda_function.sensor_catalog_updater.arn

  starting_position = "LATEST"

  batch_size = 1
}

# Lambda para crear el catálogo de sensores en PostgreSQL
resource "aws_lambda_function" "history_ingestor" {

  function_name = "history-ingestor"

  filename = "${path.root}/lambda/history_ingestor.zip"

  source_code_hash = filebase64sha256(
    "${path.root}/lambda/history_ingestor.zip"
  )

  runtime = "python3.12"

  handler = "history_ingestor.lambda_handler"

  role = var.lab_role_arn

  timeout = 30

  environment {
    variables = {
      DB_HOST     = var.postgres_endpoint
      DB_NAME     = var.postgres_database
      DB_USER     = var.postgres_username
      DB_PASSWORD = var.postgres_password
    }
  }
}


resource "aws_lambda_permission" "allow_s3" {

  statement_id = "AllowExecutionFromS3"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.history_ingestor.function_name

  principal = "s3.amazonaws.com"

  source_arn = var.sensor_bucket_arn
}

resource "aws_s3_bucket_notification" "sensor_upload" {

  bucket = var.sensor_bucket_name

  lambda_function {

    lambda_function_arn = aws_lambda_function.history_ingestor.arn

    events = [
      "s3:ObjectCreated:*"
    ]
  }

  depends_on = [
    aws_lambda_permission.allow_s3
  ]
}



# Lambda que recibe alertas desde IoT Core
resource "aws_lambda_function" "alert_producer" {

  function_name = "alert-producer"

  filename = "${path.root}/lambda/alert_producer.zip"

  source_code_hash = filebase64sha256(
    "${path.root}/lambda/alert_producer.zip"
  )

  runtime = "python3.12"

  handler = "lambda_function.lambda_handler"

  role = var.lab_role_arn

  timeout = 30

  environment {
    variables = {
      QUEUE_URL = var.queue_url
    }
  }
}


# resource "aws_iam_role_policy" "alert_producer_sqs" {

#   name = "alert-producer-sqs"

#   role = replace(var.lab_role_arn, "arn:aws:iam::793805163219:role/", "")

#   policy = jsonencode({
#     Version = "2012-10-17"

#     Statement = [
#       {
#         Effect = "Allow"

#         Action = [
#           "sqs:SendMessage"
#         ]

#         Resource = var.queue_arn
#       }
#     ]
#   })
# }

# Lambda que consume alertas desde SQS y las procesa 
resource "aws_lambda_function" "alert_consumer" {

  function_name = "alert-consumer"

  filename = "${path.root}/lambda/alert_consumer.zip"

  source_code_hash = filebase64sha256(
    "${path.root}/lambda/alert_consumer.zip"
  )

  runtime = "python3.12"

  handler = "lambda_function.lambda_handler"

  role = var.lab_role_arn

  timeout = 30
}

# Mapeo de la cola de alertas a la función Lambda de consumo
resource "aws_lambda_event_source_mapping" "alerts_queue" {

  event_source_arn = var.queue_arn

  function_name = aws_lambda_function.alert_consumer.arn

  batch_size = 1
}