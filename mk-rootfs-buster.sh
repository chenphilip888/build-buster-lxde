#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

if [ -e $TARGET_ROOTFS_DIR ]; then
	sudo rm -rf $TARGET_ROOTFS_DIR
fi

if [ "$ARCH" == "armhf" ]; then
	ARCH='armhf'
elif [ "$ARCH" == "arm64" ]; then
	ARCH='arm64'
else
    echo -e "\033[36m please input is: armhf or arm64...... \033[0m"
fi

if [ ! $VERSION ]; then
	VERSION="release"
fi

if [ ! -e live-image-$ARCH.tar.tar.gz ]; then
	echo "\033[36m Run sudo lb build first \033[0m"
fi

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

echo -e "\033[36m Extract image \033[0m"
sudo tar -xpf live-image-$ARCH.tar.tar.gz

if [ "$BOARD" == "radxa" ]; then
sudo cp -rf ./kernel/tmp/lib/modules $TARGET_ROOTFS_DIR/lib
sudo cp -rf ./kernel/tmp/lib/firmware $TARGET_ROOTFS_DIR/lib
elif [ "$BOARD" == "rpi4b" ]; then
sudo cp -rf ./linux/tmp/lib/modules $TARGET_ROOTFS_DIR/lib
elif [ "$BOARD" == "rk3328" ]; then
sudo cp -rf ./kernel/tmp/lib/modules $TARGET_ROOTFS_DIR/lib
elif [ "$BOARD" == "tinker" ]; then
sudo cp -rf ./debian_kernel/tmp/lib/modules $TARGET_ROOTFS_DIR/lib
fi

# packages folder
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rf ../packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

# overlay folder
sudo cp -rf ../overlay/* $TARGET_ROOTFS_DIR/

echo -e "\033[36m Change root.....................\033[0m"
if [ "$ARCH" == "armhf" ]; then
	sudo cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
elif [ "$ARCH" == "arm64"  ]; then
	sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
fi
sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

ln -sf /etc/resolvconf/run/resolv.conf /etc/resolv.conf
resolvconf -u
apt-get update
apt-get upgrade -y
apt-get install -y build-essential git libssl-dev nmap net-tools libncurses5-dev libncursesw5-dev dnsutils vsftpd ftp libjpeg-dev scons libncurses5-dev libncursesw5-dev libdbus-glib-1-dev libbluetooth-dev python-dev python-setuptools python3-dev python3-pip python3-setuptools fonts-arphic-ukai fonts-arphic-uming firefox-esr libx11-dev libpng-dev mpg123 libudev-dev flex bison pulseaudio pulseaudio-utils vlc vlc-plugin-fluidsynth fluid-soundfont-gs fluid-soundfont-gm speedtest-cli meson libdrm-dev libwayland-dev wayland-protocols libwayland-egl-backend-dev libxcb-dri3-dev libxcb-dri2-0-dev libxcb-glx0-dev libx11-xcb-dev libxcb-present-dev libxcb-sync-dev libxxf86vm-dev libxshmfence-dev libxrandr-dev libwayland-dev libxdamage-dev libxext-dev libxfixes-dev x11proto-dri2-dev x11proto-dri3-dev x11proto-present-dev x11proto-gl-dev x11proto-xf86vidmode-dev libexpat1-dev libudev-dev gettext mesa-utils xutils-dev libpthread-stubs0-dev ninja-build bc cmake valgrind llvm python3-pip pkg-config zlib1g-dev libxcb-shm0-dev

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local

if [ "$BOARD" != "rpi4b" ]; then
dpkg -i /packages/xserver/*.deb
apt-get install -f -y
apt-get install -y libinput-bin libinput10 xserver-xorg-input-all xserver-xorg-input-libinput
fi

if [ "$BOARD" == "radxa" ]; then
#------------------rkwifibt------------
echo -e "\033[36m Install rkwifibt.................... \033[0m"
dpkg -i  /packages/rkwifibt/*.deb
apt-get install -f -y
mkdir /vendor
mkdir /vendor/etc
ln -sf /system/etc/firmware /vendor/etc/
elif [ "$BOARD" == "rpi4b" ]; then
#------------------rpiwifi-------------
echo -e "\033[36m Install rpiwifi..................... \033[0m"
dpkg -i /packages/rpiwifi/firmware-brcm80211_20190114-2_all.deb
cp /packages/rpiwifi/brcmfmac43455-sdio.txt /lib/firmware/brcm/
apt-get install -f -y
fi

systemctl enable rockchip.service
systemctl enable resize-helper

#---------------Clean--------------
rm -rf /var/lib/apt/lists/*

EOF

sudo umount $TARGET_ROOTFS_DIR/dev
