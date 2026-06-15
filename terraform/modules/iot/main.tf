# Creación del Thing (Dispositivo Edge Gateway)
resource "aws_iot_thing" "edge_gateway" {
  name = "edge-gateway-01-${var.environment}"
}

# Creación de los certificados
resource "aws_iot_certificate" "cert" {
  active = true
}

# Creación de la política de IoT
resource "aws_iot_policy" "sensor_policy" {
  name = "EdgeGatewayPolicy-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Statement 1 (Connect): Permite al dispositivo establecer una conexión MQTT con AWS IoT Core.
      # Seguridad: Se restringe el recurso a un 'client' específico. Esto asegura que nadie más pueda 
      # conectarse a AWS IoT usando estos certificados si intenta usar un Client ID diferente.
      {
        Action   = ["iot:Connect"]
        Effect   = "Allow"
        Resource = ["arn:aws:iot:${var.region}:${var.account_id}:client/${aws_iot_thing.edge_gateway.name}"]
      },

      # Statement 2 (Publish / Receive): Permite al dispositivo enviar (Publish) datos a AWS IoT Core 
      # y recibir (Receive) mensajes que le lleguen a través de tópicos específicos.
      # Seguridad: Solo puede interactuar con la jerarquía de tópicos 'lab/sensors/*'
      {
        Action   = ["iot:Publish", "iot:Receive"]
        Effect   = "Allow"
        Resource = ["arn:aws:iot:${var.region}:${var.account_id}:topic/lab/sensors/*"]
      },

      # Statement 3 (Subscribe): Permite al dispositivo solicitar la suscripción a un tópico MQTT.
      # Seguridad: Utiliza el recurso 'topicfilter' (que permite comodines de MQTT como # y +).
      # Esto autoriza al Edge Gateway a suscribirse para escuchar cualquier sub-tópico de 'lab/sensors/'.
      {
        Action   = ["iot:Subscribe"]
        Effect   = "Allow"
        Resource = ["arn:aws:iot:${var.region}:${var.account_id}:topicfilter/lab/sensors/*"]
      }
    ]
  })
}

# Adjuntar política al certificado
# Relaciona la política de seguridad (permisos) creada arriba con el certificado X.509.
# Sin esto, el certificado sería válido criptográficamente pero no tendría autorización para hacer nada en AWS.
resource "aws_iot_policy_attachment" "att" {
  policy = aws_iot_policy.sensor_policy.name
  target = aws_iot_certificate.cert.arn
}

# Adjuntar certificado al Thing
# Relaciona el certificado X.509 con el "Thing" (la representación virtual de nuestro Edge Gateway).
# Esto completa la cadena de identidad lógica: Dispositivo Físico <-> Certificado <-> Política de Permisos.
resource "aws_iot_thing_principal_attachment" "att" {
  principal = aws_iot_certificate.cert.arn
  thing     = aws_iot_thing.edge_gateway.name
}

# Escribir los certificados generados al disco local (Edge Gateway)
# Extrae el contenido PEM del certificado y lo guarda como archivo para que Mosquitto lo pueda leer.
resource "local_file" "certificate_pem" {
  content  = aws_iot_certificate.cert.certificate_pem
  filename = "${path.root}/../edge_gateway/certs/certificate.pem.crt"
}

# Extrae la clave privada generada por AWS y la guarda localmente (¡este archivo es secreto!).
resource "local_file" "private_key" {
  content  = aws_iot_certificate.cert.private_key
  filename = "${path.root}/../edge_gateway/certs/private.pem.key"
}

# Extrae la clave pública y la guarda en un archivo local.
resource "local_file" "public_key" {
  content  = aws_iot_certificate.cert.public_key
  filename = "${path.root}/../edge_gateway/certs/public.pem.key"
}

# Guarda el certificado raíz de Amazon (Root CA) necesario para que Mosquitto verifique la identidad del servidor de AWS.
resource "local_file" "root_ca" {
  content  = var.root_ca_pem
  filename = "${path.root}/../edge_gateway/certs/AmazonRootCA1.pem"
}

