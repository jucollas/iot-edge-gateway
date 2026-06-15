variable "project_name" { type = string }
variable "environment" { type = string }
variable "lab_role_arn" { type = string }
variable "account_id" { type = string }
variable "region" { type = string }
variable "iot_endpoint" { type = string }
variable "root_ca_pem" { type = string }
variable "sensor_bucket_name" { type = string }
variable "sensor_table_name" { type = string }

variable "alert_lambda_arn" {}

