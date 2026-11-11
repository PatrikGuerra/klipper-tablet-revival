# Diagnosis and rollback

For symptoms, use the [FAQ](FAQ.md). On the BTT, use the serial shown by `adb devices -l` and run the read-only diagnostic script (its ADB queries may start the local daemon):

```sh
TABLET_SERIAL='serial-shown-by-adb'
bash scripts/diagnostico.sh "$TABLET_SERIAL"
```

## Disable the integration

Stop the supervisor first so it cannot reopen XSDL. The custom launcher did not exist **on the tested BTT**. On another installation, restore its original launcher from the backup directory displayed by the [main guide](COMECE_AQUI.md) or [supervisor setup](RECONEXAO.md). Do not delete a third-party configuration.

```sh
sudo systemctl disable --now tablet-usb-watchdog
sudo systemctl stop KlipperScreen
mkdir -p ~/tablet-xsdl
backup_dir=$(mktemp -d "$HOME/tablet-xsdl/rollback.XXXXXXXX")
mv ~/KlipperScreen/scripts/launch_KlipperScreen.sh "$backup_dir/"
echo "Disabled launcher: $backup_dir"
sudo systemctl start KlipperScreen
```

Without the custom launcher, behavior again depends on the existing `KlipperScreen-start.sh` and prior configuration. If the service fails, inspect `journalctl -u KlipperScreen -n 40 --no-pager` and the relevant backup. To remove the device-specific USB rule, move it outside `/etc/udev/rules.d`, reload udev, and reconnect only the tablet. Do not automatically uninstall ADB; it may still be useful.

## Android backups

- Previous touch settings: `touch-settings-before.cfg` on the BTT; see [TOUCH.md](TOUCH.md).
- Before XSDL repair, the [repair guide](INSTALACAO.md) creates a unique TAR on `/sdcard` and copies it to the BTT. Full restore was not tested.
- `xkbcomp.pre-repair`, if created, points to the prior installation; it is not a guaranteed working rollback.

Never restore a full TAR over a running app. Inspect its contents, ownership and version first. Wi-Fi-off, physical cable disconnection and long-duration operation remain untested; BTT/tablet reboots and XSDL recovery were tested.
