DEFAULT_PREFERENCE = "1"

DESCRIPTION = "RockPi-3 U-Boot"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=a2c678cfd4a4d97135585cad908541c6"

include recipes-bsp/u-boot/u-boot-rockpi.inc

COMPATIBLE_MACHINE = "(rk3568)"
UBOOT_MAKE_TARGET = "$(UBOOT_MACHINE)"

SRC_URI = " \
	git://github.com/radxa/u-boot.git;branch=stable-4.19-rock3; \
	file://${MACHINE}/uEnv.txt \
	file://${MACHINE}/boot.cmd \
"

SRCREV = "5d7d46a482c89f063ffd31beb7266c11a05c23d5"

do_compile_append() {
	oe_runmake -C ${S} O=${B}/${config} BL31=${DEPLOY_DIR_IMAGE}/radxa-binary/bl31.elf spl/u-boot-spl.bin u-boot.dtb u-boot.itb
	./tools/mkimage -n rk3568 -T rksd -d ${DEPLOY_DIR_IMAGE}/radxa-binary/ddr.bin:spl/u-boot-spl.bin idbloader.img
}

do_deploy_append() {
	install -D -m 644 ${B}/u-boot.itb ${DEPLOYDIR}/
	install -D -m 644 ${B}/idbloader.img ${DEPLOYDIR}/
}
