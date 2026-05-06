# cifertech — ESP32-DIV v1.5.0
### Auditoría Completa del Firmware
**Fecha:** 2026-05-06 | **Repo original:** github.com/cifertech/ESP32-DIV | **Target:** ESP32-S3 WROOM

---

## 1. ¿Qué es este proyecto?

**cifertech ESP32-DIV** es un dispositivo de pentesting/seguridad portátil basado en ESP32-S3,
con pantalla táctil TFT 240×320, botones físicos por expansor I2C PCF8574, y múltiples radios.
El repo del usuario `tovazmx/ESP32-DIV` es una copia exacta (mismos commits, mismos archivos).

---

## 2. Estructura de Archivos

| Archivo | Líneas | Función |
|---|---|---|
| `ESP32-DIV.ino` | 2607 | Main: setup, loop, sistema de menús |
| `bluetooth.cpp` | 2869 | BLE jammer, spoofer, SourApple, sniffer, scanner, NRF24 |
| `wifi.cpp` | 5055 | Packet monitor, beacon spam, deauther, captive portal |
| `subghz.cpp` | 2152 | Replay attack, jammer, perfiles CC1101 |
| `ir.cpp` | 1598 | IR record y replay |
| `ducky.cpp` | 1374 | BLE Rubber Ducky HID |
| `utils.cpp` | 1483 | Status bar, batería, SD card, UI, terminal |
| `KeyboardUI.cpp` | 220 | Teclado táctil en pantalla |
| `SettingsStore.cpp` | 112 | Config JSON en SD card |
| `Theme.cpp` | 29 | Paleta de colores (Dark/Light) |
| `Touchscreen.cpp` | 28 | Init XPT2046 |
| `shared.h` | 326 | Pines, colores, constantes globales |
| `config.h` | 133 | Includes centralizados + namespaces |
| `BleCompat.h` | 14 | Shim NimBLE → BLEDevice API |
| `icon.h` | 1463 | Bitmaps de iconos |

---

## 3. Menú Completo

```
cifertech ESP32-DIV v1.5.0
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
│   ├── Analyzer [WIP]
│   ├── WLAN Jammer [WIP]
│   └── Proto Kill
├── SubGHz (CC1101)
│   ├── Replay Attack
│   ├── Bruteforce [WIP]
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
└── About
```

---

## 4. Mapa de Pines

### PCF8574 I2C (expansor — NO son GPIO del ESP32)
| Pin | Botón |
|---|---|
| 3 | BTN_LEFT |
| 4 | BTN_RIGHT |
| 5 | BTN_DOWN |
| 6 | BTN_SELECT |
| 7 | BTN_UP |

### ESP32-S3 GPIO directos
| GPIO | Uso principal | Conflicto |
|---|---|---|
| 2 | BUZZER_PIN / BATTERY_ADC (hardcodeado) | Ambos en mismo pin |
| 3 | TX_PIN UART | SUBGHZ_RX_PIN |
| 4 | CSN_PIN_1 NRF24 #1 | — |
| 5 | CC1101_CS | SD_CS_PIN (MISMO PIN) |
| 6 | RX_PIN UART | SUBGHZ_TX_PIN |
| 7 | BACKLIGHT_PIN PWM | — |
| 10 | SD_CS (primario) | — |
| 11 | SD_MOSI / CC1101_MOSI | SPI compartido (OK) |
| 12 | SD_SCLK / CC1101_SCK | SPI compartido (OK) |
| 13 | SD_MISO / CC1101_MISO | SPI compartido (OK) |
| 14 | CE_PIN_3 NRF24 #3 | IR_TX_PIN |
| 15 | CE_PIN_1 NRF24 #1 | — |
| 18 | XPT2046_CS | — |
| 21 | CSN_PIN_3 NRF24 #3 | IR_RX_PIN |
| 34 | BATTERY_ADC_PIN (definido) | NO EXISTE en ESP32-S3 |
| 35 | XPT2046_MOSI | — |
| 36 | XPT2046_CLK | — |
| 37 | XPT2046_MISO | — |
| 38 | SD_CD (card detect) | — |
| 47 | CE_PIN_2 NRF24 #2 | — |
| 48 | CSN_PIN_2 NRF24 #2 | — |

---

## 5. Estado de Componentes — Diagnóstico

