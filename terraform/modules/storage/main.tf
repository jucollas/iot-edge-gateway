resource "random_id" "id" {
  byte_length = 4
}

resource "aws_s3_bucket" "sensor_data" {
  bucket        = "${var.environment}-${var.project_name}-sensor-data-${random_id.id.hex}"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.environment}-${var.project_name}-athena-results-${random_id.id.hex}"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
