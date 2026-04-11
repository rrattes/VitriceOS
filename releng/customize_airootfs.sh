#!/usr/bin/env bash
set -euo pipefail

# Ativar o serviço de instalação automática no TTY1
# (substitui o getty@tty1, exatamente como o Omarchy faz com systemd para o login)
systemctl enable vitrice-autoinstall.service