| Componente | Estado | Razón |
|---|---|---|
| TFT Display | ✅ OK | Init correcto, rotación configurada |
| XPT2046 Touch | ✅ OK | HSPI separado, calibración auto |
| PCF8574 Botones | ✅ OK | I2C 0x20, INPUT_PULLUP configurado |
| SD Card | ⚠️ INESTABLE | CS=10 funciona, pero SD_CS_PIN=5 conflicta con CC1101 |
| CC1101 Sub-GHz | ⚠️ INESTABLE | CS=5 comparte pin con SD_CS_PIN |
| NRF24 #1 | ⚠️ REVISAR | SPI.begin(13,11,12,4) hardcodeado en bluetooth.cpp:1906 |
| IR TX/RX | ⚠️ REVISAR | GPIO 14/21 comparten con NRF24 #3 |
| Backlight | ⚠️ API OBSOLETA | ledcSetup/ledcAttachPin no funciona en Arduino-ESP32 v3+ |
| Buzzer | ⚠️ API OBSOLETA | Mismo problema LEDC + comparte GPIO 2 con batería |
| Batería ADC | ❌ ROTO | Lee analogRead(2) hardcodeado; BATTERY_ADC_PIN=34 no existe en S3 |
| LoRa | ❌ SIN SOPORTE | No existe en el firmware cifertech — cero código |

---

## 6. Problemas Críticos del Código

### 6.1 API LEDC obsoleta (no compila en Arduino-ESP32 v3+)
```cpp
// ESP32-DIV.ino:2561-2562
ledcSetup(PWM_CHANNEL, PWM_FREQ, PWM_RESOLUTION);  // DEPRECATED
ledcAttachPin(BACKLIGHT_PIN, PWM_CHANNEL);           // DEPRECATED
// Fix: ledcAttach(BACKLIGHT_PIN, PWM_FREQ, PWM_RESOLUTION)
//      ledcWrite(BACKLIGHT_PIN, value)
```

### 6.2 Batería — pin incorrecto + GPIO inválido en S3
```cpp
// utils.cpp:364
sum += analogRead(2);           // GPIO 2 = buzzer, NO es ADC de batería
// shared.h:195
#define BATTERY_ADC_PIN 34      // GPIO 34-39 NO existen en ESP32-S3
// Fix: usar GPIO ≤20 para ADC1 en S3 y usar analogRead(BATTERY_ADC_PIN)
```

### 6.3 Classic Bluetooth headers — ESP32-S3 no lo tiene
```cpp
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_bt_api.h"   // BR/EDR solo, S3 no tiene
// Fix: #if !defined(CONFIG_IDF_TARGET_ESP32S3)
```

### 6.4 SD_CS_PIN == CC1101_CS (conflicto real)
```cpp
#define SD_CS_PIN  5
#define CC1101_CS  5   // MISMO PIN — uno anula al otro
```

### 6.5 Header deprecado
```cpp
#include "esp_event_loop.h"   // Eliminado en ESP-IDF 4.x+
```

### 6.6 Otros menores
- `settingsLoad()` llamado 2 veces en setup()
- `Serial.begin()` repetido en wifi.cpp, subghz.cpp x3
- Ternarios sin efecto en displaySubmenu() líneas 248/278
- `bleconfig.h` redundante (duplica config.h)

---

## 7. LoRa — No existe en cifertech

El firmware cifertech ESP32-DIV **no tiene ningún soporte de LoRa**.
Cero archivos, cero librerías, cero pines asignados.
Si el ESP32-S3 tiene módulos LoRa soldados (SX1276/SX1278/SX1262),
necesitan código nuevo — no están en este firmware.

---

## 8. Dependencias / Librerías

- `TFT_eSPI` — Display
- `XPT2046_Touchscreen` — Touch
- `PCF8574` — Expansor botones
- `NimBLE-Arduino` — BLE
- `RF24` + `nRF24L01` — 2.4GHz
- `ELECHOUSE_CC1101_SRC_DRV` — Sub-GHz
- `RCSwitch` — RF 433/868MHz
- `arduinoFFT` — Análisis espectral
- `ArduinoJson` — Config JSON
- ESP-IDF nativo: `esp_wifi`, `nvs_flash`, `esp_event`

---

## 9. FreeRTOS Tasks

| Task | Core | Stack | Intervalo |
|---|---|---|---|
| `statusBar` | 0 | 2048 B | 500ms |
| `wifiScanner` | — | — | background |
| `bleScanner` | — | — | background |

---

*Auditoría: solo lectura. Repo: github.com/cifertech/ESP32-DIV v1.5.0*
