#ifndef ZIGBEE_MODE_ED
#error "Zigbee end device mode is not selected"
#endif

#include "Zigbee.h"
#include "esp_sleep.h"
#include <Adafruit_SHT4x.h>
#include <Wire.h>

// =============================================================================
// CONFIGURATION CONSTANTS
// =============================================================================
const int TEMP_SENSOR_ENDPOINT_NUMBER = 10;
const unsigned long long uS_TO_S_FACTOR = 1000000ULL;
const int TIME_TO_SLEEP = 60;         // Sleep time in seconds
const bool ENABLE_SLEEP = true;       // Enable/disable deep sleep mode
const int FAKE_SLEEP_TIME = 60;       // Delay when sleep is disabled (seconds)
const int BUTTON_DEBOUNCE_TIME = 100; // Button debounce time in ms
const int FACTORY_RESET_TIME =
    10000;                         // Time to hold button for factory reset (ms)
const int ZIGBEE_TIMEOUT = 10000;  // Zigbee connection timeout in ms
const int SENSOR_RETRY_DELAY = 50; // Delay between sensor read retries in ms

// Sensor validation limits
const float TEMP_MIN = -40.0;
const float TEMP_MAX = 125.0;
const float HUMIDITY_MIN = 0.0;
const float HUMIDITY_MAX = 100.0;

// Communication constants
const long SERIAL_BAUD_RATE = 115200;
const int I2C_SDA_PIN = 1;
const int I2C_SCL_PIN = 2;
const int SERIAL_WAIT_TIME_MS =
    10; // Delay after Serial.begin to allow connection

// Delay constants
const int SETUP_STABILIZE_DELAY_MS =
    1000; // Delay after setup to allow system stabilization
const int FACTORY_RESET_DELAY_MS =
    1000; // Delay after triggering factory reset before sleep

// Initialization and connection delays
const int ZIGBEE_CONNECT_DELAY_MS =
    100; // Delay while waiting for Zigbee network connection
const int SHT4X_INIT_FAILURE_DELAY_MS =
    1000; // Delay in the infinite loop when SHT4x sensor initialization fails

// Sleep delays
const int SLEEP_ENTRY_DELAY_MS =
    100; // Delay after printing sleep message to ensure serial output completes

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
void initializeSensor(esp_sleep_wakeup_cause_t wakeup_cause);
void initializeZigbee(esp_sleep_wakeup_cause_t wakeup_cause);
void goToSleep();
bool isValidSensorData(float temperature, float humidity);

// =============================================================================
// MAIN FUNCTIONS
// =============================================================================
void setup() {
  Serial.begin(SERIAL_BAUD_RATE);
  while (!Serial)
    delay(SERIAL_WAIT_TIME_MS);

  esp_sleep_wakeup_cause_t wakeup_cause = esp_sleep_get_wakeup_cause();

  if (wakeup_cause == ESP_SLEEP_WAKEUP_TIMER) {
    Serial.println(F("=== Woke up from sleep ==="));
  } else {
    Serial.println(F("=== AlvarosDev HumiTempSensor Starting ==="));
  }

  pinMode(button, INPUT_PULLUP);
  esp_sleep_enable_timer_wakeup(TIME_TO_SLEEP * uS_TO_S_FACTOR);

  initializeSensor(wakeup_cause);
  initializeZigbee(wakeup_cause);

  if (wakeup_cause != ESP_SLEEP_WAKEUP_TIMER) {
    Serial.println(F("=== Setup Complete ==="));
    delay(SETUP_STABILIZE_DELAY_MS);
  }
}

void loop() {
  handleButtonPress();

  bool success = measureAndReport();
  if (!success) {
    Serial.println(
        F("Measurement or reporting failed, retrying in next cycle"));
  }

  goToSleep();
}

// =============================================================================
// SENSOR FUNCTIONS
// =============================================================================
bool measureAndReport() {
  sensors_event_t humidity_evt, temp_evt;

  if (!sht4.getEvent(&humidity_evt, &temp_evt)) {
    Serial.println(F("Error reading SHT4x sensor"));
    return false;
  }

  float temperature = temp_evt.temperature;
  float humidity = humidity_evt.relative_humidity;

  if (!isValidSensorData(temperature, humidity)) {
    return false;
  }

  zbTempSensor.setHumidity(humidity);
  zbTempSensor.setTemperature(temperature);

  zbTempSensor.report();

  Serial.printf(F("✓ Reported - Temperature: %.2f°C, Humidity: %.2f%%\n"),
                temperature, humidity);

  return true;
}

