#!/usr/bin/env bash
set -euo pipefail

source_monitor="$(mmsg get focusing-client | jq -r '.monitor')"

mmsg dispatch tagmon,right
mmsg dispatch focusmon,"$source_monitor"
