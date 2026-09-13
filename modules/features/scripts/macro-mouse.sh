#!/usr/bin/env bash

# ============================================================
#
# Usage:
#   systemctl --user start macro-mouse@portaldesktop.service
#   systemctl --user start macro-mouse@portallaptop.service
#
# Stop:
#   systemctl --user stop macro-mouse@portaldesktop.service
#
# Add a new macro:
#
#   1. Create a new POSITIONS array:
#
#      MINECRAFT_POSITIONS=(
#          "500 300"
#          "800 500"
#          "1000 700"
#      )
#
#   2. Add it to the 'case':
#
#      minecraft)
#          POSITIONS=("${MINECRAFT_POSITIONS[@]}")
#          ;;
#
#   3. Start it:
#
#      systemctl --user start macro-mouse@minecraft.service
#
# The systemd template passes the name after '@' to this script
# as $1.
#
# ============================================================


PORTALLAPTOP_POSITIONS=(
    "980 300"
    "400 611"
    "600 850"
    "700 411"
    "1250 850"
)

PORTALDESKTOP_POSITIONS=(
    "980 285"
    "400 550"
    "600 780"
    "700 370"
    "1250 800"
)

DELAY=0.5
YDOTOOL="/run/current-system/sw/bin/ydotool"
export YDOTOOL_SOCKET="/run/ydotoold/socket"

MODE="${1:-portaldesktop}"

case "$MODE" in
    portallaptop)
        POSITIONS=("${PORTALLAPTOP_POSITIONS[@]}")
        echo "Using portallaptop positions."
        ;;
    portaldesktop)
        POSITIONS=("${PORTALDESKTOP_POSITIONS[@]}")
        echo "Using portaldesktop positions."
        ;;
    *)
        echo "Use: $0 [portaldesktop|portallaptop]"
        exit 1
        ;;
esac

if [ ! -x "$YDOTOOL" ]; then
    echo "Error: ydotool not found in $YDOTOOL."
    exit 1
fi

cleanup() {
    echo -e "\nStopped."
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "Macro started. Use the same command to stop."

while true; do
    for pos in "${POSITIONS[@]}"; do
        read -r x y <<< "$pos"
        "$YDOTOOL" mousemove --absolute -x "$x" -y "$y"
        sleep 0.05
        "$YDOTOOL" click 0xC0
        sleep "$DELAY"
    done
done
