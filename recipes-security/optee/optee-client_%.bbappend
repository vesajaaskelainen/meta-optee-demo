inherit gitpkgv

PV = "gitr${SRCPV}"
PKGV = "gitr${GITPKGV}"

SRC_URI = " \
    git://github.com/vesajaaskelainen/optee_client.git;branch=devel \
    file://tee-supplicant.service \
    file://tee-supplicant.sh \
"
SRCREV = "${AUTOREV}"
