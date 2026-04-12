#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Finalização"
run "umount -R '${VITRICE_TARGET}'"

log "Instalação concluída."
echo
printf '  Sistema instalado com sucesso!\n'
printf '  Usuário: %s\n' "${VITRICE_USERNAME}"
printf '  Senhas definidas durante a instalação.\n'
echo

if [[ "${VITRICE_DRY_RUN}" != "1" ]]; then
  read -r -p "Pressione Enter para reiniciar o sistema..." _
  reboot
fi
