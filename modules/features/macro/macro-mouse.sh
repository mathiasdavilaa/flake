#!/usr/bin/env bash
#
# macro-mouse — cliques automáticos via ydotool + mango.
# Uso, cadastro de novos macros e troubleshooting: README.md
# (modules/features/macro/)

set -uo pipefail

YDOTOOL="${YDOTOOL:-/run/current-system/sw/bin/ydotool}"
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-/run/ydotoold/socket}"
DEFAULT_DELAY="${MACRO_DELAY:-0.5}"
MACROS_DIR="${MACROS_DIR:-$(dirname "$(readlink -f "$0")")/macros}"

declare -A MACRO_ALIASES=()

load_macros() {
    local f
    for f in "$MACROS_DIR"/*.macro; do
        [ -e "$f" ] || continue
        # shellcheck source=/dev/null
        source "$f"
    done
}

usage() {
    cat <<EOF
Uso: ${0##*/} <macro> [--once] [--dry-run]
     ${0##*/} --capture [nome]
     ${0##*/} --list
     ${0##*/} --pos
     ${0##*/} -h | --help

Macros cadastrados:
$(list_macros | sed 's/^/  /')

Flags:
  --once       roda uma volta só (não fica em loop)
  --dry-run    imprime os cliques sem mover o mouse de verdade
  --capture    modo guiado pra descobrir coordenadas e gerar um
               arquivo macros/<nome>.macro pronto pra colar
  --list       lista os macros cadastrados e sai
  --pos        imprime a posição atual do cursor ("x y") e sai

Variáveis de ambiente:
  MACRO_RES=1920x1080   força a resolução (em vez de detectar)
  MACRO_DELAY=0.5        delay padrão entre cliques (segundos)

Documentação completa: README.md (modules/features/macro/)
EOF
}

# nomes canônicos + apelidos, agrupados por macro, ordenados
list_macros() {
    local prefix primary
    local -A seen=()
    local -a prefixes=()

    for primary in "${!MACRO_ALIASES[@]}"; do
        prefix="${MACRO_ALIASES[$primary]}"
        [ -n "${seen[$prefix]:-}" ] && continue
        seen[$prefix]=1
        prefixes+=("$prefix")
    done

    IFS=$'\n' prefixes=($(sort <<<"${prefixes[*]}")); unset IFS

    for prefix in "${prefixes[@]}"; do
        local names=() name
        for name in "${!MACRO_ALIASES[@]}"; do
            [ "${MACRO_ALIASES[$name]}" = "$prefix" ] && names+=("$name")
        done
        IFS=$'\n' names=($(sort <<<"${names[*]}")); unset IFS
        if [ "${#names[@]}" -gt 1 ]; then
            printf '%s  (apelidos: %s)\n' "${names[0]}" "$(IFS=,; echo "${names[*]:1}")"
        else
            printf '%s\n' "${names[0]}"
        fi
    done
}

die() {
    echo "Erro: $*" >&2
    exit 1
}

require_tools() {
    [ -x "$YDOTOOL" ] || die "ydotool não encontrado em $YDOTOOL."
    command -v mmsg >/dev/null 2>&1 || die "mmsg não encontrado no PATH (necessário pro movimento relativo)."
    command -v jq >/dev/null 2>&1 || die "jq não encontrado no PATH."
}

# posição atual real do cursor, segundo o mango: "x y"
cursorpos() {
    mmsg get cursorpos | jq -r '"\(.x) \(.y)"'
}

# geometria do monitor focado: "largura altura origem_x origem_y".
# origem_x/y ficam em 0 se o mmsg não expuser esses campos — nesse
# caso o comportamento é idêntico ao de antes (sem offset).
focused_monitor_geom() {
    if [ -n "${MACRO_RES:-}" ]; then
        printf '%s 0 0\n' "${MACRO_RES/x/ }"
        return
    fi

    local geom
    geom="$(
        { mmsg get all-monitors 2>/dev/null || mmsg -O 2>/dev/null; } |
        jq -r '
            [.. | objects | select(has("width") and has("height"))] as $mons
            | ( $mons[] | select(.focused==true or .active==true or .selected==true) )
              // $mons[0]
            | "\(.width|floor) \(.height|floor) \((.x // 0)|floor) \((.y // 0)|floor)"
        ' 2>/dev/null
    )"
    case "$geom" in
        [0-9]*' '[0-9]*' '*)
            printf '%s\n' "$geom"
            return
            ;;
    esac

    # último recurso: modo nativo do EDID (não dá pra saber a
    # origem no layout, então assume 0,0 — serve de fallback se o
    # mmsg falhar por algum motivo)
    local conn mode
    for conn in /sys/class/drm/card*-*; do
        [ -r "$conn/status" ] || continue
        [ "$(cat "$conn/status")" = "connected" ] || continue
        mode="$(head -n1 "$conn/modes" 2>/dev/null)"
        case "$mode" in
            [0-9]*x[0-9]*)
                printf '%s 0 0\n' "${mode/x/ }"
                return
                ;;
        esac
    done

    printf '1920 1080 0 0\n'
}

