# VitriceOS

VitriceOS é uma distro Linux **baseada em Arch Linux**.

Este repositório agora tem foco em um **instalador orientado a scripts**, inspirado no fluxo do projeto Omarchy (basecamp/omarchy), mas adaptado para o nosso SO e para um começo limpo.

## Objetivo atual

- manter ISO instalável via `mkarchiso`;
- concentrar o processo em scripts simples, auditáveis e versionados;
- evitar acoplamentos que atrapalhem evolução do instalador.

## Instalador (script-first)

Ao iniciar o live ISO, um launcher em TTY1 sobe automaticamente e solicita o disco alvo para executar o instalador.

Comando manual (fallback):

```bash
VITRICE_DISK=/dev/sdX vitrice-install
```

Etapas atuais:
1. pre-flight (validação de comandos/variáveis);
2. particionamento GPT automático (EFI + root ext4);
3. bootstrap com `pacstrap`;
4. configuração em `arch-chroot`;
5. finalização e desmontagem.

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
