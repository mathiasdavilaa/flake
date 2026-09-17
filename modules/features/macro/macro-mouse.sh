#!/usr/bin/env bash
#
# macro-mouse.sh — cliques automáticos via ydotool + mango
#
# Uso:
#   macro-mouse.sh <macro>              inicia (loop infinito)
#   macro-mouse.sh <macro> --once       roda uma volta só e sai
#   macro-mouse.sh <macro> --dry-run    só imprime os cliques, não move nada
#   macro-mouse.sh --list               lista os macros cadastrados
#   macro-mouse.sh --pos                imprime a posição atual do cursor
#   macro-mouse.sh -h | --help          esta ajuda
#
#   systemctl --user start macro-mouse@<macro>.service   (via systemd)
#   systemctl --user stop  macro-mouse@<macro>.service
#
# Documentação completa (arquitetura, calibração, troubleshooting):
#   ../macro/README.md
#
# Resumo de como funciona: cada clique é um MOVIMENTO RELATIVO —
# lê a posição real do cursor via `mmsg get cursorpos`, calcula o
# delta até o alvo e manda pro ydotool. Não usa --absolute (não é
# confiável em multi-monitor). Detalhes no README.
#
# ============================================================
#  CADASTRO DE MACROS — é só isso, nada de mexer em case/if
# ============================================================
#
#   1. Descubra as coordenadas:
#        ~/.config/mango/scripts/get-mousepos.sh
#      (ou: macro-mouse.sh --pos, pra pegar um ponto rápido)
#
#   2. Declare o array de posições e a resolução em que foram
#      medidas, seguindo o padrão <PREFIXO>_REF / <PREFIXO>_POSITIONS:
#
#        MINECRAFT_REF="1920x1080"
#        MINECRAFT_POSITIONS=(
#            "500 300"
#            "800 500"
#        )
#
#      Opcional: se você mediu à mão numa resolução específica
#      (em vez de deixar reescalar), declare também
#      <PREFIXO>_POSITIONS_<LARGURA>x<ALTURA> — quando existir, é
#      usado literalmente, sem reescalonamento.
#
#      Opcional: <PREFIXO>_DELAY sobrescreve o delay entre
#      cliques só pra esse macro (padrão: $MACRO_DELAY ou 0.5s).
#
#   3. Registre o nome (e apelidos, se quiser) em MACRO_ALIASES,
#      logo abaixo das definições:
#
#        [minecraft]=MINECRAFT
#
#   4. Teste sem clicar de verdade:
#        macro-mouse.sh minecraft --dry-run
#
#   5. Use:
#        ~/.config/mango/scripts/macro-toggle.sh minecraft
#
# ============================================================

set -uo pipefail

# ------------------------------------------------------------
# CONFIG GLOBAL
# ------------------------------------------------------------

YDOTOOL="${YDOTOOL:-/run/current-system/sw/bin/ydotool}"
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-/run/ydotoold/socket}"
DEFAULT_DELAY="${MACRO_DELAY:-0.5}"

# ------------------------------------------------------------
# MACROS — posições em pixels reais (mmsg cursorpos), na
# resolução declarada em *_REF.
# ------------------------------------------------------------

# medido no desktop, 1920x1080, monitor DP-3
PORTAL_REF="1920x1080"
PORTAL_POSITIONS=(
    "955 275"
    "390 555"
    "610 790"
    "700 370"
    "1250 780"
)

# override opcional: valores medidos à mão no laptop (1920x1200).
# Apague se preferir deixar o reescalonamento automático cuidar.
PORTAL_POSITIONS_1920x1200=(
    "980 300"
    "400 611"
    "600 850"
    "700 411"
    "1250 850"
)

# ------------------------------------------------------------
# REGISTRO — nome usado no comando -> prefixo das variáveis acima.
# Vários nomes podem apontar pro mesmo prefixo (apelidos).
# ------------------------------------------------------------

declare -A MACRO_ALIASES=(
    [portal]=PORTAL
    [portaldesktop]=PORTAL   # nome antigo, mantido por compatibilidade
    [portallaptop]=PORTAL    # nome antigo, mantido por compatibilidade
)

# ============================================================
#  daqui pra baixo é motor — normalmente não precisa mexer
# ============================================================

usage() {
    cat <<EOF
Uso: ${0##*/} <macro> [--once] [--dry-run]
     ${0##*/} --list
     ${0##*/} --pos
     ${0##*/} -h | --help

Macros cadastrados:
$(list_macros | sed 's/^/  /')

Flags:
  --once       roda uma volta só (não fica em loop)
  --dry-run    imprime os cliques sem mover o mouse de verdade
  --list       lista os macros cadastrados e sai
  --pos        imprime a posição atual do cursor ("x y") e sai

Variáveis de ambiente:
  MACRO_RES=1920x1080   força a resolução (em vez de detectar)
  MACRO_DELAY=0.5        delay padrão entre cliques (segundos)

Documentação completa: ../macro/README.md
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

# Resolução da tela: só decide qual array de posições usar.
detect_res() {
    if [ -n "${MACRO_RES:-}" ]; then
        printf '%s\n' "$MACRO_RES"
        return
    fi

    local res
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

    # último recurso: modo nativo do EDID (não acompanha
    # mudanças feitas só no config do mango, mas serve de
    # fallback se o mmsg falhar por algum motivo)
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

# resolve as posições do macro pedido pra resolução atual.
# preenche o array global POSITIONS.
resolve_positions() {
    local macro="$1" res="$2"
    local exact="${macro}_POSITIONS_${res}"
    local base="${macro}_POSITIONS"
    local refname="${macro}_REF"

    POSITIONS=()

    if declare -p "$exact" >/dev/null 2>&1; then
        local -n _src="$exact"
        POSITIONS=("${_src[@]}")
        echo "macro em ${res}: usando posições medidas nessa resolução." >&2
        return
    fi

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
        POSITIONS+=("$(scale "$x" "$rw" "$w") $(scale "$y" "$rh" "$h")")
    done
    echo "macro em ${res}: reescalado a partir de ${_ref}." >&2
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
# relativo até o alvo e clica. Consulta a posição real antes de
# cada movimento, então erros não acumulam entre cliques.
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

# ------------------------------------------------------------
# ARGUMENTOS
# ------------------------------------------------------------

MODE=""
ONCE=0
DRYRUN=0

if [ $# -eq 0 ]; then
    usage
    exit 0
fi

for arg in "$@"; do
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        --list) list_macros; exit 0 ;;
        --pos)
            command -v mmsg >/dev/null 2>&1 || die "mmsg não encontrado no PATH."
            command -v jq   >/dev/null 2>&1 || die "jq não encontrado no PATH."
            cursorpos
            exit 0
            ;;
        --once) ONCE=1 ;;
        --dry-run) DRYRUN=1 ;;
        -*) die "flag desconhecida: '$arg' (veja --help)" ;;
        *)
            [ -n "$MODE" ] && die "mais de um macro informado ('$MODE' e '$arg')"
            MODE="$arg"
            ;;
    esac
done

[ -n "$MODE" ] || die "nenhum macro informado (veja --list)"

MACRO="${MACRO_ALIASES[$MODE]:-}"
[ -n "$MACRO" ] || die "macro desconhecido: '$MODE' (veja --list)"

require_tools

RES="$(detect_res)"
resolve_positions "$MACRO" "$RES"

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
