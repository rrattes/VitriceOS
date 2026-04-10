#!/usr/bin/env bash
set -euo pipefail

SCRIPT_UNDER_TEST="releng/airootfs/etc/calamares/scripts/install-bootloader.sh"

if [[ ! -f "${SCRIPT_UNDER_TEST}" ]]; then
  echo "ERROR: script not found: ${SCRIPT_UNDER_TEST}" >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "${TMP_ROOT}"' EXIT

new_case() {
  local name="$1"
  local case_dir="${TMP_ROOT}/${name}"
  mkdir -p "${case_dir}/mock"
  printf '%s' "${case_dir}"
}

write_noop() {
  local path="$1"
  cat > "${path}" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${path}"
}

make_test_script() {
  local out="$1"
  cp "${SCRIPT_UNDER_TEST}" "${out}"
  # Allow deterministic UEFI testing in CI/smoke by injecting an override.
  sed -i "s#\\[ -d /sys/firmware/efi/efivars \\] && UEFI=true#\\[ \"\${FORCE_UEFI:-0}\" = \"1\" \\] \&\& UEFI=true || \\[ -d /sys/firmware/efi/efivars \\] \&\& UEFI=true#" "${out}"
}

mk_blockdev_if_missing() {
  local node="$1" major="$2" minor="$3"
  [[ -b "${node}" ]] || mknod -m 600 "${node}" b "${major}" "${minor}" 2>/dev/null || true
}

run_case() {
  local name="$1"
  local expect_rc="$2"
  local case_dir="$3"
  local log="${case_dir}/log"
  local out="${case_dir}/out"
  local err="${case_dir}/err"
  : > "${log}"

  if PATH="${case_dir}/mock:/usr/bin:/bin" \
      TEST_LOG="${log}" \
      FORCE_UEFI="${FORCE_UEFI:-0}" \
      bash "${case_dir}/script.sh" >"${out}" 2>"${err}"; then
    rc=0
  else
    rc=$?
  fi

  if [[ "${rc}" -ne "${expect_rc}" ]]; then
    echo "FAIL(${name}): expected rc=${expect_rc}, got rc=${rc}" >&2
    echo "--- stdout ---" >&2; cat "${out}" >&2 || true
    echo "--- stderr ---" >&2; cat "${err}" >&2 || true
    return 1
  fi
  echo "PASS(${name})"
}

# Shared no-op commands that should never mutate host in smoke tests.
shared_noops=(cp snapper systemctl pacman useradd sudo mktemp rm userdel chown grep sed find tar)

###############################################################################
# CASE 1: BIOS root on mapper resolves to /dev/sda
###############################################################################
case1="$(new_case bios_mapper_root)"
make_test_script "${case1}/script.sh"

cat > "${case1}/mock/findmnt" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"-o UUID /"*) echo "1111-2222";;
  *"-o SOURCE /boot"*) exit 1;;
  *"-o SOURCE /"*) echo "/dev/mapper/vg-root";;
  *"-o FSTYPE /"*) echo "ext4";;
  *"-o OPTIONS /"*) echo "rw,relatime";;
  *) exit 1;;
esac
EOF
chmod +x "${case1}/mock/findmnt"

cat > "${case1}/mock/lsblk" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"PKNAME /dev/mapper/vg-root"*) echo "sda2";;
  *"PKNAME /dev/sda2"*) echo "sda";;
  *"PKNAME /dev/sda"*) exit 0;;
  *) exit 0;;
esac
EOF
chmod +x "${case1}/mock/lsblk"

cat > "${case1}/mock/limine" <<'EOF'
#!/usr/bin/env bash
echo "limine $*" >> "${TEST_LOG}"
exit 0
EOF
chmod +x "${case1}/mock/limine"

for cmd in "${shared_noops[@]}"; do write_noop "${case1}/mock/${cmd}"; done
mk_blockdev_if_missing /dev/sda 8 0
mk_blockdev_if_missing /dev/sda2 8 2
run_case "bios_mapper_root" 0 "${case1}"
grep -q "limine bios-install /dev/sda" "${case1}/log"

###############################################################################
# CASE 2: BIOS fallback to /boot source when root source cannot resolve
###############################################################################
case2="$(new_case bios_boot_fallback)"
make_test_script "${case2}/script.sh"

cat > "${case2}/mock/findmnt" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"-o UUID /"*) echo "3333-4444";;
  *"-o SOURCE /boot"*) echo "/dev/nvme0n1p1";;
  *"-o SOURCE /"*) echo "/dev/mapper/unknown";;
  *"-o FSTYPE /"*) echo "ext4";;
  *"-o OPTIONS /"*) echo "rw,relatime";;
  *) exit 1;;
esac
EOF
chmod +x "${case2}/mock/findmnt"

cat > "${case2}/mock/lsblk" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"PKNAME /dev/mapper/unknown"*) exit 0;;
  *"PKNAME /dev/nvme0n1p1"*) echo "nvme0n1";;
  *"PKNAME /dev/nvme0n1"*) exit 0;;
  *) exit 0;;
esac
EOF
chmod +x "${case2}/mock/lsblk"

cat > "${case2}/mock/limine" <<'EOF'
#!/usr/bin/env bash
echo "limine $*" >> "${TEST_LOG}"
exit 0
EOF
chmod +x "${case2}/mock/limine"

for cmd in "${shared_noops[@]}"; do write_noop "${case2}/mock/${cmd}"; done
mk_blockdev_if_missing /dev/nvme0n1 259 0
mk_blockdev_if_missing /dev/nvme0n1p1 259 1
run_case "bios_boot_fallback" 0 "${case2}"
grep -q "limine bios-install /dev/nvme0n1" "${case2}/log"

###############################################################################
# CASE 3: UEFI must fail when no FAT ESP is mounted
###############################################################################
case3="$(new_case uefi_missing_esp)"
make_test_script "${case3}/script.sh"

cat > "${case3}/mock/findmnt" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"-o UUID /"*) echo "5555-6666";;
  *"-o SOURCE /"*) echo "/dev/sda2";;
  *"-o FSTYPE /"*) echo "ext4";;
  *"-o TARGET /boot/efi"*) exit 1;;
  *"-o TARGET /boot"*) exit 1;;
  *"-o TARGET /efi"*) exit 1;;
  *"-o OPTIONS /"*) echo "rw,relatime";;
  *) exit 1;;
esac
EOF
chmod +x "${case3}/mock/findmnt"

cat > "${case3}/mock/lsblk" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"PKNAME /dev/sda2"*) echo "sda";;
  *"PKNAME /dev/sda"*) exit 0;;
  *) exit 0;;
esac
EOF
chmod +x "${case3}/mock/lsblk"

write_noop "${case3}/mock/limine"
for cmd in "${shared_noops[@]}"; do write_noop "${case3}/mock/${cmd}"; done
mk_blockdev_if_missing /dev/sda 8 0
mk_blockdev_if_missing /dev/sda2 8 2
FORCE_UEFI=1 run_case "uefi_missing_esp" 1 "${case3}"
grep -q "no mounted FAT ESP" "${case3}/out"

echo "All smoke checks passed."
