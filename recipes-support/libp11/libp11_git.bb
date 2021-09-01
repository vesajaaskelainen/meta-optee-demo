SUMMARY = "Library for using PKCS"
DESCRIPTION = "\
Libp11 is a library implementing a small layer on top of PKCS \
make using PKCS"
HOMEPAGE = "https://github.com/OpenSC/libp11"
BUGTRACKER = "https://github.com/OpenSC/libp11/issues"
SECTION = "Development/Libraries"
LICENSE = "LGPLv2+"
LIC_FILES_CHKSUM = "file://COPYING;md5=fad9b3332be894bab9bc501572864b29"
DEPENDS = "libtool openssl"

SRC_URI = "git://github.com/OpenSC/libp11.git"
SRCREV = "51261328691443edb6d013bc76ef9de2880fb12a"

UPSTREAM_CHECK_GITTAGREGEX = "libp11-(?P<pver>\d+(\.\d+)+)"

S = "${WORKDIR}/git"

inherit autotools pkgconfig gitpkgv

PV = "gitr${SRCPV}"
PKGV = "gitr${GITPKGV}"

EXTRA_OECONF = "--disable-static"

do_install:append () {
    rm -rf ${D}${docdir}/${BPN}
}

FILES:${PN} += "${libdir}/engines*/pkcs11.so"
FILES:${PN}-dev += "${libdir}/engines*/libpkcs11${SOLIBSDEV}"

BBCLASSEXTEND = "native"
