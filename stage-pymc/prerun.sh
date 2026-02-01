#!/bin/bash -e

if [ ! -d "${ROOTFS_DIR}" ]; then
	mkdir -p "${ROOTFS_DIR}"
    # Try finding stage2 explicitly or use PREV_STAGE
    SRC_DIR=""
    if [ -d "${WORK_DIR}/stage2/rootfs" ]; then
        SRC_DIR="${WORK_DIR}/stage2/rootfs"
    elif [ -n "${PREV_STAGE}" ] && [ -d "${WORK_DIR}/${PREV_STAGE}/rootfs" ]; then
        SRC_DIR="${WORK_DIR}/${PREV_STAGE}/rootfs"
    fi

    if [ -n "${SRC_DIR}" ]; then
        echo "Copying rootfs from ${SRC_DIR} to ${ROOTFS_DIR}..."
        rsync -aHAXx --exclude var/cache/apt/archives --exclude var/lib/apt/lists "${SRC_DIR}/" "${ROOTFS_DIR}/"
    else
        echo "Error: Previous stage rootfs not found!"
        echo "Checked: ${WORK_DIR}/stage2/rootfs"
        echo "Checked: ${WORK_DIR}/${PREV_STAGE}/rootfs"
        exit 1
    fi
fi
