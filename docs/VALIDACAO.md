# Validation of the published material

## Installation evidence

- `adb devices -l` showed the NT-1710 in `device` state.
- `xset -display :100 -q` responded through USB forwarding.
- `systemctl is-active KlipperScreen klipper moonraker` reported all three active.
- KlipperScreen logs showed printer initialization and temperature reads.
- A real Android screenshot is included at [images/klipperscreen-usb.png](images/klipperscreen-usb.png).
- After the touch correction, the user physically confirmed correct behavior.

## Original script checks

Copies of the then-published scripts were sent to `<DeviceHome>/tablet-xsdl` for verification, without replacing the active launcher:

```sh
bash -n ~/tablet-xsdl/launch_KlipperScreen.sh
bash -n ~/tablet-xsdl/diagnostico.sh
python3 -m py_compile ~/tablet-xsdl/patch_touch.py
python3 ~/tablet-xsdl/patch_touch.py ~/tablet-xsdl/touch-settings-before.cfg /tmp/revival-verify-20261109-a.cfg
cmp /tmp/revival-verify-20261109-a.cfg ~/tablet-xsdl/touch-settings-direct.cfg
python3 ~/tablet-xsdl/patch_touch.py /tmp/revival-verify-20261109-a.cfg /tmp/revival-verify-20261109-b.cfg
cmp /tmp/revival-verify-20261109-a.cfg /tmp/revival-verify-20261109-b.cfg
```

These checks passed. The patch produced **the same bytes** as the settings confirmed by the user; reapplying it did not change the output. The real `.cfg` files were not published. This did not exercise printer controls.

The entire guide was not rerun from scratch, which would require another tablet or reinstall. The diagnostic script's syntax was checked, but the full script was not rerun as a separate hardware test. Tablet/BTT reboots were later tested under [automatic reconnection](RECONEXAO.md). Physical cable removal and long-duration operation remain open. See [history](HISTORICO.md) for the difference between the planned and actual paths.

## Checking an installation today

After the original tests, the three installed supervisor scripts matched the repository files **at that time**. Those hashes predate anonymization and this documentation revision, so they cannot establish that a current installation uses this commit. The installed common script also intentionally differs because it contains the local user/serial/path configuration.

From the repository root on the BTT, check current files:

```sh
printf '%s\0' scripts/*.sh | xargs -0 -n 1 bash -n
python3 -m py_compile scripts/patch_touch.py
sha256sum scripts/*.sh /usr/local/bin/tablet-usb-watchdog.sh /usr/local/lib/tablet-usb-common.sh
diff -u scripts/tablet-usb-watchdog.sh /usr/local/bin/tablet-usb-watchdog.sh
diff -u scripts/tablet-usb-common.sh /usr/local/lib/tablet-usb-common.sh
```

The common-script diff should show only configured local values. Compare the installed launcher with `scripts/launch_KlipperScreen-autoconnect.sh`, or with `scripts/launch_KlipperScreen.sh` if still using the initial one (expect the serial assignment to differ). In the original test, supervisor, KlipperScreen, Klipper and Moonraker were active; the Android foreground window was `x.org.server/.MainActivity` and the final screenshot showed the connected interface.
