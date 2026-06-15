import os
import boto3
from boto3.dynamodb.conditions import Key


### Variables de entorno para ECS ###
AWS_REGION = os.environ["AWS_REGION"]

SENSORS_TABLE = os.environ["SENSORS_TABLE"]
SENSOR_DATA_TABLE = os.environ["SENSOR_DATA_TABLE"]

dynamodb = boto3.resource(
    "dynamodb",
    region_name=AWS_REGION
)

table = dynamodb.Table(SENSORS_TABLE)

sensor_data_table = dynamodb.Table(
    SENSOR_DATA_TABLE
)


### local ###
# TABLE_NAME = "Sensors-lab"

# dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
# table = dynamodb.Table(TABLE_NAME)

# sensor_data_table = dynamodb.Table("SensorData-lab")


def get_all_sensors():
    response = table.scan()
    return response.get("Items", [])


def get_sensor(sensor_id: str):
    response = table.get_item(
        Key={
            "sensor_id": sensor_id
        }
    )

    return response.get("Item")


def create_sensor(sensor):
    table.put_item(
        Item={
            "sensor_id": sensor.sensor_id,
            "sensor_type": sensor.sensor_type
        }
    )

def delete_sensor(sensor_id: str):

    table.delete_item(
        Key={
            "sensor_id": sensor_id
        }
    )

def get_sensor_data(sensor_id: str):

    response = sensor_data_table.query(
        KeyConditionExpression=Key("sensor_id").eq(sensor_id)
    )

    return response.get("Items", [])

def get_sensor_current(sensor_id: str):

    response = sensor_data_table.query(
        KeyConditionExpression=Key("sensor_id").eq(sensor_id),
        ScanIndexForward=False,
        Limit=1
    )

    items = response.get("Items", [])

    if not items:
        return None

    return items[0]


def get_sensor_recent(sensor_id: str):

    response = sensor_data_table.query(
        KeyConditionExpression=Key("sensor_id").eq(sensor_id),
        ScanIndexForward=False,
        Limit=10
    )

    return response.get("Items", [])