# Create an image that can be written onto a SD card using dd.

inherit image_types

# Use an uncompressed ext4 by default as rootfs
IMG_ROOTFS_TYPE = "ext4"
IMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}.${IMG_ROOTFS_TYPE}"

# This image depends on the rootfs image
IMAGE_TYPEDEP_rockpi3-gpt-img = "${IMG_ROOTFS_TYPE}"

GPTIMG = "${IMAGE_BASENAME}-${MACHINE}-gpt.img"
BOOT_IMG = "${IMAGE_BASENAME}-${MACHINE}-boot.img"
IDBLOADER = "idbloader.img"

# Get From radxa-binary loader
DDR_BIN = "radxa-binary/ddr.bin"
LOADER_BIN = "radxa-binary/loader.bin"
MINILOADER_BIN = "radxa-binary/miniloader.bin"
ATF_BIN = "radxa-binary/atf.bin"
BL31_ELF = "radxa-binary/bl31.elf"
TRUST_IMG = "trust.img"
# Not from radxa-binary
UBOOT_IMG = "u-boot.img"
UBOOT_ITB = "u-boot.itb"

GPTIMG_APPEND_rk3568 = "earlyprintk console=ttyFIQ0,1500000n8 rw root=PARTUUID=614e0000-0000-4b53-8000-1d28000054a9 rootfstype=ext4 init=/sbin/init rootwait"
ROOT_UUID_rk3568 = "614e0000-0000-4b53-8000-1d28000054a9"
# default partitions [in Sectors]
# More info at http://rockchip.wikidot.com/partitions
LOADER1_SIZE = "8000"
RESERVED1_SIZE = "128"
RESERVED2_SIZE = "8192"
LOADER2_SIZE = "8192"
ATF_SIZE = "8192"
BOOT_SIZE = "1048576"

# WORKROUND: miss recipeinfo
do_image_rockpi3_gpt_img[depends] += " \
	radxa-binary-loader:do_populate_lic \
	virtual/bootloader:do_populate_lic"

do_image_rockpi3_gpt_img[depends] += " \
	parted-native:do_populate_sysroot \
	mtools-native:do_populate_sysroot \
	gptfdisk-native:do_populate_sysroot \
	dosfstools-native:do_populate_sysroot \
	radxa-binary-native:do_populate_sysroot \
	radxa-binary-loader:do_deploy \
	virtual/kernel:do_deploy \
	virtual/bootloader:do_deploy"

PER_CHIP_IMG_GENERATION_COMMAND_rk3568 = "generate_rk3568_loader_image"

IMAGE_CMD_rockpi3-gpt-img () {
	# Change to image directory
	cd ${DEPLOY_DIR_IMAGE}

	# Remove the existing image
	rm -f "${GPTIMG}"
	rm -f "${BOOT_IMG}"

	create_rk_image

	${PER_CHIP_IMG_GENERATION_COMMAND}

	cd ${DEPLOY_DIR_IMAGE}
	if [ -f ${WORKDIR}/${BOOT_IMG} ]; then
		cp ${WORKDIR}/${BOOT_IMG} ./
	fi
}

