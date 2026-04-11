#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Bootstrap do sistema base"

run "pacstrap -K '${VITRICE_TARGET}' base linux linux-firmware sudo networkmanager efibootmgr"
run "genfstab -U '${VITRICE_TARGET}' > '${VITRICE_TARGET}/etc/fstab'"

cat > "${VITRICE_TARGET}/root/vitrice-post-chroot.sh" <<CHROOT
#!/usr/bin/env bash
set -euo pipefail
ln -sf /usr/share/zoneinfo/${VITRICE_TIMEZONE} /etc/localtime
hwclock --systohc
sed -i "s/^#${VITRICE_LOCALE}/${VITRICE_LOCALE}/" /etc/locale.gen
locale-gen
echo 'LANG=${VITRICE_LOCALE}' > /etc/locale.conf
echo 'KEYMAP=${VITRICE_KEYMAP}' > /etc/vconsole.conf
echo '${VITRICE_HOSTNAME}' > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${VITRICE_HOSTNAME}.localdomain ${VITRICE_HOSTNAME}
HOSTS
systemctl enable NetworkManager
useradd -m -G wheel -s /bin/bash '${VITRICE_USERNAME}' || true
echo 'root:${VITRICE_ROOT_PASSWORD}' | chpasswd
echo '${VITRICE_USERNAME}:${VITRICE_USER_PASSWORD}' | chpasswd
usermod -U root || true
usermod -U '${VITRICE_USERNAME}' || true
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
bootctl --path=/boot install
mkdir -p /boot/loader/entries
cat > /boot/loader/loader.conf <<LOADER
default vitr.conf
timeout 3
editor no
LOADER
ROOT_UUID="$(blkid -s UUID -o value '${ROOT_PART}')"
cat > /boot/loader/entries/vitr.conf <<ENTRY
title VitriceOS
linux /vmlinuz-linux
initrd /initramfs-linux.img
initrd /initramfs-linux-fallback.img
options root=UUID=${ROOT_UUID} rw
ENTRY
rm -f /root/vitrice-post-chroot.sh
CHROOT

run "chmod +x '${VITRICE_TARGET}/root/vitrice-post-chroot.sh'"
run "arch-chroot '${VITRICE_TARGET}' /root/vitrice-post-chroot.sh"
