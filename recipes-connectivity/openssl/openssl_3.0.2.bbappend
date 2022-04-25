FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:class-target = "file://0001-openssl.cnf-Configure-OP-TEE-for-pkcs11-engine.patch"
