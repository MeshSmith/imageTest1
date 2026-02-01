#!/bin/bash -e

# This runs OUTSIDE the chroot and can write into the rootfs via $ROOTFS_DIR
# We copy Debian archive keyrings into the target rootfs so apt can verify InRelease signatures.

if [ ! -d "${ROOTFS_DIR}" ]; then
	bootstrap ${RELEASE} "${ROOTFS_DIR}" http://raspbian.raspberrypi.com/raspbian/
fi

install -d -m 0755 "${ROOTFS_DIR}/etc/apt/trusted.gpg.d"
install -d -m 0755 "${ROOTFS_DIR}/usr/share/keyrings"

# Debian archive keyring (on the build host)
if [ -f /usr/share/keyrings/debian-archive-keyring.gpg ]; then
  install -m 0644 /usr/share/keyrings/debian-archive-keyring.gpg \
    "${ROOTFS_DIR}/usr/share/keyrings/debian-archive-keyring.gpg"
  # Also place it where apt will definitely trust it in the chroot
  install -m 0644 /usr/share/keyrings/debian-archive-keyring.gpg \
    "${ROOTFS_DIR}/etc/apt/trusted.gpg.d/debian-archive-keyring.gpg"
fi

# Removed/expired keys file (harmless, but useful for completeness)
if [ -f /usr/share/keyrings/debian-archive-removed-keys.gpg ]; then
  install -m 0644 /usr/share/keyrings/debian-archive-removed-keys.gpg \
    "${ROOTFS_DIR}/usr/share/keyrings/debian-archive-removed-keys.gpg"
fi

# Ensure readable by _apt (unreadable keyrings can be ignored by apt)
chmod 0644 "${ROOTFS_DIR}/etc/apt/trusted.gpg.d/"*.gpg || true
