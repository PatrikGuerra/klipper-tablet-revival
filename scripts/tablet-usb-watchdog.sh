#!/bin/bash
# Panel supervisor. Does not restart Klipper, Moonraker, or the BTT.
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
        say 'Tablet USB unavailable; waiting for reconnection'
        needs_restart=1
        failed=0
        sleep 10
        continue
    fi
    if ! tablet_booted; then
        say 'Android is starting; waiting for sys.boot_completed=1'
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
    # In the background, SDL can suspend X11: resume the app before
    # concluding that the display server stopped responding.
    if [[ $TABLET_KEEP_FOREGROUND == 1 ]] && ! tablet_foreground; then
        echo 'Restoring XSDL to the foreground (dedicated panel)'
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
                say "USB/X11 connection restored; KlipperScreen restarted; boot=$boot"
                # The first draw is demanding on older Android.
                sleep 20
            else
                say 'Failed to restart KlipperScreen; retrying on the next check'
            fi
        else
            say 'USB/X11 panel available'
        fi
    else
        ((failed+=1))
        if ((failed < 2 && ! needs_restart)); then
            say 'X11 query is slow; waiting for confirmation before recovery'
            sleep 10
            continue
        fi
        needs_restart=1
        say 'XSDL unavailable; recovering the panel'
        now=$(date +%s)
        if ((failed >= 4 && now-last_reset >= 180)); then
            echo 'XSDL did not respond in consecutive checks; reopening only the app'
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
