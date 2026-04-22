# Cipher Tech (ESP32-DIV) — Auditoría Completa
**Fecha:** 2026-04-22  
**Versión del proyecto:** v1.5.0  
**Rama:** main  

---

## 1. Descripción General

El **Cipher Tech** (nombre interno: ESP32-DIV) es un dispositivo de seguridad/pentesting
portátil tipo Flipper Zero, basado en ESP32-S3 WROOM, con pantalla táctil TFT, botones
físicos vía expansor I2C, y múltiples radios (WiFi, BLE, Sub-GHz, NRF24, IR).

---

## 2. Estructura de Archivos

### Código fuente (`/ESP32-DIV/`)

| Archivo | Líneas | Descripción |
|---|---|---|
| `ESP32-DIV.ino` | 2607 | Main: setup, loop, sistema de menús |
| `bluetooth.cpp` | 2869 | BLE jammer, spoofer, SourApple, sniffer, scanner, NRF24 |
| `wifi.cpp` | 5055 | Packet monitor, beacon spam, deauther, WiFi scan, captive portal |
| `subghz.cpp` | 2152 | Replay attack, jammer, perfiles guardados (CC1101) |
| `ir.cpp` | 1598 | IR record y replay |
| `ducky.cpp` | 1374 | BLE Rubber Ducky |
| `utils.cpp` | 1483 | Status bar, batería, SD card, UI de settings, terminal serial |
| `KeyboardUI.cpp` | 220 | Teclado táctil en pantalla |
| `SettingsStore.cpp` | 112 | Configuración JSON persistida en SD |
| `Theme.cpp` | 29 | Paleta de colores UI |
| `Touchscreen.cpp` | 28 | Inicialización XPT2046 |
| `icon.h` | 1463 | Datos de iconos bitmap |
| `shared.h` | 326 | Pines, colores, constantes globales |
| `config.h` | 133 | Includes centralizados + declaraciones de namespaces |
| `BleCompat.h` | 14 | Shim NimBLE → BLEDevice API |
| `bleconfig.h` | 61 | **REDUNDANTE** — duplica config.h (pendiente eliminar) |
| `wificonfig.h` | 73 | Includes WiFi — parcialmente redundante con config.h |
| `subconfig.h` | 36 | Includes SubGHz — parcialmente redundante con config.h |
| `utils.h` | 103 | Declaraciones de utils, FeatureUI, Terminal |
| `KeyboardUI.h` | 39 | Struct OnScreenKeyboardConfig/Result |
| `SettingsStore.h` | 30 | Struct AppSettings |
| `Touchscreen.h` | 25 | Declaraciones touchscreen |

### Otros directorios

| Directorio | Contenido |
|---|---|
| `Flash File/` | Binarios pre-compilados para flashear |
| `Libraries/` | Librerías personalizadas |
| `PCB/` | Archivos de PCB |
| `Schematic/` | Esquemáticos (JPG + Excel BOM) |
| `Graphics/` | Recursos gráficos |
| `Pre-compiled Bin/` | Binarios listos |
| `Previous versions/` | Versiones anteriores (beta, v1) |

---

## 3. Hardware

| Componente | Detalle |
|---|---|
| MCU | ESP32-S3 WROOM |
| Display | TFT 240×320, biblioteca TFT_eSPI |
| Touch | XPT2046 (bus HSPI separado) |
| Botones | PCF8574 I2C expander, dirección 0x20 |
| Sub-GHz | CC1101 (SPI compartido con SD) |
| 2.4 GHz | Hasta 3× NRF24L01 |
| IR | TX GPIO 14, RX GPIO 21 |
| SD Card | SPI bus (MOSI=11, MISO=13, SCK=12) |
| BLE | NimBLE (shim en BleCompat.h) |
| Batería ADC | GPIO 2 (hardcodeado en código) |
| Backlight PWM | GPIO 7, canal LEDC 0 |
| Buzzer | GPIO 2, canal LEDC 7 |

---

## 4. Mapa de Pines (shared.h)

### PCF8574 (I2C expander — NO son GPIO directos)
| Pin PCF | Función |
|---|---|
| 3 | BTN_LEFT |
| 4 | BTN_RIGHT |
| 5 | BTN_DOWN |
| 6 | BTN_SELECT |
| 7 | BTN_UP |

