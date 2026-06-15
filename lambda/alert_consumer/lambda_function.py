import json

def lambda_handler(event, context):

    print("=== ALERTA CRÍTICA RECIBIDA ===")

    for record in event["Records"]:

        body = json.loads(record["body"])

        print(
            f"ALERTA | Sensor={body['sensor_id']} "
            f"Tipo={body['sensor_type']} "
            f"Valor={body['value']} "
            f"Timestamp={body['timestamp']}"
        )

    return {
        "statusCode": 200
    }