create_rk_image () {

	# last dd rootfs will extend gpt image to fit the size,
	# but this will overrite the backup table of GPT
	# will cause corruption error for GPT
	IMG_ROOTFS_SIZE=$(stat -L --format="%s" ${IMG_ROOTFS})

	GPTIMG_MIN_SIZE=$(expr $IMG_ROOTFS_SIZE + \( ${LOADER1_SIZE} + ${RESERVED1_SIZE} + ${RESERVED2_SIZE} + ${LOADER2_SIZE} + ${ATF_SIZE} + ${BOOT_SIZE} + 35 \) \* 512 )

	GPT_IMAGE_SIZE=$(expr $GPTIMG_MIN_SIZE \/ 1024 \/ 1024 + 2)

	# Initialize sdcard image file
	dd if=/dev/zero of=${GPTIMG} bs=1M count=0 seek=$GPT_IMAGE_SIZE

	# Create partition table
	parted -s ${GPTIMG} mklabel gpt

	# Create vendor defined partitions
	LOADER1_START=64
	RESERVED1_START=$(expr ${LOADER1_START} + ${LOADER1_SIZE})
	RESERVED2_START=$(expr ${RESERVED1_START} + ${RESERVED1_SIZE})
	LOADER2_START=$(expr ${RESERVED2_START} + ${RESERVED2_SIZE})
	ATF_START=$(expr ${LOADER2_START} + ${LOADER2_SIZE})
	BOOT_START=$(expr ${ATF_START} + ${ATF_SIZE})
	ROOTFS_START=$(expr ${BOOT_START} + ${BOOT_SIZE})

	BOOT_PART=1
	ROOT_PART=2

	# Create boot partition and mark it as bootable
	parted -s ${GPTIMG} unit s mkpart boot ${BOOT_START} $(expr ${ROOTFS_START} - 1)
	parted -s ${GPTIMG} set ${BOOT_PART} boot on

	# Create rootfs partition
	parted -s ${GPTIMG} -- unit s mkpart rootfs ${ROOTFS_START} -34s

	parted ${GPTIMG} print

	# Change rootfs partuuid
	gdisk ${GPTIMG} <<EOF
x
c
${ROOT_PART}
${ROOT_UUID}
w
y
EOF

	# Delete the boot image to avoid trouble with the build cache
	rm -f ${WORKDIR}/${BOOT_IMG}
	# Create boot partition image
	BOOT_BLOCKS=$(LC_ALL=C parted -s ${GPTIMG} unit b print | awk "/ ${BOOT_PART} / { print substr(\$4, 1, length(\$4 -1)) / 512 /2 }")
	BOOT_BLOCKS=$(expr $BOOT_BLOCKS / 63 \* 63)

	mkfs.vfat -F32 -n "boot" -S 512 -C ${WORKDIR}/${BOOT_IMG} ${BOOT_BLOCKS}
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin ::${KERNEL_IMAGETYPE}
	DTB_NAME=""
	DTB_NAME=$(echo "${KERNEL_DEVICETREE}" | cut -d '/' -f 2)

	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${DTB_NAME} ::${DTB_NAME}

	# Create extlinux config file
	cat >${WORKDIR}/extlinux.conf <<EOF
default rock3

label rock3
	kernel /${KERNEL_IMAGETYPE}
	devicetree /${DTB_NAME}
	append ${GPTIMG_APPEND}
EOF

	mmd -i ${WORKDIR}/${BOOT_IMG} ::/extlinux
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${WORKDIR}/extlinux.conf ::/extlinux/
	if [ -d ${DEPLOY_DIR_IMAGE}/overlays ]; then
		mmd -i ${WORKDIR}/${BOOT_IMG} ::/overlays
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/overlays/* ::/overlays/
	fi
	if [ -e ${DEPLOY_DIR_IMAGE}/hw_intfc.conf ]; then
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/hw_intfc.conf ::/
	fi
	if [ -e ${DEPLOY_DIR_IMAGE}/uEnv.txt ]; then
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/uEnv.txt ::/
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/boot.scr ::/
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/boot.cmd ::/
	fi

	# Burn Boot Partition
	dd if=${WORKDIR}/${BOOT_IMG} of=${GPTIMG} conv=notrunc,fsync seek=${BOOT_START}

	# Burn Rootfs Partition
	dd if=${IMG_ROOTFS} of=${GPTIMG} conv=notrunc,fsync seek=${ROOTFS_START}

}

generate_rk3568_loader_image () {
	LOADER1_START=64
	RESERVED1_START=$(expr ${LOADER1_START} + ${LOADER1_SIZE})
	RESERVED2_START=$(expr ${RESERVED1_START} + ${RESERVED1_SIZE})
	LOADER2_START=$(expr ${RESERVED2_START} + ${RESERVED2_SIZE})
	ATF_START=$(expr ${LOADER2_START} + ${LOADER2_SIZE})
	BOOT_START=$(expr ${ATF_START} + ${ATF_SIZE})
	ROOTFS_START=$(expr ${BOOT_START} + ${BOOT_SIZE})

	dd if=${DEPLOY_DIR_IMAGE}/${IDBLOADER} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER1_START}
	dd if=${DEPLOY_DIR_IMAGE}/${UBOOT_ITB} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER2_START}
}
