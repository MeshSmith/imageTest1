#!/bin/bash -e

# Ensure ROOTFS_DIR is defined
if [ -z "${ROOTFS_DIR}" ]; then
    ROOTFS_DIR="${WORK_DIR}/${STAGE}/rootfs"
fi

if [ ! -d "${ROOTFS_DIR}" ] || [ -z "$(ls -A "${ROOTFS_DIR}")" ]; then
    echo "Rootfs missing or empty. Manually copying from stage2..."
    mkdir -p "${ROOTFS_DIR}"

    # Path to stage2 rootfs based on pi-gen structure
    # The log shows: /pi-gen/work/MeshSmith-Trixie-Lite/stage2/rootfs
    PREV_ROOTFS="${WORK_DIR}/stage2/rootfs"
    
    # Fallback search if exact path fails (robustness)
    if [ ! -d "${PREV_ROOTFS}" ]; then
        echo "stage2 rootfs not found at ${PREV_ROOTFS}. Searching work dir..."
        FOUND_ROOTFS=$(find "${WORK_DIR}" -maxdepth 2 -path "*/stage2/rootfs" | head -n 1)
        if [ -n "${FOUND_ROOTFS}" ]; then
             PREV_ROOTFS="${FOUND_ROOTFS}"
        fi
    fi

    if [ -d "${PREV_ROOTFS}" ]; then
        echo "Copying rootfs from ${PREV_ROOTFS} to ${ROOTFS_DIR}..."
        # Use rsync for better attribute preservation, or cp -al if hardlinks supported (rsync is safer across potentially different mounts/FS types in docker)
        rsync -aHAXx --exclude var/cache/apt/archives --exclude var/lib/apt/lists "${PREV_ROOTFS}/" "${ROOTFS_DIR}/"
    else
        echo "CRITICAL ERROR: Could not find stage2 rootfs to copy!"
        echo "Expected at: ${PREV_ROOTFS}"
        echo "Work Dir contents:"
        ls -la "${WORK_DIR}" || true
        exit 1
    fi
else
    echo "Rootfs already exists at ${ROOTFS_DIR}. Skipping copy."
fi
