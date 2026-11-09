#!/bin/bash
# Substituto do launcher inicial: cada consulta tem timeout.
set -u
source /usr/local/lib/tablet-usb-common.sh
while true; do
    if tablet_online && tablet_booted; then
        tablet_forward || true
        if tablet_x_ready; then break; fi
        tablet_open || true
    fi
    sleep 5
done
tablet_as_user timeout 5 xset -display "$TABLET_DISPLAY" s off || true
tablet_as_user timeout 5 xset -display "$TABLET_DISPLAY" -dpms 2>/dev/null || true
export DISPLAY="$TABLET_DISPLAY"
# KS_XCLIENT é definido pela unidade original do KlipperScreen.
if [[ -z ${KS_XCLIENT:-} ]]; then echo 'KS_XCLIENT ausente' >&2; exit 1; fi
exec $KS_XCLIENT
