import json
import os
import urllib.parse

import boto3
import psycopg2

s3 = boto3.client("s3")

DB_HOST = os.environ["DB_HOST"]
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]


def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )


def lambda_handler(event, context):

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS sensor_history (
        id SERIAL PRIMARY KEY,
        sensor_id VARCHAR(100),
        sensor_type VARCHAR(100),
        value NUMERIC,
        event_timestamp TIMESTAMP
    );
    """)

    for record in event["Records"]:

        bucket = record["s3"]["bucket"]["name"]

        key = urllib.parse.unquote_plus(
            record["s3"]["object"]["key"]
        )

        response = s3.get_object(
            Bucket=bucket,
            Key=key
        )

        body = response["Body"].read()

        data = json.loads(body)

        cur.execute(
            """
            INSERT INTO sensor_history
            (
                sensor_id,
                sensor_type,
                value,
                event_timestamp
            )
            VALUES (%s,%s,%s,%s)
            """,
            (
                data["sensor_id"],
                data["sensor_type"],
                data["value"],
                data["timestamp"]
            )
        )

    conn.commit()

    cur.close()
    conn.close()

    return {"statusCode": 200}