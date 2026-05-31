#!/bin/bash
# soal_1/kernel.sh

mkdir -p osboot

echo "Downloading Linux Kernel 6.1.1..."
wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.1.tar.xz

echo "Menghapus folder lama dan mengekstrak ulang..."
rm -rf linux-6.1.1
tar -xf linux-6.1.1.tar.xz

cd linux-6.1.1
echo "Membersihkan sisa build..."
make clean

echo "Configuring kernel..."
make defconfig

# PEMENUHAN POIN 2: Custom Kernel Name
sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION = -farewell/' Makefile

# --- FIX UNTUK WSL & UBUNTU ---
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
scripts/config --disable CONFIG_DEBUG_INFO
scripts/config --disable CONFIG_DEBUG_INFO_BTF
scripts/config --disable CONFIG_DRM
scripts/config --enable CONFIG_FUSE_FS
scripts/config --disable CONFIG_WERROR
# ------------------------------

# Terapkan konfigurasi
make olddefconfig

echo "Compiling kernel (Menggunakan 2 core)..."
make -j2

echo "Copying bzImage to osboot..."
cp arch/x86/boot/bzImage ../osboot/bzImage
cd ..
echo "Kernel compile done!"
