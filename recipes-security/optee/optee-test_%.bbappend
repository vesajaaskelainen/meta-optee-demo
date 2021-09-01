inherit gitpkgv

PV = "gitr${SRCPV}"
PKGV = "gitr${GITPKGV}"

SRC_URI = " \
    git://github.com/vesajaaskelainen/optee_test.git;branch=devel \
    file://run-ptest \
"
SRCREV = "${AUTOREV}"

EXTRA_OEMAKE += " \
    CFG_PKCS11_TA=y \
"
