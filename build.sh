#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:-/var/tmp/vitriceos-work}"
OUT_DIR="${2:-/var/tmp/vitriceos-out}"

if [[ ${EUID} -ne 0 ]]; then
  echo "Erro: execute como root (sudo ./build.sh)" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" releng/

echo "ISO gerada em: ${OUT_DIR}"