# Generar mosquitto.conf automáticamente inyectando el endpoint de AWS
# Crea el archivo de configuración del broker local Mosquitto. Se usa un bloque heredoc (<<-EOT)
# para definir el texto e interpolar dinámicamente el Endpoint ATS de AWS y el nombre del Thing.
resource "local_file" "mosquitto_conf" {
  content  = <<-EOT
# Configuración del servidor local Mosquitto
listener 1883 0.0.0.0
allow_anonymous true

# Configuración del Bridge hacia AWS IoT Core
connection awsiot
address ${var.iot_endpoint}:8883

# Mapeo de tópicos: local -> remoto
topic lab/sensors/data out 1 "" ""

bridge_protocol_version mqttv311
bridge_insecure false

cleansession true
clientid ${aws_iot_thing.edge_gateway.name}
start_type automatic
notifications false
keepalive_interval 60

# Certificados TLS para la conexión con AWS
bridge_cafile /mosquitto/certs/AmazonRootCA1.pem
bridge_certfile /mosquitto/certs/certificate.pem.crt
bridge_keyfile /mosquitto/certs/private.pem.key
EOT
  filename = "${path.root}/../edge_gateway/mosquitto.conf"
}

# === REGLAS IOT ===

# Regla de DynamoDB:
# Actúa como un suscriptor interno en AWS IoT Core. Escucha todo lo que llega a 'lab/sensors/data'
# (vía la sentencia SQL) y ejecuta la acción "dynamodbv2", la cual inserta o actualiza 
# el ítem en la tabla de DynamoDB usando el LabRole para tener permisos de escritura.
resource "aws_iot_topic_rule" "dynamodb_rule" {
  name        = "SensorDataToDynamoDB_${var.environment}"
  description = "Guarda los eventos de sensores en DynamoDB"
  enabled     = true
  sql         = "SELECT * FROM 'lab/sensors/data'"
  sql_version = "2016-03-23"

  dynamodbv2 {
    role_arn = var.lab_role_arn
    put_item {
      table_name = var.sensor_table_name
    }
  }
}

# Regla de S3:
# De forma paralela a la regla anterior, intercepta los mismos mensajes de 'lab/sensors/data'.
# En lugar de base de datos, ejecuta la acción "s3", guardando el payload como un archivo JSON.
# La llave (key) usa funciones de interpolación internas de AWS IoT ($${parse_time...}) para organizar los archivos 
# en carpetas particionadas por año/mes/día directamente, optimizando futuras consultas analíticas (Athena).
resource "aws_iot_topic_rule" "s3_rule" {
  name        = "SensorDataToS3_${var.environment}"
  description = "Guarda los eventos de sensores en S3 particionados por fecha"
  enabled     = true
  sql         = "SELECT * FROM 'lab/sensors/data'"
  sql_version = "2016-03-23"

  s3 {
    bucket_name = var.sensor_bucket_name
    key         = "data/year=$${parse_time(\"yyyy\", timestamp())}/month=$${parse_time(\"MM\", timestamp())}/day=$${parse_time(\"dd\", timestamp())}/$${topic(3)}_$${newuuid()}.json"
    role_arn    = var.lab_role_arn
  }
}


# Regla de alerta por temperatura alta
resource "aws_iot_topic_rule" "temperature_alert_rule" {

  name = "TemperatureAlertRule_${var.environment}"

  description = "Dispara Lambda cuando la temperatura supera 35"

  enabled = true

  sql = "SELECT * FROM 'lab/sensors/data' WHERE sensor_type = 'temperature' AND value > 35"

  sql_version = "2016-03-23"

  lambda {
    function_arn = var.alert_lambda_arn
  }
}


resource "aws_lambda_permission" "allow_iot_alerts" {

  statement_id = "AllowIoTInvokeAlertProducer"

  action = "lambda:InvokeFunction"

  function_name = var.alert_lambda_arn

  principal = "iot.amazonaws.com"
}