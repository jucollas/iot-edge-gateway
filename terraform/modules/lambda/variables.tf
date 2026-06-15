# Variablespara Lambda module
variable "lab_role_arn" {}

variable "sensors_table_name" {}

variable "sensor_stream_arn" {}


# Variables para PostgreSQL 
variable "sensor_bucket_name" {}

variable "sensor_bucket_arn" {}


variable "postgres_endpoint" {}

variable "postgres_database" {}

variable "postgres_username" {}

variable "postgres_password" {}


# Variables para SQS
variable "queue_url" {}

variable "queue_arn" {}