# Auto-start do instalador no primeiro login do ISO live (zsh login shell).
if [ "$(tty 2>/dev/null || true)" = "/dev/tty1" ]; then
  /usr/local/bin/vitrice-autoinstall-launcher
fi
