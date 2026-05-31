#!/bin/bash
# soal_1/single.sh

echo "Membuat Single-User Filesystem..."
mkdir -p single_fs/{bin,dev,proc,sys,etc,tmp,root}

# Download BusyBox statis
wget -q -nc -O single_fs/bin/busybox https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
chmod +x single_fs/bin/busybox

cd single_fs
./bin/busybox --install -s ./bin

# --- FIX KERNEL PANIC (Konversi path absolut ke relatif) ---
for link in bin/*; do
    if [ -L "$link" ]; then
        ln -sf busybox "$link"
    fi
done
# -----------------------------------------------------------

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

# Membuat script inisialisasi booting
cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Menyalakan interface jaringan untuk koneksi internet
echo "Initializing Network..."
ip link set lo up
ip link set eth0 up
udhcpc -i eth0 -n -q

echo "Welcome to Single User Mode"
# Masuk langsung sebagai root tanpa password
# FIX: Gunakan setsid -c untuk job control
exec setsid -c /bin/sh
EOF

# --- FIX KERNEL PANIC (Konversi format Windows ke Linux murni) ---
dos2unix init usr/share/udhcpc/default.script
# -----------------------------------------------------------------

chmod +x init

# Melakukan kompresi menjadi format cpio.gz
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../osboot/single.gz
cd ..
rm -rf single_fs
echo "Berhasil: osboot/single.gz siap digunakan!"