require u-boot.inc

DESCRIPTION = "RockPi-3 U-Boot"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=a2c678cfd4a4d97135585cad908541c6"
HOMEPAGE = "https://github.com/radxa/u-boot"
LICENSE = "GPLv2+"
SECTION = "bootloaders"
DEPENDS = "dtc-native bc-native swig-native bison-native coreutils-native"

S = "${WORKDIR}/git"

# u-boot will build native python module
inherit pythonnative

SRC_URI = " \
	git://github.com/radxa/u-boot.git;branch=stable-4.19-rock3; \
	file://${MACHINE}/uEnv.txt \
	file://${MACHINE}/boot.scr \
	file://0001-Fix-error-when-loading-make_fit_args.sh-from-make_fi.patch \
"

SRCREV = "5d7d46a482c89f063ffd31beb7266c11a05c23d5"

do_configure () {
    if [ -z "${UBOOT_CONFIG}" ]; then
        if [ -n "${UBOOT_MACHINE}" ]; then
            oe_runmake -C ${S} O=${B} ${UBOOT_MACHINE}
        else
            oe_runmake -C ${S} O=${B} oldconfig
        fi

        ${S}/scripts/kconfig/merge_config.sh -m .config ${@" ".join(find_cfgs(d))}
        cml1_do_configure
    fi
}

do_compile_prepend () {
	export STAGING_INCDIR=${STAGING_INCDIR_NATIVE};
	export STAGING_LIBDIR=${STAGING_LIBDIR_NATIVE};
	mkdir -p ${B}/arch/arm
	cp -rf ${S}/arch/arm/mach-rockchip ${B}/arch/arm
}

do_compile_append () {
	# copy to default search path
	if [ ${SPL_BINARY} ]; then
		cp ${B}/spl/${SPL_BINARY} ${B}/
	fi
	if [ -f "${WORKDIR}/${MACHINE}/boot.cmd" ]; then
		cp ${WORKDIR}/${MACHINE}/boot.cmd ${WORKDIR}/boot.cmd
		${B}/tools/mkimage -C none -A arm -O linux -T script -d ${WORKDIR}/boot.cmd ${WORKDIR}/boot.scr
	elif [ -f "${WORKDIR}/${MACHINE}/boot.scr" ]; then
		cp ${WORKDIR}/${MACHINE}/boot.scr ${WORKDIR}/boot.scr
	fi

	oe_runmake -C ${S} O=${B} BL31=${DEPLOY_DIR_IMAGE}/radxa-binary/bl31.elf spl/u-boot-spl.bin u-boot.dtb u-boot.itb
	./tools/mkimage -n rk3568 -T rksd -d ${DEPLOY_DIR_IMAGE}/radxa-binary/ddr.bin:spl/u-boot-spl.bin idbloader.img
}

do_install_append() {
	if [ -f "${WORKDIR}/boot.scr" ]; then
		install -m 644 ${WORKDIR}/boot.scr ${D}/boot/
	fi
	if [ -f "${WORKDIR}/${MACHINE}/uEnv.txt" ]; then
		install -m 644 ${WORKDIR}/${MACHINE}/uEnv.txt ${D}/boot/
	fi
}

do_deploy_append() {
	cp -a ${B}/tools/mkimage ${DEPLOY_DIR_IMAGE}
	if [ -f "${WORKDIR}/${MACHINE}/uEnv.txt" ]; then
		install -D -m 644 ${WORKDIR}/${MACHINE}/uEnv.txt ${DEPLOYDIR}/
	fi
	if [ -f "${WORKDIR}/boot.scr" ]; then
		install -D -m 644 ${WORKDIR}/boot.scr ${DEPLOYDIR}/
	fi
	if [ -f "${WORKDIR}/boot.cmd" ]; then
		install -D -m 644 ${WORKDIR}/boot.cmd ${DEPLOYDIR}/
	fi
	install -D -m 644 ${B}/u-boot.itb ${DEPLOYDIR}/
	install -D -m 644 ${B}/idbloader.img ${DEPLOYDIR}/
}

PACKAGE_BEFORE_PN = "${PN}-scripts"
FILES_${PN}-scripts = " \
	/boot/boot.scr \
	/boot/uEnv.txt \
"
