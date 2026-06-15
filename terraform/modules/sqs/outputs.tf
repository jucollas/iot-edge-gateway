output "queue_url" {
  value = aws_sqs_queue.alerts.id
}

output "queue_arn" {
  value = aws_sqs_queue.alerts.arn
}