# scale <valor> <referência> <atual>  (com arredondamento)
scale() {
    echo $(( ($1 * $3 + $2 / 2) / $2 ))
}

# resolve as posições do macro pedido pra resolução/monitor atual,
# já somando a origem do monitor focado (coordenada global final).
# preenche o array global POSITIONS.
resolve_positions() {
    local macro="$1" res="$2" mon_x="$3" mon_y="$4"
    local exact="${macro}_POSITIONS_${res}"
    local base="${macro}_POSITIONS"
    local refname="${macro}_REF"
    local -a local_positions=()

    if declare -p "$exact" >/dev/null 2>&1; then
        local -n _src="$exact"
        local_positions=("${_src[@]}")
        echo "macro em ${res}: usando posições medidas nessa resolução." >&2
    else
        if ! declare -p "$base" >/dev/null 2>&1; then
            die "macro '$macro' não tem ${base} declarado."
        fi

        local -n _src="$base"
        local -n _ref="$refname"
        local rw="${_ref%x*}" rh="${_ref#*x}"
        local w="${res%x*}" h="${res#*x}"
        local pos x y

        for pos in "${_src[@]}"; do
            read -r x y <<<"$pos"
            local_positions+=("$(scale "$x" "$rw" "$w") $(scale "$y" "$rh" "$h")")
        done
        echo "macro em ${res}: reescalado a partir de ${_ref}." >&2
    fi

    POSITIONS=()
    local pos x y
    for pos in "${local_positions[@]}"; do
        read -r x y <<<"$pos"
        POSITIONS+=("$((x + mon_x)) $((y + mon_y))")
    done
}

SLEEP_PID=""

cleanup() {
    [ -n "$SLEEP_PID" ] && kill "$SLEEP_PID" 2>/dev/null
    echo "Macro parado."
    exit 0
}
trap cleanup SIGINT SIGTERM

# sleep em background + wait: o SIGTERM do systemd interrompe na
# hora, sem esperar o sleep terminar.
nap() {
    sleep "$1" &
    SLEEP_PID=$!
    wait "$SLEEP_PID" 2>/dev/null
    SLEEP_PID=""
}

# click_at <x-alvo> <y-alvo> [--dry-run]: anda por delta
# relativo até o alvo (já em coordenada global) e clica. Consulta
# a posição real antes de cada movimento, então erros não
# acumulam entre cliques.
click_at() {
    local tx="$1" ty="$2" dry="${3:-}" cx cy dx dy
    read -r cx cy < <(cursorpos)
    dx="$(awk -v t="$tx" -v c="$cx" 'BEGIN{d=t-c; printf "%d", (d>=0)?int(d+0.5):int(d-0.5)}')"
    dy="$(awk -v t="$ty" -v c="$cy" 'BEGIN{d=t-c; printf "%d", (d>=0)?int(d+0.5):int(d-0.5)}')"

    if [ "$dry" = "--dry-run" ]; then
        printf 'clicaria em (%s, %s) — atual (%s, %s), delta (%s, %s)\n' \
            "$tx" "$ty" "$cx" "$cy" "$dx" "$dy"
        return
    fi

    "$YDOTOOL" mousemove -x "$dx" -y "$dy"
    nap 0.05
    "$YDOTOOL" click 0xC0
}

