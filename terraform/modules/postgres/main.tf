### Security Group para RDS ###
resource "aws_security_group" "postgres" {
  name        = "iot-postgres-sg"
  description = "Postgres access"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### Subnet Group para RDS ###
resource "aws_db_subnet_group" "postgres" {
  name = "iot-postgres-subnets"

  subnet_ids = [
    var.subnet_a,
    var.subnet_b
  ]
}


### RDS ###
resource "aws_db_instance" "postgres" {
  identifier = "iot-postgres"

  engine         = "postgres"
  engine_version = "15"

  instance_class = "db.t3.micro"

  allocated_storage = 20

  username = "postgres"
  password = var.db_password

  db_name = "iot"

  publicly_accessible = true

  skip_final_snapshot = true

  vpc_security_group_ids = [
    aws_security_group.postgres.id
  ]

  db_subnet_group_name = aws_db_subnet_group.postgres.name
}