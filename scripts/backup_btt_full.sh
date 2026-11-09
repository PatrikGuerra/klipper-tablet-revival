#!/bin/bash
# Backup de arquivos persistentes + boot do BTT validado. Nunca formata/apaga backups.
set -Eeuo pipefail
export LC_ALL=C
USB_UUID=05B1-3EBC
ROOT_UUID=10ee7f0c-c457-4a96-8da8-13398de6c273
BOOT_UUID=AEBD-0084
MOUNT_POINT=/mnt/btt-backup-usb
UNIT=btt-system-backup
STATE_DIR=/var/lib/btt-backup
out=''
mounted_here=0
services_touched=0
finished=0
running_backup=0
active=()
usage() {
    cat <<'EOF'
Backup do BTT para o pendrive cadastrado, sem apagar dados existentes.
  sudo btt-backup --start   Inicia em segundo plano; pode fechar o SSH.
  sudo btt-backup --status  Mostra andamento/último resultado.
  sudo btt-backup --check   Confere discos, espaço e impressora, sem fazer cópia.
  sudo btt-backup --run     Executa no terminal; mantenha a sessão aberta.
  sudo btt-backup --stop    Interrompe e tenta religar os serviços.
  btt-backup --help         Exibe esta ajuda.
Sem argumentos equivale a --start. Pode levar dezenas de minutos.
O backup contém senhas/chaves do sistema: mantenha-o privado.
EOF
}
die() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
log() {
    local message="$(date -Is) $*"
    printf '%s\n' "$message"
    if [[ -n $out ]]; then printf '%s\n' "$message" >>"$out/progress.log"; fi
}
state() {
    printf 'phase=%s\nupdated=%s\nbackup=%s\n' "$1" "$(date -Is)" "$out" >"$STATE_DIR/status.new"
    mv "$STATE_DIR/status.new" "$STATE_DIR/status.txt"
    log "$1"
}
check_printer_json() {
    python3 - "$1" <<'PY'
import json, sys
try:
    s = json.load(open(sys.argv[1]))["result"]["status"]
    state = s["print_stats"]["state"].lower()
    if state not in ("standby", "complete", "cancelled", "error"):
        raise ValueError("impressão ativa, pausada ou estado desconhecido: " + state)
    if s["idle_timeout"]["state"] not in ("Idle", "Ready"):
        raise ValueError("idle_timeout não confirma ociosidade")
    for name in ("extruder", "heater_bed"):
        if float(s[name]["target"]) != 0:
            raise ValueError("aquecimento ativo em " + name)
except Exception as exc:
    sys.exit("Estado da impressora não permite backup: " + str(exc))
PY
}
printer_check() {
    curl -fsS --max-time 10 'http://127.0.0.1:7125/printer/objects/query?print_stats&idle_timeout&extruder&heater_bed' >"$printer_json"
    check_printer_json "$printer_json"
}
restore_services() {
    if ((services_touched)); then
        log 'Religando somente os serviços que estavam ativos antes do backup.'
        if ((${#active[@]})); then systemctl start "${active[@]}" || return 1; fi
        services_touched=0
    fi
}
cleanup() {
    local rc=$?
    trap - EXIT INT TERM HUP
    set +e
    restore_services || rc=1
    if [[ -n $out ]]; then
        if ((rc == 0 && finished)); then
            log 'SUCESSO: backup e verificações concluídos.'
            printf 'exit=0\nstatus=SUCCESS\n' >"$out/RESULT.txt"
            state SUCCESS
        else
            ((rc != 0)) || rc=1
            log "FALHA/INTERRUPÇÃO: exit=$rc. Pasta parcial preservada; não é backup validado."
            printf 'exit=%s\nstatus=FAILED\n' "$rc" >"$out/RESULT.txt"
            state FAILED
        fi
        cp "$out/RESULT.txt" "$STATE_DIR/last-result.txt"
    elif ((running_backup)); then
        ((rc != 0)) || rc=1
        state FAILED
        printf 'exit=%s\nstatus=FAILED_PREFLIGHT\n' "$rc" >"$STATE_DIR/last-result.txt"
    fi
    [[ -z ${printer_json:-} ]] || rm -f -- "$printer_json"
    sync
    if ((mounted_here)) && ! umount "$MOUNT_POINT"; then
        printf 'AVISO: falha ao desmontar %s; não remova o USB ainda.\n' "$MOUNT_POINT" >&2
        rc=1
    fi
    exit "$rc"
}
preflight() {
    local tool parent available used required other_source other_target
    for tool in tar gzip split sha256sum sfdisk lsblk findmnt blockdev mount umount flock curl python3 systemctl systemd-run df du dd readlink mktemp sync tee install dpkg-query find; do
        command -v "$tool" >/dev/null || die "Comando ausente: $tool"
    done
    exec 9>/run/lock/btt-system-backup.lock
    flock -n 9 || die 'Outro backup/verificação já está em execução.'
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM HUP
    if [[ ${1:-} == backup ]]; then
        install -d -m 0700 "$STATE_DIR"
        running_backup=1
        state PREFLIGHT
    fi
    root_device=$(readlink -f "$(findmnt -n -o SOURCE /)")
    [[ -b $root_device && $(findmnt -n -o UUID /) == "$ROOT_UUID" ]] || die 'Raiz diferente do BTT cadastrado.'
    boot_device=$(readlink -f "/dev/disk/by-uuid/$BOOT_UUID")
    usb_device=$(readlink -f "/dev/disk/by-uuid/$USB_UUID")
    [[ -b $boot_device && -b $usb_device ]] || die 'Boot ou pendrive cadastrado não encontrado.'
    root_disk="/dev/$(lsblk -dn -o PKNAME "$root_device")"
    [[ -b $root_disk ]] || die 'Cartão de origem não identificado.'
    [[ $(lsblk -dn -o PKNAME "$root_device") == "$(lsblk -dn -o PKNAME "$boot_device")" ]] || die 'Boot em outro disco.'
    [[ $(findmnt -n -o UUID /boot) == "$BOOT_UUID" ]] || die '/boot não está montado como esperado.'
    parent="/dev/$(lsblk -dn -o PKNAME "$usb_device")"
    [[ $parent != "$root_disk" && $(lsblk -dn -o TRAN "$parent") == usb ]] || die 'Destino não é USB separado do sistema.'
    if findmnt -rn -S "$usb_device" >/dev/null; then
        dest=$(findmnt -rn -S "$usb_device" -o TARGET)
        [[ $dest == "$MOUNT_POINT" ]] || die "Pendrive já montado em $dest; desmonte-o antes."
        [[ ,$(findmnt -n -o OPTIONS -M "$dest"), == *,rw,* ]] || die 'Pendrive está somente para leitura.'
    else
        mkdir -p "$MOUNT_POINT"
        ! findmnt -rn -M "$MOUNT_POINT" >/dev/null || die 'Ponto de montagem ocupado.'
        [[ -z $(find "$MOUNT_POINT" -mindepth 1 -maxdepth 1 -print -quit) ]] || die 'Ponto de montagem contém arquivos locais.'
        mount -o rw,nosuid,nodev,noexec,umask=077 "$usb_device" "$MOUNT_POINT"
        mounted_here=1
        dest=$MOUNT_POINT
    fi
    [[ $(findmnt -n -o UUID -M "$dest") == "$USB_UUID" ]] || die 'UUID do pendrive montado não confere.'
    [[ $(findmnt -n -o FSTYPE -M "$dest") == vfat ]] || die 'Pendrive diferente do FAT32 validado.'
    while read -r other_source other_target; do
        if [[ $other_source == /dev/* && $other_target != / && $other_target != /boot && $other_target != "$dest" ]]; then
            die "Volume persistente adicional não coberto: $other_source em $other_target"
        fi
    done < <(findmnt -rn -o SOURCE,TARGET)
    available=$(df -B1 --output=avail "$dest" | tail -1 | tr -d ' ')
    used=$(df -B1 --output=used / | tail -1 | tr -d ' ')
    required=$((used + $(blockdev --getsize64 "$boot_device") + 1073741824))
    ((available >= required)) || die "Espaço insuficiente: precisa de $required bytes, há $available. Nenhum backup foi apagado."
    printer_json=$(mktemp /run/btt-backup-printer.XXXXXX)
    printer_check
    log "Verificação OK: origem=$root_disk; USB=$USB_UUID; livre=$available; necessário conservador=$required bytes."
}
write_restore_notes() {
    cat >"$out/RESTORE.txt" <<'EOF'
BACKUP DE ARQUIVOS PERSISTENTES + BOOT DO BTT
Não é uma imagem bruta única. /dev /proc /sys /run /tmp /mnt /media e
lost+found são excluídos. /boot é capturado como imagem separada.
Klipper, Moonraker, KlipperScreen e seu supervisor são parados na captura.
O Linux continua ligado: não é snapshot atômico de todos os serviços.

VERIFICAR, dentro desta pasta:
  cat RESULT.txt                   # precisa indicar SUCCESS e exit=0
  sha256sum -c SHA256SUMS
  gzip -t boot-partition.img.gz
  cat root.tar.gz.part-* | gzip -t
  cat root.tar.gz.part-* | tar -tzf - > /tmp/inventario.txt

RESTAURAR: use outro Linux, BTT desligado e cartão de destino identificado.
Gravar discos/partições APAGA O DESTINO. Não grave no BTT em funcionamento.
1. Valide hashes e capacidade do cartão conforme partition-table.sfdisk.
2. Recrie prefixo/bootloader e layout no cartão de destino correto.
3. Recrie raiz ext4 com UUID registrado em disks.txt/fstab.txt.
4. Restaure boot-partition.img.gz na partição FAT de boot correspondente.
5. Monte a raiz. Concatene root.tar.gz.part-* e extraia como root com GNU
   tar, preservando --numeric-owner --acls --xattrs e os links.
6. Recrie /dev /proc /sys /run /mnt /media e /tmp (modo 1777).
7. Confira UUIDs/fstab/boot; sincronize, desmonte e teste no BTT.
A verificação de arquivos não substitui teste de restauração em outro cartão.
O backup pode conter senhas/chaves. Não publique seu conteúdo no GitHub.
EOF
}
run_backup() {
    preflight backup
    out=$(mktemp -d "$dest/BTT-backup-$(date +%Y-%m-%d_%H-%M-%S)-XXXXXX")
    state PREPARING
    cp "$printer_json" "$out/printer-before.json"
    cp /etc/fstab "$out/fstab.txt"
    cp "${BASH_SOURCE[0]}" "$out/backup-script.sh"
    lsblk -o NAME,PATH,SIZE,FSTYPE,UUID,MOUNTPOINT,MODEL,TRAN >"$out/disks.txt"
    findmnt >"$out/mounts.txt"
    dpkg-query -W >"$out/packages.txt"
    sfdisk -d "$root_disk" >"$out/partition-table.sfdisk"
    sfdisk --json "$root_disk" >"$out/partition-table.json"
    write_restore_notes
    local unit prefix_sectors
    for unit in tablet-usb-watchdog.service KlipperScreen.service moonraker.service klipper.service; do
        if systemctl is-active --quiet "$unit"; then active+=("$unit"); fi
    done
    printf '%s\n' "${active[@]}" >"$out/services-active-before.txt"
    printer_check
    state CAPTURING
    services_touched=1
    if ((${#active[@]})); then systemctl stop "${active[@]}"; fi
    sync
    prefix_sectors=$(python3 - "$out/partition-table.json" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))["partitiontable"]
assert p.get("sectorsize", 512) == 512
n = min(x["start"] for x in p["partitions"])
assert 0 < n <= 131072, "Prefixo de boot fora do perfil validado"
print(n)
PY
)
    dd if="$root_disk" of="$out/boot-prefix.bin" bs=512 count="$prefix_sectors" status=none
    dd if="$boot_device" bs=1M status=none | gzip -1 >"$out/boot-partition.img.gz"
    log 'Copiando a raiz; a pasta cresce durante esta etapa. Aguarde.'
    local compressor=(gzip -1)
    if command -v pigz >/dev/null; then compressor=(pigz -1 -p 2); fi
    printf '%s\n' "${compressor[*]}" >"$out/compressor.txt"
    set +e
    tar --one-file-system --acls --xattrs --numeric-owner --sparse \
        --exclude=./dev --exclude=./proc --exclude=./sys --exclude=./run \
        --exclude=./tmp --exclude=./mnt --exclude=./media --exclude=./lost+found \
        -C / -cpf - . 2>"$out/root-tar.log" | "${compressor[@]}" | split -b 1900M -d -a 3 - "$out/root.tar.gz.part-"
    local pipeline=("${PIPESTATUS[@]}")
    set -e
    printf '%s\n' "${pipeline[*]}" >"$out/root-pipeline-status.txt"
    [[ ${pipeline[*]} == '0 0 0' ]] || die 'Falha/arquivos mudando na captura; consulte root-tar.log. Cópia não validada.'
    restore_services
    state VALIDATING
    gzip -t "$out/boot-partition.img.gz"
    cat "$out"/root.tar.gz.part-* | gzip -t
    cat "$out"/root.tar.gz.part-* | tar -tzf - >"$out/root-inventory.txt"
    grep -q '^./etc/' "$out/root-inventory.txt"
    grep -q '^.<DeviceHome>/KlipperScreen/' "$out/root-inventory.txt"
    (cd "$out"; sha256sum boot-prefix.bin boot-partition.img.gz root.tar.gz.part-* >SHA256SUMS; sha256sum -c SHA256SUMS >checksum-validation.txt)
    du -sh "$out" | tee "$out/size.txt"
    finished=1
}
main() {
    local mode=${1:---start}
    if [[ $mode == --help || $mode == -h ]]; then usage; return; fi
    [[ $# -le 1 ]] || die 'Use uma opção por vez; consulte --help.'
    [[ $(id -u) == 0 ]] || die 'Execute com sudo.'
    case "$mode" in
        --start)
            if systemctl is-active --quiet "$UNIT"; then die 'Backup em andamento; use --status.'; fi
            systemd-run --unit="$UNIT" --collect --property=Nice=10 --property=TimeoutStopSec=180 /bin/bash "$(readlink -f "${BASH_SOURCE[0]}")" --run
            printf 'Backup solicitado. Acompanhe: sudo btt-backup --status\n'
            ;;
        --run) run_backup ;;
        --check) preflight; log 'CHECK_OK: nenhum serviço parado e nenhum backup criado.' ;;
        --status)
            if [[ $(systemctl show -p LoadState --value "$UNIT" 2>/dev/null) == not-found ]]; then
                printf 'Nenhum backup em execução.\n'
            else
                systemctl status "$UNIT" --no-pager || true
            fi
            if [[ -f $STATE_DIR/status.txt ]]; then
                cat "$STATE_DIR/status.txt"
                local last_path
                last_path=$(sed -n 's/^backup=//p' "$STATE_DIR/status.txt")
                if [[ $last_path == "$MOUNT_POINT"/BTT-backup-* && -d $last_path ]]; then
                    printf '\nTamanho gravado até agora:\n'
                    du -sh -- "$last_path" || true
                fi
            fi
            if [[ -f $STATE_DIR/last-result.txt ]]; then printf '\nÚltima execução concluída:\n'; cat "$STATE_DIR/last-result.txt"; fi
            journalctl -u "$UNIT" -n 15 --no-pager || true
            ;;
        --stop) systemctl stop "$UNIT" ;;
        *) usage; die "Opção desconhecida: $mode" ;;
    esac
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
