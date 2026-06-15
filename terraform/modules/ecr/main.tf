resource "aws_ecr_repository" "api_repo" {
  name                 = "${var.project_name}-repo-${var.environment}"
  image_tag_mutability = "MUTABLE"

  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}