import json
import boto3
import os

sqs = boto3.client("sqs")

QUEUE_URL = os.environ["QUEUE_URL"]


def lambda_handler(event, context):

    print("Evento recibido:")
    print(json.dumps(event))

    message = {
        "sensor_id": event.get("sensor_id"),
        "sensor_type": event.get("sensor_type"),
        "value": event.get("value"),
        "timestamp": event.get("timestamp"),
        "alert": "TEMPERATURE_THRESHOLD_EXCEEDED"
    }

    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(message)
    )

    print("Mensaje enviado a SQS")

    return {
        "statusCode": 200
    }