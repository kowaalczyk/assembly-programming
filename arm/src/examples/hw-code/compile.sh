#!/bin/bash

gcc -c hw-entry.c -o hw-entry.o

as hw-startup.s -o hw-startup.o

ld -T hw-boot.ld hw-entry.o hw-startup.o -o hw-boot.elf

objcopy -O binary hw-boot.elf hw-boot.bin

objdump -d hw-boot.elf
