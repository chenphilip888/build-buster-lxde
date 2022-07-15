#!/bin/sh
BOOT=./out/sdcard.img
\rm ${BOOT}
dd if=/dev/zero of=${BOOT} bs=1M count=0 seek=5120
parted -s ${BOOT} mklabel gpt
parted -s ${BOOT} unit s mkpart loader1 64 8063
parted -s ${BOOT} unit s mkpart loader2 16384 24575
parted -s ${BOOT} unit s mkpart trust 24576 32767
parted -s ${BOOT} unit s mkpart boot 32768 1081343
parted -s ${BOOT} set 4 boot on
parted -s ${BOOT} -- unit s mkpart rootfs 1081344 -34s
ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"
gdisk ${BOOT} <<EOF
x
c
5
${ROOT_UUID}
w
y
EOF
dd if=./out/idbloader.img of=${BOOT} seek=64 conv=notrunc,fsync
dd if=./out/uboot.img of=${BOOT} seek=16384 conv=notrunc,fsync
dd if=./out/trust.img of=${BOOT} seek=24576 conv=notrunc,fsync
dd if=./out/boot.img of=${BOOT} seek=32768 conv=notrunc,fsync
dd if=./linaro-rootfs.img of=${BOOT} seek=1081344 conv=notrunc,fsync
