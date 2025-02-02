#!/bin/bash
ISO_PATH="${HOME}/Downloads/debian.iso"
MOUNT_DIR="/mnt/debian-iso"

# Mount the ISO to detect kernel/initrd
sudo mkdir -p "$MOUNT_DIR"
sudo mount -o loop "$ISO_PATH" "$MOUNT_DIR"

# Find the latest vmlinuz and initrd
VMLINUZ=$(find "$MOUNT_DIR/live" -name "vmlinuz-*" | sort -V | tail -n1)
INITRD=$(find "$MOUNT_DIR/live" -name "initrd.img-*" | sort -V | tail -n1)

echo "Latest vmlinuz: $VMLINUZ"
echo "Latest initrd: $INITRD"

sudo umount "${MOUNT_DIR}" 