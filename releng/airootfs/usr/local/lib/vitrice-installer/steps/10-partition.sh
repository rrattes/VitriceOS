#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Particionamento automático (GPT: EFI + root ext4)"
confirm_destructive

run "wipefs -af '${VITRICE_DISK}'"
run "parted -s '${VITRICE_DISK}' mklabel gpt"
run "parted -s '${VITRICE_DISK}' mkpart ESP fat32 1MiB 513MiB"
run "parted -s '${VITRICE_DISK}' set 1 esp on"
run "parted -s '${VITRICE_DISK}' mkpart root ext4 513MiB 100%"

if [[ "${VITRICE_DISK}" =~ [0-9]$ ]]; then
  EFI_PART="${VITRICE_DISK}p1"
  ROOT_PART="${VITRICE_DISK}p2"
else
  EFI_PART="${VITRICE_DISK}1"
  ROOT_PART="${VITRICE_DISK}2"
fi

export EFI_PART ROOT_PART
run "mkfs.fat -F32 '${EFI_PART}'"
run "mkfs.ext4 -F '${ROOT_PART}'"

run "mount '${ROOT_PART}' '${VITRICE_TARGET}'"
run "mkdir -p '${VITRICE_TARGET}/boot'"
run "mount '${EFI_PART}' '${VITRICE_TARGET}/boot'"
