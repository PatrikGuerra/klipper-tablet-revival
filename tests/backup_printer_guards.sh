#!/bin/bash
# Teste das recusas de impressão/aquecimento; não conversa com o BTT/MCU.
set -Eeuo pipefail
script=$(realpath "${1:-scripts/backup_btt_full.sh}")
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
python3 - "$work" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
cases = {
    "idle": ("standby", "Idle", 0),
    "printing": ("printing", "Printing", 0),
    "paused": ("paused", "Ready", 0),
    "heating": ("standby", "Idle", 200),
    "unknown": ("unexpected", "Idle", 0),
}
for name, (state, idle, target) in cases.items():
    payload = {"result": {"status": {
        "print_stats": {"state": state}, "idle_timeout": {"state": idle},
        "extruder": {"target": target}, "heater_bed": {"target": 0}}}}
    (p / (name + ".json")).write_text(json.dumps(payload))
(p / "missing.json").write_text("{}")
PY
bash -c 'source "$1"; check_printer_json "$2"' _ "$script" "$work/idle.json"
for name in printing paused heating unknown missing; do
    if bash -c 'source "$1"; check_printer_json "$2"' _ "$script" "$work/$name.json" >"$work/$name.log" 2>&1; then
        printf 'FAIL: aceitou estado %s\n' "$name" >&2
        exit 1
    fi
done
printf 'PASS: ociosa aceita; impressão, pausa, aquecimento, estado desconhecido e dados ausentes recusados.\n'
