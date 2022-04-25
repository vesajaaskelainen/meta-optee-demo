FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit useradd

SRC_URI += " \
    file://tee.rules \
"

do_install:append () {
    # install path should match the value set in optee-client/tee-supplicant
    # default TEEC_LOAD_PATH is /lib
    mkdir -p ${D}${nonarch_base_libdir}/optee_armtz/
    install -D -p -m0444 ${B}/ta/*/*.ta ${D}${nonarch_base_libdir}/optee_armtz/

    # udev rules
    install -D -m 0644 ${WORKDIR}/tee.rules ${D}${sysconfdir}/udev/rules.d/99-tee.rules
}

FILES:${PN} += " \
    ${sysconfdir}/udev/rules.d/99-tee.rules \
    ${nonarch_base_libdir}/optee_armtz/ \
"

USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "\
    so-token; \
    device-token; \
    tee; \
    teeclnt; \
"
