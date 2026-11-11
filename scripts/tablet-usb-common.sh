#!/bin/bash
# Functions shared by the launcher and supervisor. No printer commands.
TABLET_SERIAL=${TABLET_SERIAL:-"<DeviceSerialNumber>"}
TABLET_USER=${TABLET_USER:-"<DeviceUser>"}
TABLET_HOME=${TABLET_HOME:-"<DeviceHome>"}
TABLET_DISPLAY=${TABLET_DISPLAY:-:100}
TABLET_KEEP_FOREGROUND=${TABLET_KEEP_FOREGROUND:-1}
if [[ $TABLET_SERIAL == '<DeviceSerialNumber>' || $TABLET_USER == '<DeviceUser>' || $TABLET_HOME == '<DeviceHome>' ]]; then
    echo 'Configure TABLET_SERIAL, TABLET_USER and TABLET_HOME in tablet-usb-common.sh before starting.' >&2
    exit 1
fi
tablet_as_user() {
    if [[ $(id -u) == 0 ]]; then
        setpriv --reuid "$TABLET_USER" --regid "$TABLET_USER" --init-groups env HOME="$TABLET_HOME" ANDROID_SERIAL="$TABLET_SERIAL" "$@"
    else
        env ANDROID_SERIAL="$TABLET_SERIAL" "$@"
    fi
}
tablet_adb() { tablet_as_user timeout 12 adb -s "$TABLET_SERIAL" "$@"; }
tablet_online() { [[ $(tablet_adb get-state 2>/dev/null) == device ]]; }
tablet_booted() { [[ $(tablet_adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r') == 1 ]]; }
tablet_forward() { tablet_adb forward tcp:6100 tcp:6000 >/dev/null 2>&1; }
tablet_x_ready() { tablet_as_user timeout 12 xset -display "$TABLET_DISPLAY" -q >/dev/null 2>&1; }
tablet_foreground() {
    tablet_adb shell dumpsys window windows 2>/dev/null | grep 'mCurrentFocus=' | grep -q 'x.org.server/'
}
tablet_open() {
    local power
    power=$(tablet_adb shell dumpsys power 2>/dev/null)
    if grep -Eq 'mScreenOn=false|mWakefulness=Asleep' <<<"$power"; then
        tablet_adb shell input keyevent 26 >/dev/null 2>&1 || true
    fi
    if tablet_adb shell dumpsys window policy 2>/dev/null | grep -q 'mShowingLockscreen=true'; then
        tablet_adb shell input keyevent 82 >/dev/null 2>&1 || true
    fi
    tablet_adb shell am start -n x.org.server/.MainActivity >/dev/null 2>&1
}
