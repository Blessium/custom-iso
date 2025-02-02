#!/bin/bash

# Check if USB device is provided
if [ -z "$1" ]; then
  echo "Usage: $0 /dev/sdX (replace X with your USB device)"
  exit 1
fi

USB_DEVICE="$1"
USB_MOUNT_DIR="/mnt/usb"
ISO_SOURCE_DIR="${HOME}/Projects/double-iso/livesys"

echo "Installing required packages"
sudo apt update
sudo apt install shim-signed grub-efi-amd64-signed -y

echo "Unmounting existing partitions on $USB_DEVICE"
sudo umount "${USB_DEVICE}"* 2>/dev/null || true

echo "Partitioning $USB_DEVICE"
sudo parted "$USB_DEVICE" --script mklabel gpt
sudo parted "$USB_DEVICE" --script mkpart ESP fat32 1MiB 100%
sudo parted "$USB_DEVICE" --script set 1 esp on

# Force kernel to re-read the partition table
echo "Updating partition table"
sudo partprobe "$USB_DEVICE"
sleep 3  # Wait for partition to register

echo "Formatting partition ${USB_DEVICE}1 as FAT32"
sudo mkfs.vfat -F 32 "${USB_DEVICE}1"

echo "Mounting ${USB_DEVICE}1 to $USB_MOUNT_DIR"
sudo mkdir -p "$USB_MOUNT_DIR"
sudo mount "${USB_DEVICE}1" "$USB_MOUNT_DIR"

echo "Installing GRUB on $USB_DEVICE"
sudo mkdir -p "$USB_MOUNT_DIR/EFI"
sudo grub-install --target=x86_64-efi --removable "$1" --boot-directory="$USB_MOUNT_DIR/boot" --efi-directory="$USB_MOUNT_DIR/EFI"

echo "Copying ISO files to $USB_MOUNT_DIR/iso"
sudo mkdir -p "$USB_MOUNT_DIR/iso"

sudo rsync -h --progress "$ISO_SOURCE_DIR/live-image-amd64.hybrid.iso" "$USB_MOUNT_DIR/iso/debian.iso"

echo "Creating GRUB configuration file"
sudo tee "$USB_MOUNT_DIR/boot/grub/grub.cfg" > /dev/null << 'EOF'
set timeout=5
set menu_color_highlight=cyan/blue

menuentry "Custom Live ISO" {
    rmmod tpm
    set isofile="/iso/debian.iso"
    loopback loop (hd0,gpt1)$isofile
    linux (loop)/live/vmlinuz-6.1.0-30-amd64 boot=live findiso=$isofile components quiet splash --
    initrd (loop)/live/initrd.img-6.1.0-30-amd64
    boot
}
EOF

echo "Copying signed GRUB files to EFI directory"
sudo mkdir -p "$USB_MOUNT_DIR/EFI/BOOT"
sudo cp /usr/lib/shim/shimx64.efi.signed "$USB_MOUNT_DIR/EFI/BOOT/BOOTX64.EFI"
sudo cp /usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed "$USB_MOUNT_DIR/EFI/BOOT/grubx64.efi"

echo "Creating chainload GRUB config for EFI"
sudo mkdir -p "$USB_MOUNT_DIR/EFI/BOOT/grub"
sudo tee "$USB_MOUNT_DIR/EFI/BOOT/grub.cfg" > /dev/null << EOF
insmod part_gpt
insmod fat
insmod iso9660
insmod normal
search --no-floppy --set=root --file /boot/grub/grub.cfg
configfile $root/boot/grub/grub.cfg
EOF

echo "Unmounting $USB_DEVICE"
sudo umount "$USB_MOUNT_DIR"
echo "Done! USB is ready."