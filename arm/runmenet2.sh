#!/bin/bash

# Start qemu on Linux with the image
qemu-system-arm \
-M versatilepb \
-kernel vmlinuz-2.6.26-2-versatile \
-initrd initrd.img-2.6.26-2-versatile \
-hda debian_lenny_arm_standard.qcow2 \
-append "root=/dev/sda1" \
-net nic,model=rtl8139 \
-net user,hostfwd=tcp::5555-:22 \
-nographic
