#!/usr/bin/env bash

# ============================================================
# CONFIGURATION
# ============================================================

# Niri output names
LAPTOP_OUTPUT="eDP-1"
DESKTOP_OUTPUT="DP-3"

# ------------------------------------------------------------
# LAPTOP POSITIONS
# Configure your coordinates manually here
# ------------------------------------------------------------

LAPTOP_POSITIONS=(
    "980 300"
    "400 611"
    "600 850"
    "700 411"
    "1250 850"
)

# ------------------------------------------------------------
# DESKTOP / EXTERNAL MONITOR POSITIONS
# Configure your coordinates manually here
# ------------------------------------------------------------

DESKTOP_POSITIONS=(
    "980 285"
    "400 550"
    "600 780"
    "700 370"
    "1250 800"
)

# Delay between clicks
DELAY=0.5

# Path to ydotool
YDOTOOL="/run/current-system/sw/bin/ydotool"

# ydotoold socket on NixOS
export YDOTOOL_SOCKET="/run/ydotoold/socket"


# ============================================================
# DETECT FOCUSED MONITOR
# ============================================================

OUTPUT=$(niri msg -j focused-output)

# Extract the output name
OUTPUT_NAME=$(printf '%s\n' "$OUTPUT" \
    | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')

if [ -z "$OUTPUT_NAME" ]; then
    echo "Erro: não foi possível detectar o monitor focado."
    exit 1
fi

echo "Monitor detectado: $OUTPUT_NAME"


# ============================================================
# SELECT POSITION LIST
# ============================================================

case "$OUTPUT_NAME" in

    "$LAPTOP_OUTPUT")
        echo "Usando pontos do LAPTOP"
        POSITIONS=("${LAPTOP_POSITIONS[@]}")
        ;;

    "$DESKTOP_OUTPUT")
        echo "Usando pontos do DESKTOP"
        POSITIONS=("${DESKTOP_POSITIONS[@]}")
        ;;

    *)
        echo "Erro: monitor '$OUTPUT_NAME' não está configurado."
        echo "Configure o nome dele em LAPTOP_OUTPUT ou DESKTOP_OUTPUT."
        exit 1
        ;;

esac


# ============================================================
# MACRO
# ============================================================

echo "Posições configuradas:"

for pos in "${POSITIONS[@]}"; do
    echo "  $pos"
done

echo "Macro iniciada."

while true; do

    for pos in "${POSITIONS[@]}"; do

        read -r x y <<< "$pos"

        "$YDOTOOL" mousemove --absolute -x "$x" -y "$y"

        sleep 0.05

        "$YDOTOOL" click 0xC0

        sleep "$DELAY"

    done

done
