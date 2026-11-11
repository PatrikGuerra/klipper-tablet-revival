#!/bin/bash
# Uso: bash scripts/diagnostico.sh [serial-adb]
# A consulta ADB pode iniciar o daemon local; não modifica o Android.
serial=${1:-${TABLET_SERIAL:-}}
cat /etc/os-release
uname -m
df -h /
free -h
systemctl is-active klipper moonraker KlipperScreen
lsusb
if command -v adb >/dev/null; then
    adb devices -l
    adb forward --list
    if [[ -n $serial ]]; then
        adb -s "$serial" shell getprop ro.product.model
        adb -s "$serial" shell getprop ro.build.version.release
        adb -s "$serial" shell getprop ro.product.cpu.abi
    else
        echo 'Passe o serial ADB para consultar os dados do tablet.' >&2
    fi
fi
if command -v xset >/dev/null; then
    timeout 8 xset -display :100 -q
fi
journalctl -u KlipperScreen -n 20 --no-pager
