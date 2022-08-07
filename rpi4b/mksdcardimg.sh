#!/bin/sh
BOOT=./out/sdcard.img
\rm ${BOOT}
dd if=/dev/zero of=${BOOT} bs=1M count=0 seek=5120
parted -s ${BOOT} mklabel gpt
parted -s ${BOOT} unit s mkpart boot 8192 139263
parted -s ${BOOT} set 1 boot on
parted -s ${BOOT} -- unit s mkpart rootfs 139264 -34s
ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"
gdisk ${BOOT} <<EOF
x
c
2
${ROOT_UUID}
w
y
EOF
dd if=./out/boot.img of=${BOOT} seek=8192 conv=notrunc,fsync
dd if=./linaro-rootfs.img of=${BOOT} seek=139264 conv=notrunc,fsync
