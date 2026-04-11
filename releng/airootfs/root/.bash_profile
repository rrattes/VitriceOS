# Auto-start do instalador no primeiro login do ISO live.
if [[ "$(tty 2>/dev/null || true)" == "/dev/tty1" ]]; then
  /usr/local/bin/vitrice-autoinstall-launcher
fi
