#!/bin/bash

set -e

REGION="us-east-1"

echo "=== Obtener datos de AWS ==="

ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account \
  --output text)

REPO_URI=$(cd terraform && terraform output -raw ecr_repository_url)

echo "Account ID: $ACCOUNT_ID"
echo "Repo URI: $REPO_URI"

echo "=== Login ECR ==="

aws ecr get-login-password --region $REGION | \
docker login \
--username AWS \
--password-stdin \
$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo "=== Build API ==="

docker build \
-t iot-api \
./api

echo "=== Tag ==="

docker tag \
iot-api:latest \
$REPO_URI:latest

echo "=== Push ==="

docker push \
$REPO_URI:latest

echo "=== Forzar redeploy ECS ==="

CLUSTER=$(aws ecs list-clusters \
--query "clusterArns[0]" \
--output text)

SERVICE=$(aws ecs list-services \
--cluster $CLUSTER \
--query "serviceArns[0]" \
--output text)

aws ecs update-service \
--cluster $CLUSTER \
--service $SERVICE \
--force-new-deployment

echo "=== Despliegue completado ==="