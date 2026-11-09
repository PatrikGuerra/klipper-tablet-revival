#!/bin/bash
# Backup de arquivos + bootloader para FAT32. Executar como root no BTT validado.
set -Eeuo pipefail
dest=/mnt/btt-backup-usb
[[ $(findmnt -n -o UUID --target "$dest") == 05B1-3EBC ]]
[[ $(findmnt -n -o SOURCE /) == /dev/mmcblk1p2 ]]
[[ $(id -u) == 0 ]]
mkdir "$dest/BTT-backup-2026-11-09-before-autoconnect"
out="$dest/BTT-backup-2026-11-09-before-autoconnect"
exec >"$out/progress.log" 2>&1
date -Is
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT,MODEL >"$out/disks.txt"
findmnt >"$out/mounts.txt"
dpkg-query -W >"$out/packages.txt"
sfdisk -d /dev/mmcblk1 >"$out/partition-table.sfdisk"
sfdisk --json /dev/mmcblk1 >"$out/partition-table.json"
curl -fsS --max-time 8 'http://127.0.0.1:7125/printer/objects/query?print_stats&idle_timeout' >"$out/printer-before.json"
python3 -c 'import json,sys; s=json.load(open(sys.argv[1]))["result"]["status"]; assert s["print_stats"]["state"] not in ("printing","paused"); assert s["idle_timeout"]["state"]!="Printing"' "$out/printer-before.json"
units=(klipper.service moonraker.service KlipperScreen.service)
active=()
for unit in "${units[@]}"; do
    if systemctl is-active --quiet "$unit"; then active+=("$unit"); fi
done
printf '%s\n' "${active[@]}" >"$out/services-active-before.txt"
restore_services() {
    result=$?
    trap - EXIT
    if ((${#active[@]})); then systemctl start "${active[@]}" || result=1; fi
    printf 'exit=%s\n' "$result" >"$out/RESULT.txt"
    sync
    exit "$result"
}
trap restore_services EXIT
systemctl stop "${active[@]}"
sync
dd if=/dev/mmcblk1 of="$out/boot-prefix.bin" bs=1M count=4 status=none
dd if=/dev/mmcblk1p1 bs=1M status=none | gzip -1 >"$out/boot-partition.img.gz"
echo 'ROOT_ARCHIVE_START'
set +e
tar --one-file-system --acls --xattrs --numeric-owner --sparse \
    --exclude=./dev --exclude=./proc --exclude=./sys --exclude=./run \
    --exclude=./tmp --exclude=./mnt --exclude=./media --exclude=./lost+found \
    -C / -cpf - . 2>"$out/root-tar.log" | gzip -1 | split -b 1900M -d -a 3 - "$out/root.tar.gz.part-"
pipeline=("${PIPESTATUS[@]}")
set -e
printf '%s\n' "${pipeline[*]}" >"$out/root-pipeline-status.txt"
[[ ${pipeline[1]} == 0 && ${pipeline[2]} == 0 && ${pipeline[0]} -le 1 ]]
# tar 1 pode indicar arquivos alterados no sistema em execução: registrar e revisar.
echo 'ROOT_ARCHIVE_FINISHED'
systemctl start "${active[@]}"
echo 'VALIDATION_START'
gzip -t "$out/boot-partition.img.gz"
cat "$out"/root.tar.gz.part-* | gzip -t
cat "$out"/root.tar.gz.part-* | tar -tzf - >"$out/root-inventory.txt"
grep -q '^./etc/' "$out/root-inventory.txt"
grep -q '^.<DeviceHome>/KlipperScreen/' "$out/root-inventory.txt"
(cd "$out"; sha256sum boot-prefix.bin boot-partition.img.gz root.tar.gz.part-* >SHA256SUMS; sha256sum -c SHA256SUMS >checksum-validation.txt)
echo 'BACKUP_VALIDATED'
date -Is
