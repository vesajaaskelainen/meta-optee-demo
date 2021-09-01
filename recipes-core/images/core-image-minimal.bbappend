inherit extrausers

# Add demo user without password
EXTRA_USERS_PARAMS = "\
    useradd -p '' -G teeclnt,device-token demo; \
    "

IMAGE_INSTALL:append = " \
    curl \
    libp11 \
    nss \
    opensc \
    optee-os optee-client optee-test \
    python3 python3-pkcs11 python3-cryptography \
    util-linux \
"
