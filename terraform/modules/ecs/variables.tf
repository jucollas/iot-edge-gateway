variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "ecs_sg_id" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "lab_role_arn" {
  type = string
}

# PostgreSQL

variable "postgres_endpoint" {
  type = string
}

variable "postgres_database" {
  type = string
}

variable "postgres_username" {
  type = string
}

variable "postgres_password" {
  type = string
}

# DynamoDB

variable "sensors_table_name" {
  type = string
}

variable "sensor_data_table_name" {
  type = string
}




variable "target_group_arn" {
  type = string
}