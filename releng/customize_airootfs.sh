#!/usr/bin/env bash
set -euo pipefail

# Desbloquear root no ambiente live.
# O pacote 'base' coloca '!' em /etc/shadow por padrão (conta bloqueada).
# systemd 256+ recusa iniciar serviços interativos de TTY com usuário bloqueado,
# causando: "Failed to start vitrice-autoinstall.service: user root is blocked".
# passwd -d remove a senha (conta sem senha = desbloqueada).
passwd -d root

# Ativar o serviço de instalação automática no TTY1
systemctl enable vitrice-autoinstall.service
