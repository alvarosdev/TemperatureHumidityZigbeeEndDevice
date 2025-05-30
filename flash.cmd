@echo off
cd .\build\esp32.esp32.esp32c6 
python -m esptool --chip esp32c6 --baud 460800 write_flash 0x0 .\main.ino.bootloader.bin 0x8000 .\main.ino.partitions.bin 0x10000 .\main.ino.bin

