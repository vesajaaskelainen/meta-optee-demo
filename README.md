This README file contains information on the contents of the meta-optee-demo layer.

Please see the corresponding sections below for details.

# Dependencies

poky:
- URI: git://git.yoctoproject.org/poky
- branch: master (tested with commit `a5b257006b2c480d86e09909cdafb3c8ba05b863`)

meta-arm:
- URI: git://git.yoctoproject.org/meta-arm
- branch: master (tested with commit `13972eed3c9557736b6c30dbd93e8b0fb2a066b7`)

meta-openembedded:
- URI: git://git.openembedded.org/meta-openembedded
- branch: master (tested with commit `3cf16d3012703617ae835e875083105feee07fbe`)


# Adding the meta-optee-demo layer to your build

To add meta-arm layers:
- `bitbake-layers add-layer meta-arm/meta-arm meta-arm/meta-arm-toolchain`

To add open embedded layers:
- `bitbake-layers add-layer meta-openembedded/meta-oe meta-openembedded/meta-python`

(if you don't want to add meta-python please modify core-image-minimal.bbappend and remove the python packages)

And finally add this layer:
- `bitbake-layers add-layer meta-optee-demo`

Add following to `local.conf` (or to your distro configs):

```
# Use systemd for system initialization
DISTRO_FEATURES:append = " systemd"
DISTRO_FEATURES_BACKFILL_CONSIDERED += "sysvinit"
VIRTUAL-RUNTIME_login_manager = "shadow-base"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

# Machine from meta-arm for enabling secure-boot and OP-TEE
MACHINE = "qemuarm64-secureboot"

# Some extra distro features
DISTRO_FEATURES += "pam x11"

# Static user ID and group ID support
USERADDEXTENSION += "useradd-staticids"
```

Then build the image:
```
bitbake core-image-minimal
```

And run it in QEMU:
```
runqemu nographic serialstdio
```

Then you can just login as `root` or as `demo` without an password.


# Misc


## core-image-minimal

Core-image-minimal recipe has been modified to add some helper packages for making life easier.

Please see:
- [recipes-core/images/core-image-minimal.bbappend](recipes-core/images/core-image-minimal.bbappend)


## /etc/hosts

As TLS connections need to verify host name and server name is not in DNS then it can be added temporarily to hosts file.

Hosts file has been preconfigure for QEMU hosts' IP address `192.168.7.1` for `server.local`.

This is only for demonstration purposes and normally should not be used.

Modify following files to match your system or remove them:
- [recipes-core/base-files/base-files_%.bbappend](recipes-core/base-files/base-files_%.bbappend)
- [recipes-core/base-files/base-files/hosts](recipes-core/base-files/base-files/hosts)


## ca-certificates

There is stub bbappend for injecting custom CA certificate:

- [recipes-support/ca-certificates/ca-certificates_%.bbappend](recipes-support/ca-certificates/ca-certificates_%.bbappend)

Please modify it for your needs.


## openssl pkcs11 engine

Openssl is modified for inject pkcs11 engine configuration preconfigured for OP-TEE's Cryptoki library (libckteec.so).

Please see:
- [recipes-connectivity/openssl/openssl_1.1.1l.bbappend](recipes-connectivity/openssl/openssl_1.1.1l.bbappend)


## libp11

Newer version (currently newest commit) of the library to provide pkcs11 pkcs11 for openssl.

Please see:
- [recipes-support/libp11/libp11_git.bb](recipes-support/libp11/libp11_git.bb)


## optee

OP-TEE recipies have been modified to provide new groups for group based ACL demonstration.

Please see:
- [recipes-security/optee/optee-os](recipes-security/optee/optee-os)
- [conf/layer.conf](conf/layer.conf)
- [files/optee-demo.group](files/optee-demo.group)

Groups used for token access control must remain same during life cycle of the device. It is recommended to use static ID mapping to make sure they stay same.

In order for groups to be injected with static ID's following need to be added to your distro configuration or to local.conf:
```
USERADDEXTENSION += "useradd-staticids"
```

Please note that compiling OP-TEE for other machines requires additional work and not covered in here.


# Example commands

## Calculating UUID for group based ACL

Notes on how TEE Identity based ACLs work:

https://github.com/OP-TEE/optee_client/blob/3.14.0/libckteec/include/pkcs11_ta.h#L887

OP-TEE's UUID namespace in Linux kernel: `58ac9ca0-2086-4683-a1b8-ec4bc08e01b6`, the definition is here:

https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/tee/tee_core.c?h=v5.14.1#n27

And different login methods and their keywords:

https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/tee/tee_core.c?h=v5.14.1#n211

Example to calculate UUID for `gid=<device-token's gid>`:
```
# Example group list for demo user
$ id
uid=1000(demo) gid=1001(demo) groups=916(teeclnt),918(device-token),1001(demo)

$ uuidgen --sha1 --namespace 58ac9ca0-2086-4683-a1b8-ec4bc08e01b6 --name "gid=$(printf %x 918)"
ac2cb5e7-4961-50f8-bc6a-4c1571125a55
```

Resulting UUID can then be used in ACL configurations.


## Configuring PKCS11 tokens with group based ACL

Environment variable `CKTEEC_LOGIN_TYPE` is used to configure TEE Identity based login type when connecting OP-TEE's device in kernel.

Supported login types today are:
- `public` login gives unrestricted access when configured in use.
- `user` login only allow specific user to use the token. In this case TEE Identity is calculated by kernel.
- `group` based logins also `CKTEEC_LOGIN_GID` need to be set for gid. Calling process must be member of this group.

See more details from source:

https://github.com/OP-TEE/optee_client/blob/3.14.0/libckteec/src/invoke_ta.c#L252


Example configuration sequence:
```
# login as a root

# Define login type "user" so that empty SO pin automatically uses currently running user as credential
export CKTEEC_LOGIN_TYPE=user
pkcs11-tool --module /usr/lib/libckteec.so.0 --slot-index 0 --init-token --label device --so-pin ""

# Configure token with group ACL: device-token (918)
# See uuidgen command above for customizing it
pkcs11-tool --module /usr/lib/libckteec.so.0 --slot-index 0 --init-pin --login --so-pin "" --new-pin group:ac2cb5e7-4961-50f8-bc6a-4c1571125a55
```

Note: Once TEE Identity based authentication is activated for token, PIN input from tools has no longer any meaning.

Note: Now root cannot access as by default it is not member of `device-token` group.

Testing it out as `demo` user:
```
# Notice there is still the error as not being able to access device token
pkcs11-tool --module /usr/lib/libckteec.so.0 --list-objects --token device --login

# Configure group based credential in use -- kernel verifies group membership
export CKTEEC_LOGIN_TYPE=group
export CKTEEC_LOGIN_GID=918

# Now we can access "device" token with "device-token" group
pkcs11-tool --module /usr/lib/libckteec.so.0 --list-objects --token device --login
```

Generating key and exporting public key:
```
# Using pkcs11-tool to generate key pair with label `rsa-test-key`
pkcs11-tool --module /usr/lib/libckteec.so.0 --token-label device --login --pin "" --keypairgen --key-type RSA:2048 --label rsa-test-key --id 00112233

# Use openssl normally but define `pkcs11` as engine
# -inform engine specifies that "file name" for input is in engine format
# -in <pkcs11 uri>
openssl rsa -engine pkcs11 -inform engine -in "pkcs11:token=device;object=rsa-test-key;type=public" -pubout -out /tmp/rsa-test-key.pem

# Now /tmp/rsa-test-key.pem has public key matching for OP-TEE protected private key with label rsa-test-key

# Now rsa-test-key can be used in various openssl operations like signing file with calculating digest with SHA-256 and then using RSA key from OP-TEE:
openssl dgst -engine pkcs11 -keyform engine -sign "pkcs11:token=device;object=rsa-test-key;type=private" -out /tmp/myfile.sig.sha256 -sha256 /tmp/myfile
```


## Converting Object ID's to PKCS11 URI form

PKCS11 URI is defined in:

https://datatracker.ietf.org/doc/html/rfc7512

In order to have object ID for token based objects in pkcs11 URI form:
```
$ pkcs11-tool --module /usr/lib/libckteec.so.0 --list-objects --token device --login
Certificate Object; type = X.509 cert
  label:      device-cert
  subject:    DN: C=FI, O=Manufacturer, CN=Device/serialNumber=X12345
  ID:         1087fe91bf824f1493e08446b25af4fdb04bcf36
Private Key Object; RSA
  label:      
  ID:         1087fe91bf824f1493e08446b25af4fdb04bcf36
  Usage:      decrypt, sign
  Access:     sensitive, always sensitive, never extractable, local
Public Key Object; RSA 2048 bits
  label:      
  ID:         1087fe91bf824f1493e08446b25af4fdb04bcf36
  Usage:      encrypt, verify
  Access:     local
```

Then convert `ID` field in example with:
```
$ echo "1087fe91bf824f1493e08446b25af4fdb04bcf36" | sed 's/.\{2\}/%&/g'
%10%87%fe%91%bf%82%4f%14%93%e0%84%46%b2%5a%f4%fd%b0%4b%cf%36
```

Then one can make PKCS11 URI like:
```
pkcs11:token=device;id=%10%87%fe%91%bf%82%4f%14%93%e0%84%46%b2%5a%f4%fd%b0%4b%cf%36;type=private
```

This PKCS11 URI then can be used as a "key file name" with keyform "engine".


## Notes on pkcs11 engine's limitations

Certificate chain support is not perfect with openssl's command line client. It only supports one certificate being fetched from pkcs11 token.

So you need to build certificate chain first and then use it.

```
# Construct cert.pem here so that it has PEM version for TLS client certificate and intermediate CA certificates.
# cat > cert.pem
#
# Note: using cert.pem from file as openssl s_client doesn't know how to fetch it from token
openssl s_client -engine pkcs11 -verify 3 -CApath /etc/ssl/certs -keyform engine -key "pkcs11:token=device;id=${ID};type=private" -cert cert.pem server.local:4433
```

With your code you can fetch them in example utilizing with libp11's library (`PKCS11_find_certificate()` and `PKCS11_enumerate_certs()`) or some other PKCS11 library that supports token based X.509 Certificates.
