#!/bin/bash
# Supervisor do painel. Não reinicia Klipper, Moonraker nem o BTT.
set -u
source /usr/local/lib/tablet-usb-common.sh
needs_restart=1
failed=0
last_boot=''
last_state=''
last_open=0
last_reset=0
say() { if [[ $last_state != "$1" ]]; then echo "$1"; last_state=$1; fi; }
while true; do
    if ! tablet_online; then
        say 'Tablet USB indisponível; aguardando reconexão'
        needs_restart=1
        failed=0
        sleep 10
        continue
    fi
    if ! tablet_booted; then
        say 'Android iniciando; aguardando sys.boot_completed=1'
        needs_restart=1
        sleep 10
        continue
    fi
    boot=$(tablet_adb shell cat /proc/sys/kernel/random/boot_id 2>/dev/null | tr -d '\r')
    if [[ -n $boot && $boot != "$last_boot" ]]; then
        last_boot=$boot
        needs_restart=1
        failed=0
    fi
    tablet_forward || true
    # Em segundo plano, SDL pode suspender X11: retomar o aplicativo antes
    # de concluir que o servidor gráfico deixou de responder.
    if [[ $TABLET_KEEP_FOREGROUND == 1 ]] && ! tablet_foreground; then
        echo 'Restaurando XSDL em primeiro plano (painel dedicado)'
        tablet_open || true
        sleep 2
    fi
    if tablet_x_ready; then
        failed=0
        if ((needs_restart)) || ! systemctl is-active --quiet KlipperScreen; then
            tablet_open || true
            tablet_as_user timeout 5 xset -display "$TABLET_DISPLAY" s off || true
            tablet_as_user timeout 5 xset -display "$TABLET_DISPLAY" -dpms 2>/dev/null || true
            if systemctl restart KlipperScreen; then
                needs_restart=0
                say "Conexão USB/X11 restabelecida; KlipperScreen reiniciado; boot=$boot"
                # O primeiro desenho é pesado no Android antigo.
                sleep 20
            else
                say 'Falha ao reiniciar KlipperScreen; nova tentativa na próxima verificação'
            fi
        else
            say 'Painel USB/X11 disponível'
        fi
    else
        ((failed+=1))
        if ((failed < 2 && ! needs_restart)); then
            say 'Consulta X11 lenta; aguardando confirmação antes de recuperar'
            sleep 10
            continue
        fi
        needs_restart=1
        say 'XSDL indisponível; recuperando o painel'
        now=$(date +%s)
        if ((failed >= 4 && now-last_reset >= 180)); then
            echo 'XSDL não respondeu em verificações sucessivas; reabrindo somente o aplicativo'
            tablet_adb shell am force-stop x.org.server || true
            tablet_open || true
            last_reset=$now
            last_open=$now
            failed=0
        elif ((now-last_open >= 30)); then
            tablet_open || true
            last_open=$now
        fi
    fi
    sleep 10
done
