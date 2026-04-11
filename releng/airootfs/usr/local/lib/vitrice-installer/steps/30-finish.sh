#!/usr/bin/env bash
source /usr/local/lib/vitrice-installer/common.sh

log "Finalização"
run "umount -R '${VITRICE_TARGET}'"
log "Instalação base concluída. Reinicie e defina senhas com 'passwd' e 'passwd ${VITRICE_USERNAME}'."
