# ARM assembly

Setup:

1. Install `qemu`
2. Download files from [course website](https://students.mimuw.edu.pl/~zbyszek/asm/qemu) to the `vm` folder:
   - `debian_lenny_arm_standard.qcow2`
   - `initrd.img-2.6.26-2-versatile`
   - `vmlinuz-2.6.26-2-versatile`
3. Start the VM (may take a while, wait until you see root login prompt):
```bash
# host
qemu-system-arm \
-M versatilepb \
-kernel vm/vmlinuz-2.6.26-2-versatile \
-initrd vm/initrd.img-2.6.26-2-versatile \
-hda vm/debian_lenny_arm_standard.qcow2 \
-append "root=/dev/sda1" \
-net nic,model=rtl8139 \
-net user,hostfwd=tcp::5555-:22 \
-nographic
```
4. Login using user: `root`, password: `root`
5. **[OPTIONAL & INSECURE]** This image is very old and can fail to download packages because of expired keys.
   Run the following to disable `apt-get` security key checks:
```bash
# vm
echo 'deb http://archive.debian.org/debian/ lenny allow-insecure=yes main' > /etc/apt/sources.list
apt-get --allow-unauthenticated upgrade
```
6. Create a directory for source files on the VM: `cd ~ && mkdir src`
7. **[OPTIONAL]** On your local machine, add vm to the ssh config (remember to use tabs in that file):
```bash
# host: ~/.ssh/config
Host pwa-arm-dev
        HostName localhost
        Port 5555
        User root
        PasswordAuthentication yes
```
8. **[OPTIONAL]** Copy public key to the VM to login without password:
```bash
# host
ssh-copy-id -p 5555 root@localhost
# you'll need to use 'root' password when promped
```
9. **[OPTIONAL]** Copy source files from host to VM:
```bash
# host
scp -r ./src pwa-arm-dev:~
```
10. **[OPTIONAL]** Copy source files from host to VM:


## Useful commands

Start VM:
```bash
qemu-system-arm \
-M versatilepb \
-kernel vm/vmlinuz-2.6.26-2-versatile \
-initrd vm/initrd.img-2.6.26-2-versatile \
-hda vm/debian_lenny_arm_standard.qcow2 \
-append "root=/dev/sda1" \
-net nic,model=rtl8139 \
-net user,hostfwd=tcp::5555-:22 \
-nographic
```

Copy contents of src folder to the current folder to vm:
```bash
scp -r ./src pwa-arm-dev:~
```


##