#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Bootstrap do sistema base"

run "pacstrap -K '${VITRICE_TARGET}' base linux linux-firmware sudo networkmanager limine btrfs-progs"
run "genfstab -U '${VITRICE_TARGET}' > '${VITRICE_TARGET}/etc/fstab'"

ROOT_UUID="$(blkid -s UUID -o value "${ROOT_PART}")"

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

# ── Limine bootloader (abordagem exata do Omarchy) ──────────────────────────
#
# /etc/default/limine — mesmo formato que o Omarchy usa em default/limine/default.conf
cat > /etc/default/limine <<LIMINE_DEFAULT
TARGET_OS_NAME="VitriceOS"

ESP_PATH="/boot"

KERNEL_CMDLINE[default]="root=UUID=${ROOT_UUID} rw quiet"

ENABLE_UKI=yes
CUSTOM_UKI_NAME="vitriceos"

ENABLE_LIMINE_FALLBACK=yes

FIND_BOOTLOADERS=yes

BOOT_ORDER="*, *fallback"

MAX_SNAPSHOT_ENTRIES=5
LIMINE_DEFAULT

# /boot/limine.conf — mesmo formato que o Omarchy usa em default/limine/limine.conf
cat > /boot/limine.conf <<LIMINE_CONF
### Leia mais em: https://github.com/limine-bootloader/limine/blob/trunk/CONFIG.md
default_entry: 1
interface_branding: VitriceOS
interface_branding_color: 2
hash_mismatch_panic: no

term_background: 1a1b26
backdrop: 1a1b26

# Paleta Tokyo Night (mesma que o Omarchy usa)
term_palette: 15161e;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;a9b1d6
term_palette_bright: 414868;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;c0caf5

term_foreground: c0caf5
term_foreground_bright: c0caf5
term_background_bright: 24283b
LIMINE_CONF

# Instalação UEFI: copiar binário EFI para o caminho de fallback (sem precisar de efivars)
if [[ -d /sys/firmware/efi ]]; then
  mkdir -p /boot/EFI/BOOT
  cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
fi

# limine-update — exatamente o mesmo comando que o Omarchy usa (limine-snapper.sh)
limine-update

rm -f /root/vitrice-post-chroot.sh
CHROOT

run "chmod +x '${VITRICE_TARGET}/root/vitrice-post-chroot.sh'"
run "arch-chroot '${VITRICE_TARGET}' /root/vitrice-post-chroot.sh"

# Instalação BIOS (MBR) — feita fora do chroot, exige acesso direto ao disco
if [[ ! -d /sys/firmware/efi ]]; then
  run "limine bios-install '${VITRICE_DISK}'"
fi
