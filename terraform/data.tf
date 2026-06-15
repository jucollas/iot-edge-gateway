# Obtener información de la cuenta de AWS (ID, ARN)
data "aws_caller_identity" "current" {}

# Obtener la región actual
data "aws_region" "current" {}

# Obtener el LabRole preexistente del AWS Learner Lab
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Obtenemos el endpoint de IoT Core de la cuenta actual
data "aws_iot_endpoint" "iot_endpoint" {
  endpoint_type = "iot:Data-ATS"
}

# Descargar el Root CA de AWS para inyectarlo luego a los módulos
data "http" "root_ca" {
  url = "https://www.amazontrust.com/repository/AmazonRootCA1.pem"
}
