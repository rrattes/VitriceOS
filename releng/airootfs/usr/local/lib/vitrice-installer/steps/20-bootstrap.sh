#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Bootstrap do sistema base"

run "pacstrap -K '${VITRICE_TARGET}' base linux linux-firmware sudo networkmanager grub efibootmgr"
run "genfstab -U '${VITRICE_TARGET}' >> '${VITRICE_TARGET}/etc/fstab'"

cat > "${VITRICE_TARGET}/root/vitrice-post-chroot.sh" <<CHROOT
#!/usr/bin/env bash
set -euo pipefail
ln -sf /usr/share/zoneinfo/${VITRICE_TIMEZONE} /etc/localtime
hwclock --systohc
sed -i 's/^#${VITRICE_LOCALE}/${VITRICE_LOCALE}/' /etc/locale.gen
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
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=VitriceOS
grub-mkconfig -o /boot/grub/grub.cfg
rm -f /root/vitrice-post-chroot.sh
CHROOT

run "chmod +x '${VITRICE_TARGET}/root/vitrice-post-chroot.sh'"
run "arch-chroot '${VITRICE_TARGET}' /root/vitrice-post-chroot.sh"
