#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="VitriceOS"
iso_label="VITRICE_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="VitriceOS <https://example.org>"
iso_application="VitriceOS Live ISO"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.systemd-boot.esp' 'uefi-x64.systemd-boot.esp'
           'uefi-ia32.systemd-boot.eltorito' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/local/bin/vitrice-install"]="0:0:755"
  ["/usr/local/bin/vitrice-autoinstall-launcher"]="0:0:755"
  ["/etc/systemd/system/vitrice-autoinstall.service"]="0:0:644"
  ["/usr/local/lib/vitrice-installer/common.sh"]="0:0:755"
  ["/usr/local/lib/vitrice-installer/steps/00-preflight.sh"]="0:0:755"
  ["/usr/local/lib/vitrice-installer/steps/10-partition.sh"]="0:0:755"
  ["/usr/local/lib/vitrice-installer/steps/20-bootstrap.sh"]="0:0:755"
  ["/usr/local/lib/vitrice-installer/steps/30-finish.sh"]="0:0:755"
)
