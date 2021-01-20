#!/bin/bash

# Start qemu without the image
qemu-system-arm -M versatilepb -kernel qemuboot.bin
