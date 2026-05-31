#!/bin/bash
# soal_1/multi.sh

echo "Membuat Multi-User Filesystem..."
mkdir -p multi_fs/{bin,dev,proc,sys,etc,tmp,root}
mkdir -p multi_fs/home/{henn,hann,viii,kids}

# Download BusyBox
wget -q -nc -O multi_fs/bin/busybox https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
chmod +x multi_fs/bin/busybox
cd multi_fs
./bin/busybox --install -s ./bin

# --- FIX KERNEL PANIC (Konversi path absolut ke relatif) ---
for link in bin/*; do
    if [ -L "$link" ]; then
        ln -sf busybox "$link"
    fi
done
# -----------------------------------------------------------

# ----------------------------------------------------
# PEMENUHAN POIN 9: Package Manager 'party' (Turunan apk)
# ----------------------------------------------------
echo "Mengunduh package manager party..."
wget -q -O bin/party https://gitlab.alpinelinux.org/api/v4/projects/5/packages/generic/v2.14.0/x86_64/apk.static
chmod +x bin/party

# ----------------------------------------------------
# PEMENUHAN POIN 8: Network Configuration
# ----------------------------------------------------
# Setup default script untuk udhcpc agar IP/Route/DNS terpasang otomatis
mkdir -p usr/share/udhcpc
cat << 'EOF' > usr/share/udhcpc/default.script
#!/bin/sh
[ -z "$1" ] && echo "Error: should be called from udhcpc" && exit 1
RESOLV_CONF="/etc/resolv.conf"
case "$1" in
    deconfig)
        ifconfig $interface 0.0.0.0
        ;;
    renew|bound)
        ifconfig $interface $ip netmask $subnet
        if [ -n "$router" ] ; then
            # Hapus route default lama jika ada (abaikan error jika tidak ada)
            while route del default gw 0.0.0.0 dev $interface 2>/dev/null; do
                :
            done
            for i in $router ; do
                route add default gw $i dev $interface
            done
        fi
        echo -n > "$RESOLV_CONF"
        [ -n "$domain" ] && echo "search $domain" >> "$RESOLV_CONF"
        for i in $dns ; do
            echo "nameserver $i" >> "$RESOLV_CONF"
        done
        ;;
esac
exit 0
EOF
chmod +x usr/share/udhcpc/default.script
touch etc/resolv.conf

# ----------------------------------------------------
# PEMENUHAN POIN 4: Users, Groups & Passwords
# ----------------------------------------------------
# Setup struktur Group untuk membatasi akses direktori
cat << 'EOF' > etc/group
root:x:0:root
henngrp:x:1001:henn
hanngrp:x:1002:henn,hann
viiigrp:x:1003:henn,hann,viii
kidsgrp:x:1004:henn,hann,viii,kids
EOF

# Setup User Info
cat << 'EOF' > etc/passwd
root:x:0:0:root:/root:/bin/sh
henn:x:1001:1001:henn:/home/henn:/bin/sh
hann:x:1002:1002:hann:/home/hann:/bin/sh
viii:x:1003:1003:viii:/home/viii:/bin/sh
kids:x:1004:1004:kids:/home/kids:/bin/sh
EOF

# Generate Hash MD5 Password secara dinamis
ROOT_PW=$(openssl passwd -1 "root123")
HENN_PW=$(openssl passwd -1 "henn123")
HANN_PW=$(openssl passwd -1 "hann123")
VIII_PW=$(openssl passwd -1 "viii123")
KIDS_PW=$(openssl passwd -1 "kids123")

# Simpan Hash Password
cat << EOF > etc/shadow
root:${ROOT_PW}:19000:0:99999:7:::
henn:${HENN_PW}:19000:0:99999:7:::
hann:${HANN_PW}:19000:0:99999:7:::
viii:${VIII_PW}:19000:0:99999:7:::
kids:${KIDS_PW}:19000:0:99999:7:::
EOF

# Terapkan Aturan Izin Akses (Permissions)
chmod 755 .
chmod 1777 tmp
chmod 700 root

# Gunakan UID/GID numerik karena user tidak ada di sistem host
chown 1001:1001 home/henn && chmod 770 home/henn
chown 1002:1002 home/hann && chmod 770 home/hann
chown 1003:1003 home/viii && chmod 770 home/viii
chown 1004:1004 home/kids && chmod 770 home/kids

# ----------------------------------------------------
# PEMENUHAN BANNER LOGIN & INIT SCRIPT
# ----------------------------------------------------
cat << 'EOF' > etc/issue
  _____                               _ _   _____           _         
 |  ___|_ _ _ __ _____      _____  | | | |  _  |         | |        
 | |_ / _` | '__/ _ \ \ /\ / / _ \ | | | | | | |__ _ _ __| |_ _   _ 
 |  _| (_| | | |  __/\ V  V /  __/ | | | | | |/ _` | '__| __| | | |
 |_|  \__,_|_|  \___| \_/\_/ \___| |_|_| |_|  \__,_|_|  \__|\__, |
                                                             __/ |
                                                            |___/ 
EOF

cat << 'EOF' > etc/profile
cat /etc/issue
echo "Welcome, $(whoami)"
EOF

# Membuat Init untuk Multi-User
cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Menyalakan interface jaringan untuk koneksi internet (Poin 8)
ip link set lo up
ip link set eth0 up
udhcpc -i eth0 -q

# Menyalakan prompt login di terminal QEMU
# FIX: Gunakan /bin/getty karena /sbin tidak ada
exec /bin/getty -n -l /bin/login 115200 ttyS0
EOF

# --- FIX KERNEL PANIC & LOGIN ERROR ---
dos2unix init etc/group etc/passwd etc/shadow etc/issue etc/profile
# --------------------------------------

chmod +x init

find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../osboot/multi.gz
cd ..
rm -rf multi_fs
echo "Berhasil: osboot/multi.gz siap digunakan!"