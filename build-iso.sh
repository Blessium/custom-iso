#!/bin/bash

ISO_FS=config/includes.chroot

mkdir -p ./livesys
cd livesys || exit
sudo lb clean --purge
# Configurazione
lb config \
    --mode debian \
    --architecture amd64 \
    --bootloaders grub-efi \
    --debian-installer live \
    --distribution bookworm \
    --system live \
    --archive-areas 'main contrib non-free non-free-firmware' \
    --debootstrap-options "--variant=minbase" \
    --mirror-bootstrap http://deb.debian.org/debian/ \
    --mirror-binary http://deb.debian.org/debian/ \
    --apt-recommends false \


mkdir -p config/package-lists/
cat <<EOF > config/package-lists/network.list.chroot
ifupdown
iproute2
udhcpc
wpasupplicant
EOF

# Aggiunta del binario custom scritto da me
mkdir -p ${ISO_FS}/usr/local/bin
cp ../custom-binary/main ${ISO_FS}/usr/local/bin/
chmod +x ${ISO_FS}/usr/local/bin/main

mkdir -p ${ISO_FS}/lib/live/config/
cp ../0001-boot-main.hook.chroot ${ISO_FS}/lib/live/config/

mkdir -p ${ISO_FS}/etc/systemd/system/getty@tty1.service.d/
cat <<EOF > ${ISO_FS}/etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM -l /usr/local/bin/main
EOF

# mkdir -p config/bootloaders/grub/
# cat <<EOF > config/bootloaders/grub/grub.cfg
# label live
#   menu label ^Live system
#   kernel /live/vmlinuz
#   append boot=live components initrd=/live/initrd.img quiet splash --
# EOF



time sudo lb build

qemu-system-x86_64 -cdrom livesys/live-image-amd64.hybrid.iso -boot d -m 2048
