from pydantic import BaseModel


class SensorCreate(BaseModel):
    sensor_id: str
    sensor_type: str


class SensorResponse(BaseModel):
    sensor_id: str
    sensor_type: str