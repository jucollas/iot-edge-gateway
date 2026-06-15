import boto3

dynamodb = boto3.resource("dynamodb")

SENSORS_TABLE = "Sensors-lab"

table = dynamodb.Table(SENSORS_TABLE)


def lambda_handler(event, context):

    for record in event["Records"]:

        if record["eventName"] != "INSERT":
            continue

        item = record["dynamodb"]["NewImage"]

        sensor_id = item["sensor_id"]["S"]
        sensor_type = item["sensor_type"]["S"]

        table.put_item(
            Item={
                "sensor_id": sensor_id,
                "sensor_type": sensor_type
            }
        )

    return {
        "statusCode": 200
    }