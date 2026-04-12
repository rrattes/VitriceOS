#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Pre-flight"
require_root
require_cmds lsblk parted mkfs.fat mkfs.btrfs btrfs pacstrap genfstab arch-chroot

if [[ -z "${VITRICE_DISK:-}" ]]; then
  echo "Discos disponíveis:"
  lsblk -dpno NAME,SIZE,MODEL,TYPE | awk '$4=="disk" {print "  "$1"  "$2"  "$3}'
  read -r -p "Informe o disco alvo (ex: /dev/nvme0n1): " VITRICE_DISK
fi

[[ -n "${VITRICE_DISK}" ]] || die "disco alvo não informado"
[[ -b "${VITRICE_DISK}" ]] || die "disco inválido: ${VITRICE_DISK}"

log "Resumo da instalação"
printf '  Disco: %s\n' "${VITRICE_DISK}"
printf '  Hostname: %s\n' "${VITRICE_HOSTNAME}"
printf '  Usuário: %s\n' "${VITRICE_USERNAME}"
printf '  Timezone: %s\n' "${VITRICE_TIMEZONE}"
printf '  Locale: %s\n' "${VITRICE_LOCALE}"
printf '  Keymap: %s\n' "${VITRICE_KEYMAP}"
printf '  Dry-run: %s\n' "${VITRICE_DRY_RUN}"

printf '  Senha root definida: %s\n' "$([[ -n "${VITRICE_ROOT_PASSWORD}" ]] && echo sim || echo nao)"
printf '  Senha usuário definida: %s\n' "$([[ -n "${VITRICE_USER_PASSWORD}" ]] && echo sim || echo nao)"
