#!/bin/bash
# Flash ESP32-DIV cifertech firmware
# Conecta el ESP32-S3 y corre: bash FLASH.sh /dev/ttyUSB0
# (cambia /dev/ttyUSB0 por tu puerto — puede ser /dev/ttyACM0 en Linux o COM3 en Windows)

PORT="${1:-/dev/ttyUSB0}"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Flasheando en $PORT..."
esptool.py --chip esp32s3 --port "$PORT" --baud 921600 \
  --before default_reset --after hard_reset write_flash \
  -z --flash_mode dio --flash_freq 80m --flash_size 4MB \
  0x0000  "$DIR/ESP32-DIV.ino.bootloader.bin" \
  0x8000  "$DIR/ESP32-DIV.ino.partitions.bin" \
  0x10000 "$DIR/ESP32-DIV.ino.bin"

echo "Listo. Reinicia el dispositivo."