### ESP32-S3 GPIO directos
| GPIO | Función(es) |
|---|---|
| 2 | BUZZER_PIN / BATTERY_ADC (hardcodeado) |
| 3 | TX_PIN (UART) / SUBGHZ_RX_PIN ⚠️ CONFLICTO |
| 4 | CSN_PIN_1 (NRF24 #1) |
| 5 | CC1101_CS / SD_CS_PIN ⚠️ CONFLICTO |
| 6 | RX_PIN (UART) / SUBGHZ_TX_PIN ⚠️ CONFLICTO |
| 7 | BACKLIGHT_PIN |
| 10 | SD_CS (primario) |
| 11 | SD_MOSI / CC1101_MOSI (SPI compartido OK) |
| 12 | SD_SCLK / CC1101_SCK (SPI compartido OK) |
| 13 | SD_MISO / CC1101_MISO (SPI compartido OK) |
| 14 | CE_PIN_3 (NRF24 #3) / IR_TX_PIN ⚠️ (documentado) |
| 15 | CE_PIN_1 (NRF24 #1) |
| 18 | XPT2046_CS (touch) |
| 21 | CSN_PIN_3 (NRF24 #3) / IR_RX_PIN ⚠️ (documentado) |
| 34 | BATTERY_ADC_PIN (definido pero NO EXISTE en S3) ⚠️ |
| 35 | XPT2046_MOSI |
| 36 | XPT2046_CLK |
| 37 | XPT2046_MISO |
| 38 | SD_CD (card detect) |
| 47 | CE_PIN_2 (NRF24 #2) |
| 48 | CSN_PIN_2 (NRF24 #2) |

---

## 5. Menú del Dispositivo

```
Main Menu
├── WiFi
│   ├── Packet Monitor
│   ├── Beacon Spammer
│   ├── WiFi Deauther
│   ├── Deauth Detector
│   ├── WiFi Scanner
│   └── Captive Portal
├── Bluetooth
│   ├── BLE Jammer
│   ├── BLE Spoofer
│   ├── Sour Apple
│   ├── BLE Sniffer
│   ├── BLE Scanner
│   └── BLE Rubber Ducky
├── 2.4GHz (NRF24)
│   ├── Scanner
│   ├── Analyzer [Coming soon]
│   ├── WLAN Jammer [Coming soon]
│   └── Proto Kill
├── SubGHz (CC1101)
│   ├── Replay Attack
│   ├── Bruteforce [Coming soon]
│   ├── SubGHz Jammer
│   └── Saved Profile
├── IR Remote
│   ├── Record
│   └── Saved Profile
├── Tools
│   ├── Serial Monitor
│   ├── Update Firmware
│   └── Touch Calibrate
├── Setting
│   └── (brightness, tema, neo, escaneo auto, calibración touch)
└── About
```

---

## 6. Sistema de Configuración

- **Archivo:** `/config/settings.json` en SD card
- **Biblioteca:** ArduinoJson (StaticJsonDocument<512>)
- **Campos:**
  - `brightness` (uint8_t, default=128)
  - `theme` (0=Dark, 1=Light)
  - `neopixelEnabled` (bool)
  - `autoWifiScan` / `autoBleScan` (bool, se sincronizan entre sí)
  - `touch.xMin/xMax/yMin/yMax` (calibración)
- **Nota:** Si autoWifiScan != autoBleScan al cargar, ambos se igualan al OR de los dos.

---

## 7. Tareas FreeRTOS en ejecución

| Tarea | Core | Stack | Prioridad | Función |
|---|---|---|---|---|
| `statusBar` | 0 | 2048 | 1 | Lee batería + SD cada 500ms |
| `wifiScanner` | — | — | — | Escaneo WiFi background |
| `bleScanner` | — | — | — | Escaneo BLE background |

---

## 8. BLE — Arquitectura

- Usa **NimBLE** (más ligero que BluedroidBLE)
- `BleCompat.h` expone aliases: `BLEDevice = NimBLEDevice`, etc.
- Features: Jammer (sweep canales), Spoofer (advertising fake), SourApple (ataque Apple),
  Sniffer, Scanner con background task, Rubber Ducky BLE HID

---

## 9. Problemas Críticos Identificados

### 9.1 API LEDC obsoleta (no compila en Arduino-ESP32 v3+)
```cpp
// ESP32-DIV.ino:2561-2562
ledcSetup(PWM_CHANNEL, PWM_FREQ, PWM_RESOLUTION);  // DEPRECATED
ledcAttachPin(BACKLIGHT_PIN, PWM_CHANNEL);           // DEPRECATED

// subghz.cpp:506-507
ledcSetup(BUZZER_LEDC_CH, 4000, 8);                 // DEPRECATED
ledcAttachPin(BUZZER_PIN, BUZZER_LEDC_CH);           // DEPRECATED
```
**Fix:** usar `ledcAttach(pin, freq, resolution)` + `ledcWrite(pin, duty)`

### 9.2 Classic Bluetooth — ESP32-S3 NO lo tiene
```cpp
// config.h:34-36 y bleconfig.h:13-15
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_bt_api.h"  // Solo BR/EDR, no existe en S3
```
**Fix:** guards `#if !defined(CONFIG_IDF_TARGET_ESP32S3)`

### 9.3 GPIO 34 no existe en ESP32-S3 + analogRead hardcodeado
```cpp
// shared.h:195
#define BATTERY_ADC_PIN 34   // GPIO 34-39 NO EXISTEN en ESP32-S3

// utils.cpp:354,364
#define BATTERY_PIN 2        // Definición local ignorada
sum += analogRead(2);        // Hardcodeado, ignora BATTERY_ADC_PIN
float pinVoltage = (averageADC / 4095.0) * 2.2;  // 2.2V hardcodeado
```
**Fix:** usar un GPIO ADC válido en S3 (≤ GPIO 20 para ADC1), usar la constante

### 9.4 SD_CS_PIN == CC1101_CS (mismo pin = conflicto real)
```cpp
// shared.h
#define SD_CS_PIN  5
#define CC1101_CS  5   // MISMO PIN

// El check en SettingsStore.cpp es incorrecto:
if (SD_CS_PIN != CC1101_CS) {          // false → nunca entra
    if (SD.begin(SD_CS_PIN)) { ... }
}
if (SD.begin(SD_CS_PIN)) { ... }       // se ejecuta de todas formas
```

### 9.5 Header deprecado en ESP-IDF 4.x+
```cpp
// wificonfig.h:24
#include "esp_event_loop.h"   // Eliminado en IDF 4.x+
```

### 9.6 settingsLoad() llamado dos veces en setup()
```cpp
// ESP32-DIV.ino:2549 y 2571 — llamada duplicada innecesaria
settingsLoad();
...
settingsLoad();
```

### 9.7 Serial.begin() repetido en múltiples módulos
- `ESP32-DIV.ino:2551`
- `wifi.cpp:609`
- `subghz.cpp:934`, `1715`, `2030`

### 9.8 Ternarios sin efecto en displaySubmenu()
```cpp
// ESP32-DIV.ino:248 — ambas ramas idénticas
tft.setTextColor(... ? UI_TEXT : UI_TEXT, UI_BG);
// ESP32-DIV.ino:278
tft.setTextColor(... ? UI_ICON : UI_ICON, UI_BG);
```

### 9.9 SPI.begin() con pines hardcodeados en bluetooth.cpp
```cpp
// bluetooth.cpp:1906 — pin 4 no es SD_CS (10) ni CC1101_CS (5)
SPI.begin(13, 11, 12, 4);
```

### 9.10 bleconfig.h redundante
`config.h` menciona ser el merge de bleconfig.h, pero bleconfig.h sigue
existiendo con contenido duplicado y los mismos headers problemáticos de Classic BT.

### 9.11 Strings XOR-obfuscados en shared.h
```cpp
static const uint8_t OBF_PN[] = {77, 91, 88, 59, ...};   // phone?
static const uint8_t OBF_DN[] = {75, 97, 110, 109, ...};  // domain?
static const uint8_t OBF_EM[] = {107, 97, ...};           // email?
static const uint8_t OBF_GH[] = {111, 97, ...};           // GitHub URL?
static const uint8_t OBF_WB[] = {75, 97, ...};            // website?
```
Innecesario en código open-source. Reduce transparencia.

---

## 10. Conflictos de Pines — Resumen

| GPIO | Uso 1 | Uso 2 | Documentado |
|---|---|---|---|
| 3 | TX_PIN (UART) | SUBGHZ_RX_PIN | No |
| 5 | SD_CS_PIN | CC1101_CS | Parcial (check incorrecto) |
| 6 | RX_PIN (UART) | SUBGHZ_TX_PIN | No |
| 14 | CE_PIN_3 (NRF24) | IR_TX_PIN | Sí (comentario) |
| 21 | CSN_PIN_3 (NRF24) | IR_RX_PIN | Sí (comentario) |
| 34 | BATTERY_ADC_PIN | No existe en S3 | No |

---

## 11. Dependencias / Librerías

- `TFT_eSPI` — Display
- `XPT2046_Touchscreen` — Touch
- `PCF8574` — Expansor I2C botones
- `NimBLE-Arduino` — BLE (vía BleCompat.h shim)
- `RF24` + `nRF24L01` — Radio 2.4GHz
- `ELECHOUSE_CC1101_SRC_DRV` — Radio Sub-GHz
- `RCSwitch` — Protocolos RF 433/868MHz
- `arduinoFFT` — Análisis espectral
- `ArduinoJson` — Configuración JSON
- `IRremoteESP8266` (implícito en ir.cpp)
- ESP-IDF nativo: `esp_wifi`, `nvs_flash`, `esp_event`

---

## 12. Prioridades de Fix Recomendadas

1. **CRÍTICO** — Migrar API LEDC a v3 (`ledcAttach`/`ledcWrite`)
2. **CRÍTICO** — Corregir `readBatteryVoltage()` — usar GPIO válido en S3 y la constante
3. **CRÍTICO** — Guards para Classic BT headers en S3
4. **ALTO** — Resolver conflicto SD_CS_PIN == CC1101_CS
5. **ALTO** — Corregir conflictos UART ↔ SubGHz pines 3/6
6. **MEDIO** — Eliminar `bleconfig.h` (redundante)
7. **MEDIO** — Quitar `esp_event_loop.h` (deprecated)
8. **BAJO** — Eliminar `settingsLoad()` duplicado
9. **BAJO** — Corregir ternarios sin efecto en displaySubmenu()
10. **BAJO** — Consolidar `Serial.begin()` en un solo lugar (setup principal)

---

*Auditoría generada por Claude Code — solo lectura, sin modificaciones al código fuente.*
