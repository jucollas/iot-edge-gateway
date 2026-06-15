output "iot_endpoint" {
  description = "El endpoint de AWS IoT Core"
  value       = data.aws_iot_endpoint.iot_endpoint.endpoint_address
}


output "ecr_repository_url" {
  value = module.ecr.repository_url
}



output "api_url" {
  description = "URL del Application Load Balancer"

  value = "http://${module.networking.alb_dns_name}"
}