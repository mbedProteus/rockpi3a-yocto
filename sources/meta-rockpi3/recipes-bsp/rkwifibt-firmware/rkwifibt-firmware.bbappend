FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://fw_bcm43752a2_ag_apsta.bin \
    file://fw_bcm43752a2_ag.bin \
    file://nvram_ap6275s.txt \
    file://clm_bcm43752a2_ag.blob \
"

do_install_append() {
    install -d ${D}/vendor/etc/firmware
    install -m 0644 ${WORKDIR}/fw_bcm43752a2_ag_apsta.bin ${D}/vendor/etc/firmware
    install -m 0644 ${WORKDIR}/fw_bcm43752a2_ag.bin ${D}/vendor/etc/firmware
    install -m 0644 ${WORKDIR}/nvram_ap6275s.txt ${D}/vendor/etc/firmware
    install -m 0644 ${WORKDIR}/clm_bcm43752a2_ag.blob ${D}/vendor/etc/firmware
}

# do_deploy_append() {
#     install -d ${DEPLOYDIR}/vendor/etc/firmware
#     cp ${D}/vendor/etc/firmware/* ${DEPLOYDIR}/vendor/etc/firmware/
# }

PACKAGES =+ " \
    ${PN}-ap6275s-wifi \
"

FILES_${PN}-ap6275s-wifi += " \
    /vendor/etc/firmware/fw_bcm43752a2_ag_apsta.bin \
    /vendor/etc/firmware/fw_bcm43752a2_ag.bin \
    /vendor/etc/firmware/nvram_ap6275s.txt \
    /vendor/etc/firmware/clm_bcm43752a2_ag.blob \
"