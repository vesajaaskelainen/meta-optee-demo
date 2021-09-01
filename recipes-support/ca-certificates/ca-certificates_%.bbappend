FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRC_URI:append = " file://service-root-ca.pem"
#
#do_install:append() {
#    install -m 0644 ${WORKDIR}/service-root-ca.pem ${D}${sysconfdir}/ssl/certs/
#}
