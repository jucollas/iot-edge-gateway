output "sensor_table_name" {
  value       = aws_dynamodb_table.sensor_data.name
  description = "Nombre de la tabla DynamoDB para los datos del sensor"
}
#########################
### Tabla de sensores ###
#########################

output "sensors_table_name" {
  value       = aws_dynamodb_table.sensors.name
  description = "Nombre de la tabla DynamoDB para el catálogo de sensores"
}

output "sensor_stream_arn" {
  value       = aws_dynamodb_table.sensor_data.stream_arn
  description = "ARN del DynamoDB Stream de SensorData"
}


output "sensor_data_table_name" {
  value       = aws_dynamodb_table.sensor_data.name
  description = "Nombre de la tabla DynamoDB SensorData"
}

