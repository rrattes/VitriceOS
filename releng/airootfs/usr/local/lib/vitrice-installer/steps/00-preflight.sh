#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Pre-flight"
require_root
require_cmds lsblk parted mkfs.fat mkfs.ext4 pacstrap genfstab arch-chroot

if [[ -z "${VITRICE_DISK:-}" ]]; then
  die "defina VITRICE_DISK (ex: /dev/nvme0n1)"
fi

[[ -b "${VITRICE_DISK}" ]] || die "disco inválido: ${VITRICE_DISK}"

log "Resumo da instalação"
printf '  Disco: %s\n' "${VITRICE_DISK}"
printf '  Hostname: %s\n' "${VITRICE_HOSTNAME}"
printf '  Usuário: %s\n' "${VITRICE_USERNAME}"
printf '  Timezone: %s\n' "${VITRICE_TIMEZONE}"
printf '  Locale: %s\n' "${VITRICE_LOCALE}"
printf '  Keymap: %s\n' "${VITRICE_KEYMAP}"
printf '  Dry-run: %s\n' "${VITRICE_DRY_RUN}"
