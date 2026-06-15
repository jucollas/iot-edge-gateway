resource "aws_dynamodb_table" "sensor_data" {
  # Añadimos el sufijo del entorno para evitar conflictos si hay varios ambientes
  name         = "SensorData-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  # Al tener SOLO un Partition Key (hash_key) y NO tener Sort Key (range_key),
  # cada vez que llegue un evento con el mismo sensor_id, DynamoDB
  # simplemente sobrescribirá el registro existente. ¡Perfecto para "Hot Data"!
  hash_key = "sensor_id"

  # Si quisiéramos almacenar un historial completo de eventos por dispositivo, podríamos agregar 
  # un Sort Key (range_key) basado en la marca de tiempo
  range_key = "timestamp"

  # Permite reaccionar automáticamente cuando llegan nuevas mediciones de sensores
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "sensor_id"
    type = "S"
  }

  # Sort key 
  attribute {
    name = "timestamp"
    type = "S"
  }


  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

##############################################################################
### Agregar una tabla adicional para almacenar información de los sensores ###
##############################################################################
resource "aws_dynamodb_table" "sensors" {
  name         = "Sensors-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "sensor_id"

  attribute {
    name = "sensor_id"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}