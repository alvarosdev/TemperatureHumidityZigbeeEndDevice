#ifndef ZIGBEE_MODE_ED
#error "Zigbee end device mode is not selected"
#endif

#include <Wire.h>
#include <Adafruit_SHT4x.h>
#include "Zigbee.h"

// =============================================================================
// CONFIGURATION CONSTANTS
// =============================================================================
#define TEMP_SENSOR_ENDPOINT_NUMBER 10
#define uS_TO_S_FACTOR 1000000ULL
#define TIME_TO_SLEEP 60                // Sleep time in seconds
#define ENABLE_SLEEP true              // Enable/disable deep sleep mode
#define FAKE_SLEEP_TIME 60             // Delay when sleep is disabled (seconds)
#define BUTTON_DEBOUNCE_TIME 100       // Button debounce time in ms
#define FACTORY_RESET_TIME 10000       // Time to hold button for factory reset (ms)
#define ZIGBEE_TIMEOUT 10000           // Zigbee connection timeout in ms
#define SENSOR_RETRY_DELAY 50          // Delay between sensor read retries in ms

// Sensor validation limits
#define TEMP_MIN -40.0
#define TEMP_MAX 125.0
#define HUMIDITY_MIN 0.0
#define HUMIDITY_MAX 100.0

// =============================================================================
// GLOBAL VARIABLES
// =============================================================================
const uint8_t button = BOOT_PIN;
ZigbeeTempSensor zbTempSensor(TEMP_SENSOR_ENDPOINT_NUMBER);
Adafruit_SHT4x sht4 = Adafruit_SHT4x();

// =============================================================================
// FUNCTION DECLARATIONS
// =============================================================================
bool measureAndReport();
void handleButtonPress();
void initializeSensor();
void initializeZigbee();
void goToSleep();
bool isValidSensorData(float temperature, float humidity);

// =============================================================================
// MAIN FUNCTIONS
// =============================================================================
void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);
  
  Serial.println("=== AlvarosDev HumiTempSensor Starting ===");
  
  // Initialize hardware
  pinMode(button, INPUT_PULLUP);
  esp_sleep_enable_timer_wakeup(TIME_TO_SLEEP * uS_TO_S_FACTOR);
  
  // Initialize sensor and Zigbee
  initializeSensor();
  initializeZigbee();
  
  Serial.println("=== Setup Complete ===");
  delay(1000); // Allow system to stabilize
}

void loop() {
  handleButtonPress();
  
  bool success = measureAndReport();
  if (!success) {
    Serial.println("Measurement or reporting failed, retrying in next cycle");
  }
  
  goToSleep();
}

// =============================================================================
// SENSOR FUNCTIONS
// =============================================================================
bool measureAndReport() {
  sensors_event_t humidity_evt, temp_evt;
  
  Serial.println("Reading SHT4x sensor...");
  if (!sht4.getEvent(&humidity_evt, &temp_evt)) {
    Serial.println("Error reading SHT4x sensor");
    return false;
  }

  float temperature = temp_evt.temperature;
  float humidity = humidity_evt.relative_humidity;

  // Validate sensor data
  if (!isValidSensorData(temperature, humidity)) {
    return false;
  }

  // Update Zigbee attributes
  Serial.println("Updating Zigbee attributes...");
  zbTempSensor.setHumidity(humidity);
  zbTempSensor.setTemperature(temperature);
  
  Serial.println("Reporting to Zigbee network...");
  zbTempSensor.report();
  
  Serial.printf("✓ Reported - Temperature: %.2f°C, Humidity: %.2f%%\n", 
                temperature, humidity);
  
  return true;
}

bool isValidSensorData(float temperature, float humidity) {
  // Check for NaN values
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("✗ Invalid sensor data: NaN detected");
    return false;
  }
  
  // Check sensor data ranges
  if (temperature < TEMP_MIN || temperature > TEMP_MAX || 
      humidity < HUMIDITY_MIN || humidity > HUMIDITY_MAX) {
    Serial.println("✗ Sensor data out of valid range");
    return false;
  }
  
  return true;
}

// =============================================================================
// BUTTON HANDLING
// =============================================================================
void handleButtonPress() {
  if (digitalRead(button) == LOW) {
    delay(BUTTON_DEBOUNCE_TIME);
    
    unsigned long pressStart = millis();
    while (digitalRead(button) == LOW) {
      delay(SENSOR_RETRY_DELAY);
      
      if ((millis() - pressStart) > FACTORY_RESET_TIME) {
        Serial.println("=== FACTORY RESET TRIGGERED ===");
        Serial.println("Resetting Zigbee to factory settings...");
        delay(1000);
        
        Zigbee.factoryReset(false);
        
        Serial.println("Entering deep sleep. Press RESET to wake up.");
        esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_TIMER);
        esp_deep_sleep_start();
      }
    }
  }
}

// =============================================================================
// INITIALIZATION FUNCTIONS
// =============================================================================
void initializeSensor() {
  Serial.println("Initializing SHT4x sensor...");
  
  Wire.begin(1, 2);
  if (!sht4.begin()) {
    Serial.println("✗ SHT4x sensor not found!");
    while (1) delay(1000); // Halt execution
  }
  
  sht4.setPrecision(SHT4X_HIGH_PRECISION);
  sht4.setHeater(SHT4X_NO_HEATER);
  
  Serial.println("✓ SHT4x sensor initialized successfully");
}

void initializeZigbee() {
  Serial.println("Configuring Zigbee device...");
  
  // Configure device properties
  zbTempSensor.setManufacturerAndModel("AlvarosDev", "HumiTempSensor");
  zbTempSensor.setMinMaxValue(10, 50);
  zbTempSensor.setTolerance(1);
  zbTempSensor.setPowerSource(ZB_POWER_SOURCE_BATTERY, 100);
  zbTempSensor.addHumiditySensor(0, 100, 1);
  
  // Add endpoint to Zigbee stack
  Serial.println("Adding Zigbee endpoint...");
  Zigbee.addEndpoint(&zbTempSensor);

  // Configure Zigbee stack
  esp_zb_cfg_t zigbeeConfig = ZIGBEE_DEFAULT_ED_CONFIG();
  zigbeeConfig.nwk_cfg.zed_cfg.keep_alive = ZIGBEE_TIMEOUT;
  Zigbee.setTimeout(ZIGBEE_TIMEOUT);
  
  // Start Zigbee stack
  Serial.println("Starting Zigbee stack...");
  if (!Zigbee.begin(&zigbeeConfig, false)) {
    Serial.println("✗ Zigbee failed to start! Restarting...");
    ESP.restart();
  }
  
  // Wait for network connection
  Serial.print("Connecting to Zigbee network");
  while (!Zigbee.connected()) {
    Serial.print(".");
    delay(100);
  }
  Serial.println("\n✓ Successfully connected to Zigbee network");
}

// =============================================================================
// SLEEP MANAGEMENT
// =============================================================================
void goToSleep() {
  if (ENABLE_SLEEP) {
    Serial.println("Entering deep sleep mode...");
    delay(100); // Ensure serial output completes
    esp_deep_sleep_start();
  } else {
    Serial.printf("Sleep disabled - waiting %d seconds...\n", FAKE_SLEEP_TIME);
    delay(FAKE_SLEEP_TIME * 1000);
  }
}