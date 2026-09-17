#!/usr/bin/env bash

# ============================================================
#  macro-mouse.sh — cliques automáticos via ydotool
#
#  Uso normal (é o que o bind SUPER+F8 faz):
#      ~/.config/mango/scripts/macro-toggle.sh portal
#
#  Uso manual:
#      systemctl --user start macro-mouse@portal.service
#      systemctl --user stop  macro-mouse@portal.service
#
#  RESOLUÇÃO
#  ---------
#  As posições são guardadas em pixels JUNTO com a resolução em
#  que foram medidas (<MACRO>_REF). Em qualquer outra tela o
#  script reescala sozinho, então o mesmo macro serve para o
#  desktop (1920x1080) e para o laptop (1920x1200).
#
#  Se você preferir medir à mão numa resolução específica, crie
#  um array <MACRO>_POSITIONS_<LARGURA>x<ALTURA>: quando ele
#  existir, é usado literalmente, sem reescalar.
#
#  Se a detecção automática errar (ex.: dois monitores no
#  desktop), force com a variável de ambiente:
#      MACRO_RES=1920x1080 macro-mouse portal
#
#  CRIAR UM MACRO NOVO
#  -------------------
#   1. Descubra as coordenadas:
#          ~/.config/mango/scripts/get-mousepos.sh
#   2. Declare o array e a resolução de referência:
#          MINECRAFT_REF="1920x1080"
#          MINECRAFT_POSITIONS=(
#              "500 300"
#              "800 500"
#          )
#   3. Registre no 'case' lá embaixo:
#          minecraft) MACRO="MINECRAFT" ;;
#   4. Use:
#          ~/.config/mango/scripts/macro-toggle.sh minecraft
#
#  O template systemd passa o nome depois do '@' como $1.
# ============================================================

set -uo pipefail

DELAY="${MACRO_DELAY:-0.5}"
YDOTOOL="${YDOTOOL:-/run/current-system/sw/bin/ydotool}"
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-/run/ydotoold/socket}"

# ------------------------------------------------------------
# MACROS
# ------------------------------------------------------------

# medido no desktop, 1920x1080
PORTAL_REF="1920x1080"
PORTAL_POSITIONS=(
  "955 275"
  "390 555"
  "610 790"
  "700 370"
  "1250 780"
)

# override opcional: seus valores medidos à mão no laptop.
# Apague este bloco se quiser deixar o reescalonamento cuidar.
PORTAL_POSITIONS_1920x1200=(
    "980 300"
    "400 611"
    "600 850"
    "700 411"
    "1250 850"
)

# ------------------------------------------------------------

usage() {
    cat <<EOF
Uso: ${0##*/} <macro>

Macros disponíveis:
  portal

Variáveis de ambiente:
  MACRO_RES=1920x1080   força a resolução
  MACRO_DELAY=0.5       intervalo entre cliques (segundos)
EOF
}

# Resolução da tela. Preferência:
#   1. MACRO_RES (override manual)
#   2. mmsg (mango) — reflete monitorrule/wlr-randr em tempo real
#   3. /sys/class/drm — modo NATIVO do EDID (último recurso: não
#      acompanha monitorrule, então se você mudou a resolução só
#      pelo config do mango este fallback continua "desatualizado")
#   4. 1920x1080 chumbado
detect_res() {
    if [ -n "${MACRO_RES:-}" ]; then
        printf '%s\n' "$MACRO_RES"
        return
    fi

    local res
    if command -v mmsg >/dev/null 2>&1; then
        res="$(
            { mmsg get all-monitors 2>/dev/null || mmsg -O 2>/dev/null; } |
            jq -r '
                [.. | objects | select(has("width") and has("height"))] as $mons
                | ( $mons[] | select(.focused==true or .active==true or .selected==true) )
                  // $mons[0]
                | "\(.width|floor)x\(.height|floor)"
            ' 2>/dev/null
        )"
        case "$res" in
            [0-9]*x[0-9]*)
                printf '%s\n' "$res"
                return
                ;;
        esac
    fi

    local conn mode
    for conn in /sys/class/drm/card*-*; do
        [ -r "$conn/status" ] || continue
        [ "$(cat "$conn/status")" = "connected" ] || continue
        mode="$(head -n1 "$conn/modes" 2>/dev/null)"
        case "$mode" in
            [0-9]*x[0-9]*)
                printf '%s\n' "$mode"
                return
                ;;
        esac
    done

    printf '1920x1080\n'
}

# scale <valor> <referência> <atual>  (com arredondamento)
scale() {
    echo $(( ($1 * $3 + $2 / 2) / $2 ))
}

MODE="${1:-}"

case "$MODE" in
    # os nomes antigos continuam valendo, ambos caem no mesmo macro
    portal | portaldesktop | portallaptop)
        MACRO="PORTAL"
        ;;
    "" | -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Macro desconhecido: '$MODE'" >&2
        usage >&2
        exit 1
        ;;
esac

if [ ! -x "$YDOTOOL" ]; then
    echo "Erro: ydotool não encontrado em $YDOTOOL." >&2
    exit 1
fi

RES="$(detect_res)"
W="${RES%x*}"
H="${RES#*x}"

EXACT="${MACRO}_POSITIONS_${RES}"
BASE="${MACRO}_POSITIONS"
REFNAME="${MACRO}_REF"

POSITIONS=()

if declare -p "$EXACT" >/dev/null 2>&1; then
    declare -n _src="$EXACT"
    POSITIONS=("${_src[@]}")
    echo "macro '$MODE' em ${RES}: usando posições medidas nessa resolução."
else
    declare -n _src="$BASE"
    declare -n _ref="$REFNAME"
    RW="${_ref%x*}"
    RH="${_ref#*x}"

    for pos in "${_src[@]}"; do
        read -r x y <<<"$pos"
        POSITIONS+=("$(scale "$x" "$RW" "$W") $(scale "$y" "$RH" "$H")")
    done
    echo "macro '$MODE' em ${RES}: reescalado a partir de ${_ref}."
fi

SLEEP_PID=""

cleanup() {
    [ -n "$SLEEP_PID" ] && kill "$SLEEP_PID" 2>/dev/null
    echo "Macro parado."
    exit 0
}
trap cleanup SIGINT SIGTERM

# sleep em background + wait: assim o SIGTERM do systemd
# interrompe na hora, sem esperar o sleep terminar.
nap() {
    sleep "$1" &
    SLEEP_PID=$!
    wait "$SLEEP_PID" 2>/dev/null
    SLEEP_PID=""
}

echo "Posições: ${POSITIONS[*]}"
echo "Macro iniciado. Aperte o mesmo atalho para parar."

while true; do
    for pos in "${POSITIONS[@]}"; do
        read -r x y <<<"$pos"
        "$YDOTOOL" mousemove --absolute -x "$x" -y "$y"
        nap 0.05
        "$YDOTOOL" click 0xC0
        nap "$DELAY"
    done
done
