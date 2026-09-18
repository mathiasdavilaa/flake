#!/usr/bin/env bash
#
# macro-toggle — liga/desliga um macro do macro-mouse.
# Uso e detalhes: README.md (modules/features/macro/)

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

# o serviço systemd --user não herda as variáveis do mango sozinho
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
