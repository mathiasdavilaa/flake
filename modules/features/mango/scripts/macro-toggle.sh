#!/usr/bin/env bash
#
# macro-toggle.sh — liga/desliga um macro do macro-mouse.sh
#
# É isto que o bind chama:
#     bind=SUPER,F8,spawn_shell,~/.config/mango/scripts/macro-toggle.sh portal
#
# 'systemctl --user start' sozinho não alterna: se a unit já está
# ativa, ele simplesmente não faz nada. Por isso o bind precisa
# passar por aqui em vez de chamar systemctl direto.
#
# Uso:
#   macro-toggle.sh <macro>      liga se estiver parado, desliga se
#                                 estiver rodando (padrão: portal)
#   macro-toggle.sh --status     mostra se algum macro está ativo
#
# Documentação completa: ../../macro/README.md

set -uo pipefail

notify() {
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -a "macro-mouse" -t 1500 "$1" "$2"
    return 0
}

if [ "${1:-}" = "--status" ]; then
    running="$(systemctl --user list-units --type=service --state=active \
        'macro-mouse@*.service' --no-legend --plain 2>/dev/null |
        awk '{print $1}' | sed -E 's/^macro-mouse@(.*)\.service$/\1/')"
    if [ -n "$running" ]; then
        echo "ativo: $running"
    else
        echo "nenhum macro ativo"
    fi
    exit 0
fi

MACRO="${1:-portal}"
UNIT="macro-mouse@${MACRO}.service"

# O bind roda como filho do mango, então este script TEM as
# variáveis do mango no próprio ambiente. Um serviço systemd
# --user não herda isso sozinho — precisa ser importado antes de
# dar start, senão o mmsg dentro do macro não enxerga o compositor.
systemctl --user import-environment \
    MANGO_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_RUNTIME_DIR \
    2>/dev/null || true

if systemctl --user is-active --quiet "$UNIT"; then
    systemctl --user stop "$UNIT"
    notify "Macro parado" "$MACRO"
else
    # garante que nenhum outro macro fique rodando junto
    systemctl --user stop 'macro-mouse@*.service' >/dev/null 2>&1 || true
    systemctl --user start "$UNIT"
    notify "Macro iniciado" "$MACRO"
fi
