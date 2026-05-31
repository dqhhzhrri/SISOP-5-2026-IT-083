#!/bin/bash
# soal_1/iso.sh

mkdir -p osboot

echo "Mempersiapkan pembuatan ISO..."
mkdir -p iso_root/boot/grub

# Copy file ke dalam direktori virtual ISO
if [ -f "osboot/bzImage" ]; then
    cp osboot/bzImage iso_root/boot/
else
    echo "Peringatan: osboot/bzImage tidak ditemukan! Pastikan file kernel diletakkan di sana."
fi

if [ -f "osboot/single.gz" ]; then
    cp osboot/single.gz iso_root/boot/
fi

if [ -f "osboot/multi.gz" ]; then
    cp osboot/multi.gz iso_root/boot/
fi

# Konfigurasi GRUB Menu
cat << 'EOF' > iso_root/boot/grub/grub.cfg
set timeout=5
set default=1

menuentry "Farewell OS - Single User Mode" {
    linux /boot/bzImage console=ttyS0 quiet
    initrd /boot/single.gz
}

menuentry "Farewell OS - Multi User Mode" {
    linux /boot/bzImage console=ttyS0 quiet
    initrd /boot/multi.gz
}
EOF

# Build ISO
grub-mkrescue -o osboot/farewell.iso iso_root/ 2>/dev/null
rm -rf iso_root/
echo "Berhasil: osboot/farewell.iso telah dibuat!"
