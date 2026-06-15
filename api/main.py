from fastapi import FastAPI, HTTPException


from models import SensorCreate
from services.dynamodb import (
    get_all_sensors,
    get_sensor,
    create_sensor,
    delete_sensor,
    get_sensor_data,
    get_sensor_current,
    get_sensor_recent
)

from services.postgres import get_sensor_history

# source venv/bin/activate
# uvicorn main:app --reload

app = FastAPI(
    title="IoT Sensor API"
)


@app.get("/")
def root():
    return {
        "message": "IoT Sensor API running"
    }


### Health que el ALB va a necesitar ###
@app.get("/health")
def health():
    return {"status": "ok"}


### Listar todos los sensores registrados ###
@app.get("/sensors")
def list_sensors():
    return get_all_sensors()


### Listar sensores ###
@app.post("/sensors")
def register_sensor(sensor: SensorCreate):

    existing_sensor = get_sensor(sensor.sensor_id)

    if existing_sensor:
        raise HTTPException(
            status_code=409,
            detail="Sensor already exists"
        )

    create_sensor(sensor)

    return {
        "message": "Sensor created successfully",
        "sensor_id": sensor.sensor_id
    }

### Obtener un sensor por ID ###  
@app.get("/sensors/{sensor_id}")
def get_sensor_by_id(sensor_id: str):

    sensor = get_sensor(sensor_id)

    if not sensor:
        raise HTTPException(
            status_code=404,
            detail="Sensor not found"
        )

    return sensor

### Eliminar un sensor por ID ###
@app.delete("/sensors/{sensor_id}")
def remove_sensor(sensor_id: str):

    sensor = get_sensor(sensor_id)

    if not sensor:
        raise HTTPException(
            status_code=404,
            detail="Sensor not found"
        )

    delete_sensor(sensor_id)

    return {
        "message": "Sensor deleted successfully",
        "sensor_id": sensor_id
    }


### Obtener el historial de datos de un sensor por ID ###
@app.get("/sensors/{sensor_id}/data")
def sensor_history(sensor_id: str):

    return get_sensor_data(sensor_id)


### Obtiene el dato en tiempo real consultando DynamoDB.
@app.get("/sensor/{sensor_id}/current")
def sensor_current(sensor_id: str):

    data = get_sensor_current(sensor_id)

    if not data:
        raise HTTPException(
            status_code=404,
            detail="No data found for sensor"
        )

    return data

### Obtiene los últimos 10 eventos consultando DynamoDB.
@app.get("/sensor/{sensor_id}/recent")
def sensor_recent(sensor_id: str):

    return get_sensor_recent(sensor_id)


### Consulta el histórico completo en PostgreSQL.
@app.get("/sensor/{sensor_id}/history")
def history(sensor_id: str):
    return get_sensor_history(sensor_id)