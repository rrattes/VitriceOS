# Inicia o assistente de instalação automaticamente no primeiro TTY após boot.
# Mesmo comportamento do .zprofile — ambos apontam para o mesmo entry point.
[[ "$(tty 2>/dev/null || true)" == "/dev/tty1" ]] || exit 0
/usr/local/bin/vitrice-autoinstall-launcher
