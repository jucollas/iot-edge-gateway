output "endpoint" {
  value = aws_db_instance.postgres.address
}

output "database_name" {
  value = aws_db_instance.postgres.db_name
}

output "port" {
  value = aws_db_instance.postgres.port
}

output "username" {
  value = aws_db_instance.postgres.username
}