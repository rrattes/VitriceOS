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

# ── Limine bootloader ────────────────────────────────────────────────────────
#
# /etc/default/limine — mesmo formato que o Omarchy usa em default/limine/default.conf
# Nota: ENABLE_UKI removido — requer limine-mkinitcpio-hook (repo custom Omarchy,
# não disponível nos mirrors padrão do Arch). Usamos boot Linux padrão.
cat > /etc/default/limine <<LIMINE_DEFAULT
TARGET_OS_NAME="VitriceOS"

ESP_PATH="/boot"

KERNEL_CMDLINE[default]="root=UUID=${ROOT_UUID} rw quiet"

ENABLE_LIMINE_FALLBACK=yes

FIND_BOOTLOADERS=yes

BOOT_ORDER="*, *fallback, Snapshots"

MAX_SNAPSHOT_ENTRIES=5

SNAPSHOT_FORMAT_CHOICE=5
LIMINE_DEFAULT

# /boot/limine.conf — mesmo formato visual do Omarchy (default/limine/limine.conf)
# + entradas de boot explícitas (sem limine-update, que não existe nos repos padrão)
cat > /boot/limine.conf <<LIMINE_CONF
### VitriceOS Bootloader — https://github.com/limine-bootloader/limine/blob/trunk/CONFIG.md
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

/VitriceOS
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: root=UUID=${ROOT_UUID} rw quiet
    module_path: boot():/initramfs-linux.img
    module_path: boot():/initramfs-linux-fallback.img

/VitriceOS (recuperação)
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: root=UUID=${ROOT_UUID} rw
    module_path: boot():/initramfs-linux-fallback.img
LIMINE_CONF

# EFI: copia binário para caminho fallback padrão (sem precisar de efivars)
if [[ -d /sys/firmware/efi ]]; then
  mkdir -p /boot/EFI/BOOT
  cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
fi

rm -f /root/vitrice-post-chroot.sh
CHROOT

run "chmod +x '${VITRICE_TARGET}/root/vitrice-post-chroot.sh'"
run "arch-chroot '${VITRICE_TARGET}' /root/vitrice-post-chroot.sh"

# Instalação BIOS (MBR) — feita fora do chroot, exige acesso direto ao disco.
# limine-bios.sys é o stage 2 lido pelo MBR após POST; deve estar no ESP.
if [[ ! -d /sys/firmware/efi ]]; then
  run "cp /usr/share/limine/limine-bios.sys '${VITRICE_TARGET}/boot/'"
  run "limine bios-install '${VITRICE_DISK}'"
fi
