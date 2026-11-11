# Direct touch: diagnosis and correction

## What was wrong

The user reported imprecise touch. The Android display was 800×480, while XSDL's usable X11 area was 800×444 because of the navigation bar. The XInput transform was the identity matrix and SDL calibration `[0, 0, 0, 0]` was left alone. The actual problem was `RelativeMouseMovement=true` (touchpad mode) and `LeftClickMethod=7` (touch/timeout click). We changed only these to absolute movement (`false`) and normal click (`0`). The user confirmed correct touch afterward. Do not scale coordinates merely to fill 800×480.

## Preferred fix: XSDL menu

At XSDL startup select **Change Device Configuration → Mouse Emulation Mode → Desktop, No Emulation**. Labels vary across releases. Prefer this on other devices; the binary patch below applies only to the observed configuration format.

## Guarded patch for the tested profile

The file `/data/data/x.org.server/files/libsdl-settings.cfg` uses Java `ObjectOutputStream` primitive blocks. The observed file had 1,552 bytes, format version 5 and 1,538 primitive-data bytes. Logical offsets 41 and 1457 held the click method and relative-movement flag. These are offsets in concatenated primitive data, **not** raw file positions. The layout was checked against the original project's `Settings.java`, `SettingsMenuMouse.java` and `Mouse.java`.

`scripts/patch_touch.py` makes only the same two changes. It rejects unexpected versions, sizes, offsets and modes, and refuses to overwrite an existing output. It is not a universal SDL settings editor.

The following requires **pre-existing ADB root shell**; this project did not root the tablet. If `id` is not `uid=0(root)`, stop. Use the serial from `adb devices -l`, and note the file's actual UID:GID before writing:

```sh
TABLET_SERIAL='serial-shown-by-adb'
adb -s "$TABLET_SERIAL" shell id
adb -s "$TABLET_SERIAL" shell ls -l /data/data/x.org.server/files/libsdl-settings.cfg
mkdir -p ~/tablet-xsdl
backup_dir=$(mktemp -d "$HOME/tablet-xsdl/touch.XXXXXXXX")
adb -s "$TABLET_SERIAL" pull /data/data/x.org.server/files/libsdl-settings.cfg "$backup_dir/touch-settings-before.cfg"
sudo systemctl stop KlipperScreen
adb -s "$TABLET_SERIAL" shell am force-stop x.org.server
adb -s "$TABLET_SERIAL" pull /data/data/x.org.server/files/libsdl-settings.cfg "$backup_dir/touch-settings-current.cfg"
cmp "$backup_dir/touch-settings-before.cfg" "$backup_dir/touch-settings-current.cfg"
```

If `cmp` differs, stop and investigate the concurrent change. Otherwise:

```sh
python3 scripts/patch_touch.py "$backup_dir/touch-settings-current.cfg" "$backup_dir/touch-settings-direct.cfg"
APP_OWNER='observed-uid:gid'
if [[ $APP_OWNER =~ ^[0-9]+:[0-9]+$ ]]; then
    adb -s "$TABLET_SERIAL" push "$backup_dir/touch-settings-direct.cfg" /data/data/x.org.server/files/libsdl-settings.cfg &&
    adb -s "$TABLET_SERIAL" shell chown "$APP_OWNER" /data/data/x.org.server/files/libsdl-settings.cfg &&
    adb -s "$TABLET_SERIAL" shell am start -n x.org.server/.MainActivity &&
    sudo systemctl start KlipperScreen
else
    echo 'Set APP_OWNER to the observed numeric UID:GID before applying the patch.' >&2
fi
```

Replace `APP_OWNER` with the observed numeric UID:GID; do not use the literal sample. UID `10076` was specific to the tested tablet. If the patch command or guarded transfer fails, restore the original file from `backup_dir` before restarting the service. The applied file was read back byte-for-byte in the original session; XServer and KlipperScreen then responded, with no manual calibration values.

## Undo only the touch change

Stop KlipperScreen and XSDL, push `touch-settings-before.cfg` from the unique backup directory, restore the real app owner, then restart XSDL and the service. That private backup lives on the BTT, not in this repository.
