#!/usr/bin/env bash
set -euo pipefail

source_monitor="$(mmsg get focusing-client | jq -r '.monitor')"
source_tag="$(mmsg get monitor "$source_monitor" | jq -r '.tags[] | select(.is_active == true) | .index')"

target_monitor="$(
  mmsg get all-monitors |
    jq -r --arg source "$source_monitor" '
      .monitors[]
      | select(.name != $source)
      | .name
    ' |
    head -n1
)"

mmsg dispatch tagcrossmon,"$source_tag,$target_monitor"
mmsg dispatch focusmon,"$source_monitor"
