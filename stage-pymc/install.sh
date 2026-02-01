#!/bin/bash -e

# Clone repo
mkdir tmp
git clone -b dev https://github.com/rightup/pyMC_Repeater.git tmp/repo

# Install pyMC files
install -d tmp/repo "${ROOTFS_DIR}/opt/pymc-repeater"

on_chroot <<- \EOF
    # Create service user
    SERVICE_USER="repeater"
    if ! id "$SERVICE_USER" &>/dev/null; then
        useradd --system --home /var/lib/pymc_repeater --shell /sbin/nologin "$SERVICE_USER"
    fi

    # Add user to groups
    usermod -a -G gpio,i2c,spi "$SERVICE_USER" 2>/dev/null || true
    usermod -a -G dialout "$SERVICE_USER" 2>/dev/null || true
EOF