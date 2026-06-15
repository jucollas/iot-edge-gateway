resource "aws_sqs_queue" "alerts" {
  name = "sensor-alerts"
}