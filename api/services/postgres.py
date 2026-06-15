import psycopg2

### Localmente ###
# DB_HOST = "iot-postgres.cy60tnifmdu3.us-east-1.rds.amazonaws.com"
# DB_NAME = "iot"
# DB_USER = "postgres"
# DB_PASSWORD = "Password123!"


### ECS ###
import os

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


def get_sensor_history(sensor_id: str):

    conn = get_connection()

    cur = conn.cursor()

    cur.execute(
        """
        SELECT
            sensor_id,
            sensor_type,
            value,
            event_timestamp
        FROM sensor_history
        WHERE sensor_id = %s
        ORDER BY event_timestamp DESC
        """,
        (sensor_id,)
    )

    rows = cur.fetchall()

    cur.close()
    conn.close()

    return [
        {
            "sensor_id": row[0],
            "sensor_type": row[1],
            "value": float(row[2]),
            "timestamp": row[3]
        }
        for row in rows
    ]