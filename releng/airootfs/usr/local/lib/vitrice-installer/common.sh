#!/usr/bin/env bash
set -euo pipefail

: "${VITRICE_TARGET:=/mnt}"
: "${VITRICE_HOSTNAME:=vitriceos}"
: "${VITRICE_USERNAME:=vitrice}"
: "${VITRICE_TIMEZONE:=UTC}"
: "${VITRICE_LOCALE:=en_US.UTF-8}"
: "${VITRICE_KEYMAP:=us}"
: "${VITRICE_DRY_RUN:=0}"

log() { printf '\n==> %s\n' "$*"; }
warn() { printf 'Aviso: %s\n' "$*" >&2; }
die() { printf 'Erro: %s\n' "$*" >&2; exit 1; }

run() {
  if [[ "${VITRICE_DRY_RUN}" == "1" ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$*"
  fi
}

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "execute como root"
}

require_cmds() {
  local missing=0
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      warn "comando ausente: $cmd"
      missing=1
    fi
  done
  [[ "$missing" -eq 0 ]] || die "instale os comandos obrigatórios antes de continuar"
}

confirm_destructive() {
  [[ "${VITRICE_DRY_RUN}" == "1" ]] && return 0
  echo "ATENÇÃO: esta etapa APAGA os dados do disco alvo."
  read -r -p "Digite exatamente 'APAGAR' para continuar: " answer
  [[ "$answer" == "APAGAR" ]] || die "operação cancelada pelo usuário"
}
