terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Módulo de Almacenamiento (S3)
module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  environment  = var.environment
}

# Módulo de Base de Datos (DynamoDB)
module "database" {
  source       = "./modules/database"
  project_name = var.project_name
  environment  = var.environment
}

# Módulo de IoT Core
module "iot" {
  source       = "./modules/iot"
  project_name = var.project_name
  environment  = var.environment

  # Variables inyectadas desde data sources globales
  lab_role_arn = data.aws_iam_role.lab_role.arn
  account_id   = data.aws_caller_identity.current.account_id
  region       = data.aws_region.current.name

  # iot_endpoint: Es la URL única (Endpoint ATS) asignada por AWS a tu cuenta y región para IoT Core.
  # Es indispensable inyectarla a Mosquitto (en su archivo mosquitto.conf) para que el Bridge sepa 
  # exactamente a qué dirección de servidor de Amazon debe conectarse y enviar los mensajes MQTT.
  iot_endpoint = data.aws_iot_endpoint.iot_endpoint.endpoint_address
  root_ca_pem  = data.http.root_ca.response_body

  # Variables inyectadas desde outputs de otros módulos
  sensor_bucket_name = module.storage.sensor_bucket_name
  sensor_table_name  = module.database.sensor_table_name

  # ARN de la función Lambda que se encargará de procesar los mensajes MQTT y actualizar el catálogo de sensores en DynamoDB.
  alert_lambda_arn = module.lambda.alert_producer_arn

}


# Modulo de Lambda para actualizar el catálogo de sensores
module "lambda" {

  source = "./modules/lambda"

  lab_role_arn = data.aws_iam_role.lab_role.arn

  sensors_table_name = module.database.sensors_table_name
  sensor_stream_arn  = module.database.sensor_stream_arn

  sensor_bucket_name = module.storage.sensor_bucket_name
  sensor_bucket_arn  = module.storage.sensor_bucket_arn


  postgres_endpoint = module.postgres.endpoint
  postgres_database = module.postgres.database_name
  postgres_username = module.postgres.username

  postgres_password = "Password123!"

  queue_url = module.sqs.queue_url
  queue_arn = module.sqs.queue_arn

}

# Módulo de RDS para PostgreSQL
module "postgres" {
  source = "./modules/postgres"

  subnet_a = "subnet-005fc6abf08047dc3"
  subnet_b = "subnet-0ecaa869547b671d2"

  db_password = "Password123!"
}


# Módulo de ECS para desplegar la API y el Worker
module "ecs" {

  source = "./modules/ecs"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.subnet_ids
  ecs_sg_id          = module.networking.ecs_sg_id
  target_group_arn   = module.networking.target_group_arn
  ecr_repository_url = module.ecr.repository_url

  lab_role_arn = data.aws_iam_role.lab_role.arn

  postgres_endpoint = module.postgres.endpoint
  postgres_database = module.postgres.database_name
  postgres_username = module.postgres.username
  postgres_password = "Password123!"

  sensors_table_name     = module.database.sensors_table_name
  sensor_data_table_name = module.database.sensor_data_table_name
}


# Módulo de Networking (VPC, Subnets, Security Groups)
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
}

# Módulo de ECR para almacenar las imágenes de Docker
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  environment  = var.environment
}



# Módulo de SQS para gestionar las colas de mensajes
module "sqs" {
  source = "./modules/sqs"
}