#!/bin/bash
# soal_1/qemu.sh

if [ "$1" == "--single" ]; then
    qemu-system-x86_64 -kernel osboot/bzImage -initrd osboot/single.gz -append "console=ttyS0 quiet" -nographic -m 512M -netdev user,id=n1 -device e1000,netdev=n1
elif [ "$1" == "--multi" ]; then
    qemu-system-x86_64 -kernel osboot/bzImage -initrd osboot/multi.gz -append "console=ttyS0 quiet" -nographic -m 512M -netdev user,id=n1 -device e1000,netdev=n1
elif [ "$1" == "--all" ]; then
    qemu-system-x86_64 -cdrom osboot/farewell.iso -nographic -m 512M -netdev user,id=n1 -device e1000,netdev=n1
else
    echo "Usage: ./qemu.sh [--single | --multi | --all]"
fi