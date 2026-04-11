# VitriceOS

VitriceOS é uma distro Linux **baseada em Arch Linux**, com foco em ser um projeto limpo para desenvolvimento de uma ISO instalável.

## Objetivo desta fase

Este repositório foi reduzido para um **esqueleto mínimo**, mantendo apenas o necessário para:

- gerar ISO com `mkarchiso`;
- preservar base Arch;
- facilitar evolução incremental sem acoplamentos desnecessários.

## Estrutura atual

- `build.sh`: script simples para build da ISO.
- `releng/`: perfil ArchISO mínimo.
  - `profiledef.sh`
  - `packages.x86_64`
  - `pacman.conf`
  - `customize_airootfs.sh`
  - arquivos de boot (grub/syslinux/efiboot)

## Build rápido

```bash
sudo ./build.sh
```

Ou manualmente:

```bash
sudo mkarchiso -v -w /tmp/vitriceos-work -o /tmp/vitriceos-out releng/
```
