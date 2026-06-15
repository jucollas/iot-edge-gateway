import os
import time
import json
from datetime import datetime, timezone
import random
import paho.mqtt.client as mqtt

# Configuraciones desde variables de entorno
MQTT_HOST = os.environ.get("MQTT_HOST", "localhost")
MQTT_PORT = int(os.environ.get("MQTT_PORT", 1883))
CLIENT_ID = os.environ.get("CLIENT_ID", f"sensor-{random.randint(1000,9999)}")
SENSOR_TYPE = os.environ.get("SENSOR_TYPE", "temperature") # temperature, humidity, etc.
INTERVAL = int(os.environ.get("INTERVAL", 5))

TOPIC = "lab/sensors/data"

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"[{CLIENT_ID}] Conectado exitosamente al broker local MQTT en {MQTT_HOST}:{MQTT_PORT}")
    else:
        print(f"[{CLIENT_ID}] Error al conectar. Código: {rc}")

def generate_sensor_data():
    """Genera un dato simulado para este sensor."""
    value = 0.0
    if SENSOR_TYPE == "temperature":
        value = round(random.uniform(25.0, 45.0), 2)
    elif SENSOR_TYPE == "humidity":
        value = round(random.uniform(40.0, 60.0), 2)
    else:
        value = round(random.uniform(0.0, 100.0), 2)

    return {
        "sensor_id": CLIENT_ID,
        "sensor_type": SENSOR_TYPE,
        "value": value,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

def main():
    print(f"[{CLIENT_ID}] Iniciando sensor tipo '{SENSOR_TYPE}'...")
    
    client = mqtt.Client(client_id=CLIENT_ID)
    client.on_connect = on_connect

    # Conexión sin TLS ya que es dentro de la red local de Docker
    while True:
        try:
            client.connect(MQTT_HOST, MQTT_PORT, 60)
            break
        except Exception as e:
            print(f"[{CLIENT_ID}] Esperando al broker MQTT {MQTT_HOST}:{MQTT_PORT}... Error: {e}")
            time.sleep(2)

    client.loop_start()

    try:
        count = 1
        while True:
            payload = generate_sensor_data()
            print(f"[{CLIENT_ID}] Publicando: {payload}")
            
            client.publish(TOPIC, json.dumps(payload), qos=1)
            count += 1
            time.sleep(INTERVAL)
            
    except KeyboardInterrupt:
        print(f"\n[{CLIENT_ID}] Deteniendo sensor...")
    finally:
        client.loop_stop()
        client.disconnect()
        print(f"[{CLIENT_ID}] Desconectado.")

if __name__ == '__main__':
    main()
