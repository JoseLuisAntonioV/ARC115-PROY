//Librerias a Incluir
#include <ESP8266WiFi.h>
#include <DHT11.h>

// Configuración de los pines
#define DHTPIN D4            // Pin donde está conectado el DHT11
#define MQ3PIN A0            // Pin analógico donde está conectado el MQ-3

DHT11 dht(DHTPIN);           // Inicializar el sensor DHT11 en el pin correspondiente

//Declaracion de Variables
float humidity;
float temperature;
int airQualityRaw;
int airQuality;  // Variable para guardar el valor en ppm

//Setup Inicial
void setup() {
  //Definimos valor e Bauds
  Serial.begin(115200);
}

//Iniciamos Loop
void loop() {
  // Leer valores del sensor DHT11
  humidity = dht.readHumidity();
  temperature = dht.readTemperature();

  //Leer valores del sensor MQ135
  airQualityRaw = analogRead(MQ3PIN);

  // Convertir a ppm
  airQuality = map(airQualityRaw, 0, 1023, 0, 500); // Mapea el valor a 0-500 ppm

  // Verificar si la lectura fue correcta
  if (!isnan(humidity) && !isnan(temperature)) {
    // Enviar datos en formato CSV
    Serial.print(humidity);
    Serial.print(",");
    Serial.print(temperature);
    Serial.print(",");
    Serial.println(airQuality); // Envía el valor en ppm
  } else {
    //Coeigo de ERROR
    Serial.println("Error");
  }
  
  delay(2000); // Retraso de 2 segundos entre lecturas
}
