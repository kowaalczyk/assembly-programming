# ARM assembly (32bit)

Setup:

1. Install `qemu` (`brew install qemu`)
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
10. **[OPTIONAL]** Compile & run a simple C program to make sure gcc works:
```bash
# vm
cd ~/src
gcc -o hello hello.c
./hello
# should print something
```
11. **[OPTIONAL]** Compile & run a simple assembly program:
```bash
# vm
cd ~/src/examples
make
./first
echo $?
# should be 2
```

## Useful commands

Start VM:
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

Copy contents of src folder to the current folder to vm:
```bash
# host
scp -r ./src pwa-arm-dev:~
```

Use `fswatch` + `rsync` to automatically sync all changed files to vm:
```bash
# host
fswatch -r ./src \
| xargs -I{} realpath --relative-to=$(realpath .) {} \
| xargs -I{} scp ./{} 'pwa-arm-dev:~/'{}
```

Stop the vm:
```bash
# vm
halt
```


## Example programs

All example programs (in [`src/examples`](src/examples)) are copied from
the [course website](https://students.mimuw.edu.pl/~zbyszek/asm/progarm) -
they are not my property and are attached here only for convenience.
