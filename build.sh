#!/usr/bin/env bash
set -eEuo pipefail

WORK_DIR="${1:-/var/tmp/vitriceos-work}"
OUT_DIR="${2:-/var/tmp/vitriceos-out}"
MKARCHISO_BIN="${MKARCHISO_BIN:-mkarchiso}"

if [[ ${EUID} -ne 0 ]]; then
  echo "Erro: execute como root (sudo ./build.sh)" >&2
  exit 1
fi

echo "[build] Limpando workdir anterior: ${WORK_DIR}"
rm -rf "${WORK_DIR}"
mkdir -p "${OUT_DIR}"

echo "[build] Gerando ISO com '${MKARCHISO_BIN}'..."
"${MKARCHISO_BIN}" -v -w "${WORK_DIR}" -o "${OUT_DIR}" releng/

echo "ISO gerada em: ${OUT_DIR}"
