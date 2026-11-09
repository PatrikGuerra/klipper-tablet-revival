#!/bin/bash
# Exercita o trap de erro com serviço fictício; não para/inicia serviços reais.
set -Eeuo pipefail
script=$(realpath "${1:-scripts/backup_btt_full.sh}")
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir "$work/archive" "$work/state"
set +e
bash -c '
source "$1"
out="$2/archive"
STATE_DIR="$2/state"
active=(fixture-only.service)
services_touched=1
running_backup=1
systemctl() { printf "%s\n" "$*" >>"$STATE_DIR/service-calls.txt"; }
trap cleanup EXIT
exit 23
' _ "$script" "$work"
rc=$?
set -e
[[ $rc == 23 ]]
grep -qx 'start fixture-only.service' "$work/state/service-calls.txt"
grep -qx 'status=FAILED' "$work/archive/RESULT.txt"
grep -qx 'phase=FAILED' "$work/state/status.txt"
printf 'PASS: falha preserva exit=23, registra FAILED e restaura somente o serviço fictício.\n'
