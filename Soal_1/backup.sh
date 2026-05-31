#!/bin/bash
# soal_1/backup.sh

TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
ZIP_NAME="farewell_backup_${TIMESTAMP}.zip"

# Masuk ke folder osboot untuk mempermudah zipping tanpa path panjang
cd osboot

echo "Membuat arsip backup..."
zip -r "$ZIP_NAME" bzImage single.gz multi.gz farewell.iso

echo "Menghapus file asli..."
rm bzImage single.gz multi.gz farewell.iso

cd ..
echo "Backup Selesai: osboot/$ZIP_NAME"