bool isValidSensorData(float temperature, float humidity) {
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println(F("✗ Invalid sensor data: NaN detected"));
    return false;
  }

  if (temperature < TEMP_MIN || temperature > TEMP_MAX ||
      humidity < HUMIDITY_MIN || humidity > HUMIDITY_MAX) {
    Serial.println(F("✗ Sensor data out of valid range"));
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
        Serial.println(F("=== FACTORY RESET TRIGGERED ==="));
        Serial.println(F("Resetting Zigbee to factory settings..."));
        delay(FACTORY_RESET_DELAY_MS);

        Zigbee.factoryReset(
            false); // false means do not erase NVRAM, preserving some settings

        Serial.println(F("Entering deep sleep. Press RESET to wake up."));
        esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_TIMER);
        esp_deep_sleep_start();
      }
    }
  }
}

// =============================================================================
// INITIALIZATION FUNCTIONS
// =============================================================================
void initializeSensor(esp_sleep_wakeup_cause_t wakeup_cause) {
  if (wakeup_cause != ESP_SLEEP_WAKEUP_TIMER) {
    Serial.println(F("Initializing SHT4x sensor..."));
  }

  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  if (!sht4.begin()) {
    Serial.println(F("✗ SHT4x sensor not found!"));
    while (1)
      delay(SHT4X_INIT_FAILURE_DELAY_MS);
  }

  sht4.setPrecision(SHT4X_HIGH_PRECISION);
  sht4.setHeater(SHT4X_NO_HEATER);

  if (wakeup_cause != ESP_SLEEP_WAKEUP_TIMER) {
    Serial.println(F("✓ SHT4x sensor initialized successfully"));
  }
}

void initializeZigbee(esp_sleep_wakeup_cause_t wakeup_cause) {
  if (wakeup_cause != ESP_SLEEP_WAKEUP_TIMER) {
    Serial.println(F("Configuring Zigbee device..."));
  }

  // Configure device properties
  zbTempSensor.setManufacturerAndModel("AlvarosDev", "HumiTempSensor");
  zbTempSensor.setMinMaxValue(10, 50);
  zbTempSensor.setTolerance(1);
  zbTempSensor.setPowerSource(ZB_POWER_SOURCE_BATTERY, 100);
  zbTempSensor.addHumiditySensor(0, 100, 1);

  if (wakeup_cause != ESP_SLEEP_WAKEUP_TIMER) {
    Serial.println(F("Adding Zigbee endpoint..."));
  }
  Zigbee.addEndpoint(&zbTempSensor);

  // Configure Zigbee stack settings
  esp_zb_cfg_t zigbeeConfig = ZIGBEE_DEFAULT_ED_CONFIG();
  zigbeeConfig.nwk_cfg.zed_cfg.keep_alive = ZIGBEE_TIMEOUT;
  Zigbee.setTimeout(ZIGBEE_TIMEOUT);

  if (wakeup_cause != ESP_SLEEP_WAKEUP_TIMER) {
    Serial.println(F("Starting Zigbee stack..."));
  }
  if (!Zigbee.begin(&zigbeeConfig, false)) {
    Serial.println(F("✗ Zigbee failed to start! Restarting..."));
    ESP.restart();
  }

  // Only print connection message on initial boot
  if (wakeup_cause != ESP_SLEEP_WAKEUP_TIMER) {
    Serial.print(F("Connecting to Zigbee network"));
    while (!Zigbee.connected()) {
      Serial.print(".");
      delay(ZIGBEE_CONNECT_DELAY_MS);
    }
    Serial.println(F("\n✓ Connected to Zigbee network"));
  } else {
    // On wake-up, just wait for connection silently or with minimal indicator
    // if needed For now, we'll assume silent reconnection is desired for
    // cleaner logs.
    while (!Zigbee.connected()) {
      delay(ZIGBEE_CONNECT_DELAY_MS);
    }
    Serial.println(F(
        "✓ Reconnected to Zigbee network")); // Indicate reconnection on wake-up
  }
}

// =============================================================================
// SLEEP MANAGEMENT
// =============================================================================
void goToSleep() {
  if (ENABLE_SLEEP) {
    Serial.println(F("Entering deep sleep mode..."));
    delay(SLEEP_ENTRY_DELAY_MS);
    esp_deep_sleep_start();
  } else {
    Serial.printf(F("Sleep disabled - waiting %d seconds...\n"),
                  FAKE_SLEEP_TIME);
    delay(FAKE_SLEEP_TIME * 1000);
  }
}