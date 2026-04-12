# VitriceOS

VitriceOS é uma distro Linux **baseada em Arch Linux**.

Este repositório agora tem foco em um **instalador orientado a scripts**, inspirado no fluxo do projeto Omarchy (basecamp/omarchy), mas adaptado para o nosso SO e para um começo limpo.

## Objetivo atual

- manter ISO instalável via `mkarchiso`;
- concentrar o processo em scripts simples, auditáveis e versionados;
- evitar acoplamentos que atrapalhem evolução do instalador.

## Instalador (script-first)

No live ISO, um prompt de instalação abre automaticamente no tty1 (estilo Omarchy).

Comando manual:

```bash
VITRICE_DISK=/dev/sdX vitrice-install
```

Senha padrão inicial (altere após primeiro boot):
- root: `vitrice`
- usuário padrão (`vitrice`): `vitrice`

Etapas atuais:
1. pre-flight (validação de comandos/variáveis);
2. particionamento GPT automático (ESP + root Btrfs com subvolumes `@` e `@home`);
3. bootstrap com `pacstrap` (base, KDE Plasma 6, Plasma Login Manager, Limine…);
4. configuração em `arch-chroot` (locale, rede, usuário, `plasmalogin.service`);
5. configuração de boot com **Limine** (UEFI e BIOS/MBR);
6. finalização e desmontagem.

### Modo seguro para desenvolvimento

Para validar fluxo sem alterar disco:

```bash
VITRICE_DISK=/dev/sdX VITRICE_DRY_RUN=1 vitrice-install
```

## Build da ISO

```bash
sudo ./build.sh
```

Ou manualmente:

```bash
sudo mkarchiso -v -w /tmp/vitriceos-work -o /tmp/vitriceos-out releng/
```
