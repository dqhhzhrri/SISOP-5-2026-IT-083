 # SISOP-5-2026-IT-083

  ## Profil Mahasiswa
  Nama           : D'Qhaizhar Ari Dhiaulhaq

  NRP            : 5027251083

  Departemen     : Teknologi Informasi

  ## Laporan Penyelesaian Soal Praktikum Modul 5
  Repository ini berisi source code dan penjelasan mengenai penyelesaian soal Praktikum Modul 5 untuk mata kuliah Sistem Operasi. Modul ini berfokus pada
  Operating System & Bootloaders, termasuk kompilasi Kernel Linux secara kustom dan pembuatan sistem file (initramfs) menggunakan BusyBox.

  ## Problem Keseluruhan
  Dalam penyelesaian modul ini, saya menggunakan bantuan Gemini AI sebagai partner diskusi utama untuk memecahkan masalah teknis terkait kernel panic,
  manajemen symlink pada initramfs, dan konfigurasi jaringan pada emulator QEMU. Bantuan AI sangat krusial dalam mendiagnosa pesan error kernel yang cukup
  kompleks.

  Gemini AI : Link Percakapan (https://gemini.google.com/share/b0347306-9170-42d1-b48d-1ec06b7ecf83) (Ganti dengan link share Anda)

  ## Soal 1
  Pada soal ini, saya menggunakan berbagai perintah dasar dan lanjut seperti make, cpio, wget, fakeroot, sed, dos2unix, dan qemu-system-x86_64.

  ### Problem Soal 1
  Pada penyelesaian soal 1, saya menghadapi beberapa masalah kritis:
   1. Kernel Panic: Muncul pesan Kernel panic - not syncing: No working init found karena BusyBox menginstal symlink dengan absolute path yang merujuk ke
      folder host, sehingga tidak ditemukan saat booting di dalam QEMU.
   2. TTY Access: Pesan /bin/sh: can't access tty; job control turned off yang menyebabkan shell tidak stabil.
   3. Network Unreachable: Perintah ping dan wget gagal karena absennya default script untuk udhcpc, sehingga IP dan DNS tidak terkonfigurasi secara
      otomatis meski lease sudah didapatkan.
   4. Package Manager Gagal: Link download apk-tools yang diberikan sudah tidak aktif (404 Not Found).

  ### Penyelesaian Soal 1

  1. Kompilasi Kernel (kernel.sh)
  Pertama, saya mengunduh source code Linux Kernel 6.1.1 dan melakukan konfigurasi menggunakan make defconfig. Saya mengubah nama kernel menggunakan sed
  pada Makefile untuk menambahkan identitas -farewell (Poin 2).
```sh
   1 # Potongan kode modifikasi Makefile
   2 sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION = -farewell/' Makefile
```

  2. Pembuatan Filesystem Single-User (single.sh)
  Saya membuat struktur direktori dasar dan mengunduh BusyBox statis. Untuk mengatasi Kernel Panic, saya menambahkan logika untuk mengubah semua absolute
  symlink menjadi relative symlink.

```sh
   1 # Solusi agar init ditemukan (Relative Symlink)
   2 for link in bin/*; do
   3     if [ -L "$link" ]; then
   4         ln -sf busybox "$link"
   5     fi
   6 done
```

  3. Konfigurasi Jaringan & Init Script
  Untuk mengatasi masalah jaringan, saya membuat file /usr/share/udhcpc/default.script yang berfungsi untuk memasang IP, Route, dan DNS secara otomatis saat
  booting. Saya juga menggunakan setsid -c agar shell mendapatkan akses TTY yang benar.

```sh
    1 # Init script dengan fix TTY dan Network
    2 cat << 'EOF' > init
    3 #!/bin/sh
    4 mount -t proc none /proc
    5 mount -t sysfs none /sys
    6 mount -t devtmpfs none /dev
    7
    8 ip link set lo up
    9 ip link set eth0 up
   10 udhcpc -i eth0 -n -q
   11
   12 echo "Welcome to Single User Mode"
   13 exec setsid -c /bin/sh
   14 EOF
```

  4. Pembuatan Filesystem Multi-User (multi.sh)
  Pada mode ini, saya menambahkan pembuatan user (henn, hann, viii, kids) dan group. Saya menggunakan fakeroot saat menjalankan script agar kepemilikan file
  (UID/GID) tersimpan dengan benar di dalam file .gz meskipun dijalankan tanpa akses root di host.

  !Image Link (Assets/multi_user_boot.png) (Contoh placeholder gambar)

  5. Menjalankan Emulator (qemu.sh)
  Terakhir, saya menjalankan sistem menggunakan QEMU dengan parameter -kernel dan -initrd yang telah dibuat.

  !Image Link (Assets/qemu_success.png) (Contoh placeholder gambar)

  Meskipun ping terkadang gagal karena keterbatasan User-mode Networking pada QEMU, koneksi internet berhasil dibuktikan dengan DNS yang mampu melakukan
  resolving domain (seperti google.com) dan akses via wget.
