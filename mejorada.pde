import processing.serial.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.BufferedReader;
import java.io.InputStreamReader;

Serial myPort;  // Puerto serie
String[] data;  // Para almacenar los datos recibidos
float humidity, temperature, airQuality;
boolean manualAlarm = false;
boolean automaticAlarm = false;
String espIp = "<DIRECCION_IP_DEL_ESP8266>"; // Cambia esto por tu IP por defecto, si es necesario

void setup() {
  size(800, 600);
  myPort = new Serial(this, "COM3", 115200);  // Configurar para usar el puerto correcto
  smooth();
  espIp = getESP8266IP();  // Obtener IP del ESP8266
}

void draw() {
  background(240);  // Fondo gris claro
  
  // Título del panel
  fill(30);
  textSize(32);
  textAlign(CENTER);
  text("Panel de Monitoreo Meteorológico", width / 2, 50);
  
  // Sección de datos
  float yStart = 120; // Posición inicial para las barras
  float barHeight = 50; // Altura de las barras
  float barWidth = 300; // Ancho de las barras
  float margin = 20; // Margen entre las barras
  
  drawBar("• Humedad", humidity, color(0, 0, 255), yStart, 0, 100, barHeight, barWidth);
  drawBar("• Temperatura", temperature, color(255, 165, 0), yStart + barHeight + margin, -10, 50, barHeight, barWidth);
  drawBar("• Calidad del aire", airQuality, color(0, 255, 0), yStart + 2 * (barHeight + margin), 0, 300, barHeight, barWidth);
  
  // Botones
  drawButton("Reiniciar", width - 240, height - 50, 100, 40);
  drawButton("Salir", width - 120, height - 50, 100, 40);
  //drawButton("Alarma Manual", width - 240, height - 100, 120, 40);
  
  // Mostrar estado de alarmas
  if (manualAlarm) {
    fill(255, 0, 0);
    textSize(20);
    textAlign(CENTER);
    text("¡ALERTA MANUAL ACTIVADA!", width / 2, height - 150);
  }
  if (automaticAlarm) {
    fill(255, 0, 0);
    textSize(20);
    textAlign(CENTER);
    text("¡ALERTA AUTOMÁTICA ACTIVADA!", width / 2, height - 180);
  }

  // Mostrar fecha y hora
  String currentTime = getCurrentTime();
  fill(30);
  textSize(16);
  textAlign(RIGHT);
  text(currentTime, width - 20, 30);
  
  // Leer datos del puerto serie
  if (myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    if (inString != null) {
      data = inString.trim().split(",");
      if (data.length == 3) {
        humidity = float(data[0]);
        temperature = float(data[1]);
        airQuality = float(data[2]);
      }
    }
  }
  
  // Verificar alarmas automáticas
  if (temperature > 30 && humidity < 60) {
    automaticAlarm = true;
    sendCommand("led_on");  // Activar LED automáticamente
  } else {
    automaticAlarm = false;
    sendCommand("led_off");  // Desactivar LED automáticamente
  }
}

void drawBar(String label, float value, color barColor, float yPosition, float minValue, float maxValue, float barHeight, float barWidth) {
  float normalizedValue = map(value, minValue, maxValue, 0, barWidth);
  
  fill(255);
  stroke(200);
  rect(180, yPosition - 10, barWidth + 40, barHeight + 20, 10);
  
  fill(barColor);
  rect(200, yPosition, normalizedValue, barHeight, 5);
  
  stroke(0);
  strokeWeight(1);
  noFill();
  rect(200, yPosition, barWidth, barHeight, 5);
  
  fill(50);
  textSize(18);
  textAlign(LEFT);
  text(label + ": ", 20, yPosition + 20);
  
  fill(0);
  textSize(14);
  textAlign(RIGHT);
  String unit = "";
  if (label.equals("• Humedad")) {
    unit = " %";
  } else if (label.equals("• Temperatura")) {
    unit = " °C";
  } else if (label.equals("• Calidad del aire")) {
    unit = " ppm";
  }
  text(value + unit, 200 + normalizedValue + 10, yPosition + 20);
  
  stroke(150);
  strokeWeight(0.5);
  line(200, yPosition + barHeight, 500, yPosition + barHeight);
}

void drawButton(String label, float x, float y, float w, float h) {
  fill(50);
  rect(x, y, w, h, 10);
  fill(255);
  textSize(16);
  textAlign(CENTER, CENTER);
  text(label, x + w / 2, y + h / 2);
}

void mousePressed() {
  if (mouseX > width - 240 && mouseX < width - 140 && mouseY > height - 50 && mouseY < height - 10) {
    humidity = 0;
    temperature = 0;
    airQuality = 0;
    manualAlarm = false;
    automaticAlarm = false;
    sendCommand("led_off");  // Desactivar LED manualmente
  }
  
  if (mouseX > width - 120 && mouseX < width - 20 && mouseY > height - 50 && mouseY < height - 10) {
    exit();
  }

  if (mouseX > width - 240 && mouseX < width - 120 && mouseY > height - 100 && mouseY < height - 60) {
    manualAlarm = true;
    sendCommand("led_on");  // Activar LED manualmente
  }
}

void sendCommand(String command) {
  String url = "http://" + espIp + "/" + command; // Cambia la IP por la IP del ESP8266
  try {
    URL myURL = new URL(url);
    HttpURLConnection con = (HttpURLConnection) myURL.openConnection();
    con.setRequestMethod("GET");
    int responseCode = con.getResponseCode();
    if (responseCode == 200) {
      println("Comando enviado: " + command);
    } else {
      println("Error al enviar comando");
    }
  } catch (Exception e) {
    e.printStackTrace();
  }
}

String getESP8266IP() {
  String ip = "";
  try {
    URL myURL = new URL("http://<DIRECCION_IP_DEL_ESP8266>/get_ip"); // Cambia esto por el endpoint de tu ESP8266
    HttpURLConnection con = (HttpURLConnection) myURL.openConnection();
    con.setRequestMethod("GET");
    BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
    ip = in.readLine(); // Asume que la respuesta es solo la IP
    in.close();
    println("IP del ESP8266: " + ip);
  } catch (Exception e) {
    e.printStackTrace();
  }
  return ip;
}

String getCurrentTime() {
  SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
  Date date = new Date();
  return formatter.format(date);
}
