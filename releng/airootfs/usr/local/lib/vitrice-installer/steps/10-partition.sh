#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Particionamento automático (GPT: EFI + root Btrfs)"
confirm_destructive

run "wipefs -af '${VITRICE_DISK}'"
run "parted -s '${VITRICE_DISK}' mklabel gpt"
run "parted -s '${VITRICE_DISK}' mkpart ESP fat32 1MiB 513MiB"
run "parted -s '${VITRICE_DISK}' set 1 esp on"
run "parted -s '${VITRICE_DISK}' mkpart root btrfs 513MiB 100%"

if [[ "${VITRICE_DISK}" =~ [0-9]$ ]]; then
  EFI_PART="${VITRICE_DISK}p1"
  ROOT_PART="${VITRICE_DISK}p2"
else
  EFI_PART="${VITRICE_DISK}1"
  ROOT_PART="${VITRICE_DISK}2"
fi

export EFI_PART ROOT_PART

run "mkfs.fat -F32 '${EFI_PART}'"
run "mkfs.btrfs -f '${ROOT_PART}'"

# Criar subvolumes Btrfs (requisito do Omarchy)
run "mount '${ROOT_PART}' /mnt"
run "btrfs subvolume create /mnt/@"
run "btrfs subvolume create /mnt/@home"
run "umount /mnt"

# Montar subvolumes com opções de performance
run "mount -o subvol=@,compress=zstd,noatime '${ROOT_PART}' '${VITRICE_TARGET}'"
run "mkdir -p '${VITRICE_TARGET}/home'"
run "mount -o subvol=@home,compress=zstd,noatime '${ROOT_PART}' '${VITRICE_TARGET}/home'"
run "mkdir -p '${VITRICE_TARGET}/boot'"
run "mount '${EFI_PART}' '${VITRICE_TARGET}/boot'"
