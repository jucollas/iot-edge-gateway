# Tutorial: Cómo crear una Regla en AWS IoT Core para disparar una Lambda (Desde la Consola)

En este tutorial aprenderás paso a paso cómo crear una regla directamente desde la interfaz gráfica (Consola de AWS) para que, cada vez que llegue un mensaje de un sensor, se ejecute automáticamente una función AWS Lambda.

---

## 1. Requisito Previo: Crear la función Lambda

Antes de crear la regla, necesitamos tener una función Lambda que vaya a ser ejecutada.

1. Ve a la consola de **AWS Lambda** y haz clic en **"Crear función"** (Create function).
2. Selecciona **"Crear desde cero"** (Author from scratch).
3. **Nombre de la función:** `ProcesarDatosIoT` (o el nombre que prefieras).
4. **Tiempo de ejecución:** `Python 3.12` (o Node.js, según tu preferencia).
5. Haz clic en **"Crear función"**.
6. En el editor de código de la Lambda, reemplaza el código con este ejemplo básico que simplemente imprime el mensaje recibido:

```python
import json

def lambda_handler(event, context):
    # 'event' contiene el payload JSON enviado por IoT Core
    # Formato real del sensor: {"device_id": "...", "sensor_type": "...", "value": 25.5, "timestamp": "..."}
    print("Mensaje recibido de IoT Core:")
    print(json.dumps(event, indent=2))
    
    # Ejemplo: evaluar el valor del sensor
    sensor_type = event.get('sensor_type', 'unknown')
    value = event.get('value', 0)
    
    if sensor_type == 'temperature' and value > 30:
        print(f"ALERTA: Temperatura alta detectada ({value}°C)")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Procesamiento exitoso')
    }
```
7. Haz clic en **"Deploy"** (Implementar) para guardar el código.

---

## 2. Crear la Regla en AWS IoT Core

Ahora vamos a crear la regla que conectará los mensajes MQTT con la función Lambda que acabamos de crear.

### Paso 2.1: Navegar a las Reglas de IoT
1. Ve a la consola de **AWS IoT Core**.
2. En el menú lateral izquierdo, busca la sección **"Message routing"** (Enrutamiento de mensajes) y haz clic en **"Rules"** (Reglas).
3. Haz clic en el botón naranja **"Create rule"** (Crear regla).

### Paso 2.2: Propiedades de la Regla
1. **Rule name:** Escribe un nombre descriptivo, por ejemplo `SensorToLambdaRule`.
2. **Rule description:** (Opcional) "Dispara una Lambda cuando llega un mensaje de los sensores".
3. Haz clic en **"Next"** (Siguiente).

### Paso 2.3: Configurar la sentencia SQL
Aquí es donde le decimos a AWS qué mensajes debe interceptar.
1. **SQL version:** Déjalo en `2016-03-23`.
2. **SQL statement:** Escribe la siguiente consulta para atrapar todos los mensajes del tópico de los sensores:
   ```sql
   SELECT * FROM 'lab/sensors/data'
   ```
   *(Si quisieras filtrar, podrías usar algo como `SELECT * FROM 'lab/sensors/data' WHERE sensor_type = 'temperature' AND value > 30`)*.
3. Haz clic en **"Next"** (Siguiente).

### Paso 2.4: Agregar la Acción (Action)
1. En la sección de *Rule actions*, haz clic en el menú desplegable **"Action 1"**.
2. Busca y selecciona **"Send a message to a Lambda function"** (Enviar un mensaje a una función Lambda).
3. Aparecerá un campo llamado **Lambda function**. Haz clic en el menú desplegable y selecciona la función que creaste en el Paso 1 (`ProcesarDatosIoT`).
4. **Nota sobre permisos:** A diferencia de otras acciones como DynamoDB o S3 que requieren un IAM Role, cuando configuras una acción de Lambda desde la consola, AWS automáticamente agrega los permisos necesarios basados en recursos a la función Lambda para permitir que IoT Core la invoque.
5. Haz clic en **"Next"** (Siguiente).

### Paso 2.5: Revisar y Crear
1. Revisa que el nombre, la sentencia SQL y la acción de Lambda sean correctos.
2. Haz clic en **"Create"** (Crear).

¡Listo! La regla ahora está activa.

---

## 3. ¿Cómo probarlo?

Para probar que funciona, tienes dos opciones:

### Opción A: Usar tu entorno local (Docker)
Simplemente ejecuta tu entorno local con `make local-up`. Los sensores empezarán a enviar datos a través del Bridge y activarán la regla.

### Opción B: Usar el cliente MQTT de prueba de AWS
1. En la consola de **AWS IoT Core**, ve a **"Test"** > **"MQTT test client"**.
2. Ve a la pestaña **"Publish to a topic"**.
3. En **Topic name**, escribe `lab/sensors/data`.
4. En **Message payload**, escribe un JSON de prueba que coincida con el formato real del sensor:
   ```json
   {
     "device_id": "sensor-test",
     "sensor_type": "temperature",
     "value": 25.5,
     "timestamp": "2026-05-13T12:00:00+00:00"
   }
   ```
5. Haz clic en **"Publish"**.

### Verificando el resultado
1. Ve a la consola de **AWS Lambda** y abre tu función `ProcesarDatosIoT`.
2. Haz clic en la pestaña **"Monitor"** y luego en **"View CloudWatch logs"** (Ver registros en CloudWatch).
3. Abre el Log Stream más reciente.
4. Deberías ver el `print` que hicimos en el código con el JSON exacto que enviaste o que enviaron los contenedores locales. ¡Esto confirma que la integración funciona perfectamente!
