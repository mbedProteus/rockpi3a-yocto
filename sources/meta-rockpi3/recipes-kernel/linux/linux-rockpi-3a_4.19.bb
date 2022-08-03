DESCRIPTION = "Linux kernel for Rock Pi 3A"

inherit kernel
inherit python3native
require recipes-kernel/linux/linux-yocto.inc

# We need mkimage for the overlays
DEPENDS += "openssl-native u-boot-mkimage-radxa-native"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
	git://github.com/radxa/kernel.git;branch=stable-4.19-rock3; \
"

SRCREV = "67a0c0ce87a07769ea7afd4a0978a0f22c76f8ce"
LINUX_VERSION = "4.19.193"

# Override local version in order to use the one generated by linux build system
# And not "yocto-standard"
LINUX_VERSION_EXTENSION = ""
PR = "r1"
PV = "${LINUX_VERSION}+git${SRCREV}"

# Include only supported boards for now
COMPATIBLE_MACHINE = "(rk3568)"
deltask kernel_configme

# Make sure we use /usr/bin/env ${PYTHON_PN} for scripts
do_patch_append() {
	for s in `grep -rIl python ${S}/scripts`; do
		sed -i -e '1s|^#!.*python[23]*|#!/usr/bin/env ${PYTHON_PN}|' $s
	done
}

do_compile_append() {
	oe_runmake dtbs
}

do_deploy_append() {
	install -d ${DEPLOYDIR}/overlays
	install -m 644 ${WORKDIR}/linux-rockpi_3a-standard-build/arch/arm64/boot/dts/rockchip/overlay/* ${DEPLOYDIR}/overlays
}