# modo guiado: pede ENTER a cada ponto, mostra a posição
# capturada (já em coordenada LOCAL do monitor focado, pronta pra
# colar num arquivo macros/<nome>.macro) e imprime o bloco final.
capture_mode() {
    local name="${1:-}"
    command -v mmsg >/dev/null 2>&1 || die "mmsg não encontrado no PATH."
    command -v jq   >/dev/null 2>&1 || die "jq não encontrado no PATH."

    local res w h mon_x mon_y
    read -r w h mon_x mon_y < <(focused_monitor_geom)
    res="${w}x${h}"

    echo "Monitor focado: ${res} (origem ${mon_x},${mon_y})" >&2
    echo "Posicione o mouse e aperte ENTER pra registrar um ponto." >&2
    echo "Digite 'q' + ENTER (ou Ctrl+D) pra terminar." >&2
    echo >&2

    local -a captured=()
    local i=1 line cx cy lx ly
    while true; do
        read -r -p "ponto $i> " line || break
        [ "$line" = "q" ] && break
        read -r cx cy < <(cursorpos)
        lx=$((cx - mon_x))
        ly=$((cy - mon_y))
        captured+=("$lx $ly")
        echo "  -> local (${lx}, ${ly})  [global (${cx}, ${cy})]" >&2
        i=$((i + 1))
    done

    [ "${#captured[@]}" -gt 0 ] || die "nenhum ponto capturado."

    [ -n "$name" ] || read -r -p "nome do macro (ex: minecraft): " name
    [ -n "$name" ] || die "nome do macro é obrigatório."

    local prefix upper
    upper="$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9_')"

    echo >&2
    echo "# salve como macros/${name}.macro (modules/features/macro/macros/)" >&2
    cat <<EOF
# macro: ${name}

${upper}_REF="${res}"
${upper}_POSITIONS=(
$(for p in "${captured[@]}"; do printf '    "%s"\n' "$p"; done)
)

MACRO_ALIASES+=(
    [${name}]=${upper}
)
EOF
}

# ------------------------------------------------------------
# ARGUMENTOS
# ------------------------------------------------------------

MODE=""
ONCE=0
DRYRUN=0
CAPTURE=0

if [ $# -eq 0 ]; then
    load_macros
    usage
    exit 0
fi

for arg in "$@"; do
    case "$arg" in
        -h|--help) load_macros; usage; exit 0 ;;
        --list) load_macros; list_macros; exit 0 ;;
        --pos)
            command -v mmsg >/dev/null 2>&1 || die "mmsg não encontrado no PATH."
            command -v jq   >/dev/null 2>&1 || die "jq não encontrado no PATH."
            cursorpos
            exit 0
            ;;
        --capture) CAPTURE=1 ;;
        --once) ONCE=1 ;;
        --dry-run) DRYRUN=1 ;;
        -*) die "flag desconhecida: '$arg' (veja --help)" ;;
        *)
            [ -n "$MODE" ] && die "mais de um macro/nome informado ('$MODE' e '$arg')"
            MODE="$arg"
            ;;
    esac
done

if [ "$CAPTURE" = 1 ]; then
    require_tools
    capture_mode "$MODE"
    exit 0
fi

load_macros

[ -n "$MODE" ] || die "nenhum macro informado (veja --list)"

MACRO="${MACRO_ALIASES[$MODE]:-}"
[ -n "$MACRO" ] || die "macro desconhecido: '$MODE' (veja --list)"

require_tools

RES_W="" RES_H="" MON_X="" MON_Y=""
read -r RES_W RES_H MON_X MON_Y < <(focused_monitor_geom)
RES="${RES_W}x${RES_H}"
resolve_positions "$MACRO" "$RES" "$MON_X" "$MON_Y"

DELAYVAR="${MACRO}_DELAY"
DELAY="${!DELAYVAR:-$DEFAULT_DELAY}"

echo "Posições: ${POSITIONS[*]}"
if [ "$DRYRUN" = 1 ]; then
    echo "(dry-run — nenhum clique real será enviado)"
fi
if [ "$ONCE" = 0 ] && [ "$DRYRUN" = 0 ]; then
    echo "Macro iniciado. Aperte o mesmo atalho para parar."
fi

run_pass() {
    local pos x y dryflag=""
    [ "$DRYRUN" = 1 ] && dryflag="--dry-run"
    for pos in "${POSITIONS[@]}"; do
        read -r x y <<<"$pos"
        click_at "$x" "$y" "$dryflag"
        nap "$DELAY"
    done
}

if [ "$ONCE" = 1 ] || [ "$DRYRUN" = 1 ]; then
    run_pass
    exit 0
fi

while true; do
    run_pass
done
