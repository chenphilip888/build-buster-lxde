export BOARD=rk3328
export LB_BOOTSTRAP_INCLUDE="apt-transport-https gnupg"
export OUT=$(PWD)/out
export BOOT=$(OUT)/boot.img
export ARCH=arm64
export CROSS_COMPILE=/usr/local/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-

all: u-boot kernel rootfs mksdcardimg

cleanall:
	cd u-boot; \
	make clean
	cd kernel; \
	sudo make ARCH=arm64 clean
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
	--architectures arm64 \
	--archive-areas 'main contrib non-free' \
	--backports false \
	--binary-filesystem ext4 \
	--binary-images tar \
	--bootappend-live "hostname=linaro-alip username=linaro" \
	--bootstrap-qemu-arch arm64 \
	--bootstrap-qemu-static /usr/bin/qemu-aarch64-static \
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
	sudo lb build

postbuild:
	ARCH=arm64 $(PWD)/../mk-rootfs-buster.sh

mkimage:
	$(PWD)/../mk-image.sh

u-boot: cleanuboot builduboot postbuilduboot
kernel: buildkernel postbuildkernel

cleanuboot:
	\rm -f $(OUT)/idbloader.img
	\rm -f $(OUT)/rk3328_loader_ddr786_v1.06.243.bin
	\rm -f $(OUT)/trust.img
	\rm -f $(OUT)/uboot.img

builduboot:
	cd u-boot; \
	make clean; \
	make ARCH=arm64 roc-cc-rk3328_defconfig; \
	make all

postbuilduboot:
	cd u-boot; \
	../rkbin/tools/loaderimage --pack --uboot ./u-boot-dtb.bin uboot.img 0x200000; \
	./tools/mkimage -n rk3328 -T rksd -d ../rkbin/rk33/rk3328_ddr_786MHz_v1.06.bin idbloader.img; \
	cat ../rkbin/rk33/rk3328_miniloader_v2.43.bin >> idbloader.img; \
	cp idbloader.img ${OUT}/; \
	cp ../rkbin/rk33/rk3328_loader_ddr786_v1.06.243.bin ${OUT}/; \
	../rkbin/tools/trust_merger ../trust.ini; \
	cp uboot.img ${OUT}/; \
	cp trust.img ${OUT}/

buildkernel:
	cd kernel; \
	cp ../patches/fireflyrk3328_linux_defconfig arch/arm64/configs/; \
	cp ../patches/rk3328-roc-cc.dts arch/arm64/boot/dts/rockchip/; \
	cp ../patches/rk3328.dtsi arch/arm64/boot/dts/rockchip/; \
	cp ../patches/rk3328-box-plus-dram-timing.dtsi arch/arm64/boot/dts/rockchip/; \
	cp ../patches/rk3328-dram-default-timing.dtsi arch/arm64/boot/dts/rockchip/; \
	cp ../patches/Makefile arch/arm64/boot/dts/rockchip/; \
	make ARCH=arm64 clean; \
	make ARCH=arm64 fireflyrk3328_linux_defconfig; \
	make ARCH=arm64 all -j4; \
	sudo make ARCH=arm64 INSTALL_MOD_PATH=./tmp modules_install

postbuildkernel:
	cd kernel; \
	\rm -f $(BOOT); \
	mkfs.vfat -n "boot" -S 512 -C ${BOOT} 102400; \
	mmd -i ${BOOT} ::/extlinux; \
	mcopy -i ${BOOT} -s ../rk3328.conf ::/extlinux/extlinux.conf; \
	mcopy -i ${BOOT} -s ./arch/arm64/boot/Image ::; \
	mcopy -i ${BOOT} -s ./arch/arm64/boot/dts/rockchip/rk3328-roc-cc.dtb ::

mksdcardimg:
	./mksdcardimg.sh
