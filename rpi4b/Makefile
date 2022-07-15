export BOARD=rpi4b
export LB_BOOTSTRAP_INCLUDE="apt-transport-https gnupg"
export KERNEL=kernel7l
export OUT=$(PWD)/out
export BOOT=$(OUT)/boot.img
export ARCH=arm
export CROSS_COMPILE=/usr/local/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-

all: kernel rootfs mksdcardimg

cleanall:
	cd linux; \
	sudo make ARCH=arm clean
	sudo lb clean --purge
	\rm -rf config
	\rm -rf config linaro-rootfs.img

rootfs: clean prebuild buildrootfs postbuild mkimage

clean:
	sudo lb clean --purge
	\rm -rf config

prebuild:
	lb config \
	--apt-indices false \
	--apt-recommends false \
	--apt-secure false \
	--architectures armhf \
	--archive-areas 'main contrib non-free' \
	--backports false \
	--binary-filesystem ext4 \
	--binary-images tar \
	--bootappend-live "hostname=linaro-alip username=linaro" \
	--bootstrap-qemu-arch armhf \
	--bootstrap-qemu-static /usr/bin/qemu-arm-static \
	--cache false \
	--chroot-filesystem none \
	--compression gzip \
	--debootstrap-options "--variant=minbase --include=apt-transport-https,gnupg" \
	--distribution buster \
	--gzip-options '-9 --rsyncable' \
	--iso-publisher 'Linaro; http://www.linaro.org/; linaro-dev@lists.linaro.org' \
	--iso-volume 'Linaro Buster $(date +%Y%m%d-%H:%M)' \
	--linux-flavours none \
	--linux-packages none \
	--mode debian \
	--security true \
	--system normal \
	--updates true

buildrootfs:
	\cp -rf $(PWD)/../customization/* config/
	\cp $(PWD)/../linaro-list-armhf config/package-lists/linaro.list.chroot
	sudo lb build

postbuild:
	ARCH=armhf $(PWD)/../mk-rootfs-buster.sh

mkimage:
	$(PWD)/../mk-image.sh

kernel: buildkernel postbuildkernel

buildkernel:
	cd linux; \
	cp ../patches/bcm2711_defconfig arch/arm/configs/; \
	make ARCH=arm clean; \
	make ARCH=arm bcm2711_defconfig; \
	make ARCH=arm all -j4; \
	sudo make ARCH=arm INSTALL_MOD_PATH=./tmp modules_install

postbuildkernel:
	cd linux; \
	\rm -f $(BOOT); \
	mkfs.vfat -n "boot" -S 512 -C ${BOOT} 256000; \
	mmd -i ${BOOT} ::/overlays; \
	mcopy -i ${BOOT} -s ../firmware/fixup4.dat ::; \
	mcopy -i ${BOOT} -s ../firmware/start4.elf ::; \
	mcopy -i ${BOOT} -s ../firmware/bootcode.bin ::; \
	mcopy -i ${BOOT} -s ../firmware/cmdline.txt ::; \
	mcopy -i ${BOOT} -s ../firmware/config.txt ::; \
	mcopy -i ${BOOT} -s ./arch/arm/boot/Image ::/kernel7l.img; \
	mcopy -i ${BOOT} -s ./arch/arm/boot/dts/bcm2711-rpi-4-b.dtb ::; \
	mcopy -i ${BOOT} -s ./arch/arm/boot/dts/overlays/*.dtb* ::/overlays; \
	mcopy -i ${BOOT} -s ./arch/arm/boot/dts/overlays/README ::/overlays

mksdcardimg:
	./mksdcardimg.sh
