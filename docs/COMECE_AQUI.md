# Start here: from connected tablet to working interface

The BTT runs KlipperScreen; the Android tablet displays its X11 interface and receives touch input over USB. This is the **only normal installation path**. Use [advanced repairs](INSTALACAO.md) only for a matching error. The [implementation history](HISTORICO.md) records what happened on the original device; it is not a checklist for new installations.

## Before you begin

You need a BTT with Klipper, Moonraker and KlipperScreen already running. If KlipperScreen is missing, follow its [official installation guide](https://klipperscreen.readthedocs.io/en/latest/Installation/) first. You also need an Android tablet, a data-capable USB cable, SSH/sudo access to the BTT, and access to this repository. Unlock the tablet when asked.

`<DeviceUser>`, `<DeviceHostIp>` and `<DeviceSerialNumber>` are redacted values from the tested setup. Use **your** device's values. Keep the same SSH session through the steps below; if you reconnect, set `TABLET_SERIAL` again.

| Where | What happens |
|---|---|
| Your computer | Open SSH to the BTT |
| BTT SSH terminal | Inspect USB, install ADB/XSDL, configure the launcher |
| Tablet screen | Enable debugging, authorize ADB, select direct touch |

## 1. Check the BTT

On your computer, set your SSH values before connecting:

```sh
BTT_USER='your-user'
BTT_HOST='btt-ip-address'
ssh "$BTT_USER@$BTT_HOST"
```

On the BTT:

```sh
git clone https://github.com/PatrikGuerra/klipper-tablet-revival.git
cd ~/klipper-tablet-revival
cat /etc/os-release
systemctl is-active klipper moonraker KlipperScreen
lsusb
```

All three services should be `active`; `lsusb` should show the tablet. The tested device was `18d1:0003`. If yours has another VID/PID, **do not install this repository's USB rule unchanged**. Leave unrelated USB devices alone. If the repository directory already exists, enter it and inspect `git status` instead of cloning over it. Do not save GitHub tokens in scripts or clone URLs.

## 2. Authorize ADB

On the tablet, enable **Developer options → USB debugging**, connect the cable, and keep the screen unlocked. The menu path depends on the manufacturer. On the BTT:

```sh
command -v adb
```

If ADB is absent:

```sh
sudo apt-get update
sudo apt-get install -y adb
```

Then:

```sh
adb devices -l
TABLET_SERIAL='serial-shown-by-adb'
```

Replace the sample value with the first-column serial. The state must be `device`. For `unauthorized`, accept the authorization prompt on the tablet. For `no permissions`, continue to step 3. For an empty list, check the [FAQ](FAQ.md) before installing anything else.

## 3. Fix USB permissions only if needed

This rule applies **only to `18d1:0003`**. Check that the BTT user belongs to `plugdev`. After changing group membership, reconnect SSH before continuing.

```sh
id
ls -l /etc/udev/rules.d/70-btt-tablet-adb.rules
```

If an existing rule is present, preserve it in a unique directory. The conditional copy is safe when it is absent:

```sh
mkdir -p ~/tablet-xsdl
backup_dir=$(mktemp -d "$HOME/tablet-xsdl/backup.XXXXXXXX")
if [ -e /etc/udev/rules.d/70-btt-tablet-adb.rules ]; then
    sudo cp /etc/udev/rules.d/70-btt-tablet-adb.rules "$backup_dir/"
fi
echo "Backup: $backup_dir"
```

Only when the VID/PID matches:

```sh
sudo install -m 0644 config/70-btt-tablet-adb.rules /etc/udev/rules.d/70-btt-tablet-adb.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --action=add --subsystem-match=usb --attr-match=idVendor=18d1 --attr-match=idProduct=0003
adb kill-server
adb start-server
adb devices -l
```

Stop if the selected tablet still is not `device`. Do not run ADB as root on the BTT to bypass permissions.

## 4. Install XServer XSDL

**1.11.40** worked on the tested NT-1710. There is no reason to install the failed 1.20.51 first.

```sh
mkdir -p ~/tablet-xsdl
curl -fL --connect-timeout 15 --max-time 180 \
  -o ~/tablet-xsdl/XServer-XSDL-1.11.40.apk \
  https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/XServer-XSDL-1.11.40.apk
sha256sum ~/tablet-xsdl/XServer-XSDL-1.11.40.apk
```

The recorded SHA-256 is `69e015154e115465a27495a624a3445544886ba05fd16068a73738a0c19848e2`. If it differs, stop and inspect the download. If XSDL is not installed:

```sh
adb -s "$TABLET_SERIAL" install ~/tablet-xsdl/XServer-XSDL-1.11.40.apk
adb -s "$TABLET_SERIAL" shell am start -n x.org.server/.MainActivity
```

Installation should say `Success`. Allow time for first-run data/fonts. For a font/HTTPS error, see [the specific repair](INSTALACAO.md#old-android-tls-and-fonts). If another version is already installed, back up its data before considering any downgrade.

## 5. Choose direct touch

On the tablet at XSDL startup, choose **Change Device Configuration → Mouse Emulation Mode → Desktop, No Emulation**. Labels may vary by version. You want absolute pointer movement and normal clicks, not touchpad emulation. If the menu cannot fix the exact tested profile, [TOUCH.md](TOUCH.md) records a guarded patch and rollback; do not apply it to a different configuration format.

## 6. Check X11 over USB

With XSDL open, on the BTT:

```sh
adb -s "$TABLET_SERIAL" forward tcp:6100 tcp:6000
timeout 8 xset -display :100 -q
```

Expected: keyboard, pointer and font information. This proves X11 responds, **not** that KlipperScreen is visible yet. If `xset` is missing, install `x11-xserver-utils`. For timeout or `unable to open display`, use the [FAQ](FAQ.md); do not restart Klipper or Moonraker for an XServer issue.

## 7. Configure KlipperScreen's launcher

On the BTT, inspect the current launcher. Save it if present before installing this repository's initial launcher:

```sh
cd ~/klipper-tablet-revival
ls -l ~/KlipperScreen/scripts/launch_KlipperScreen.sh
backup_dir=$(mktemp -d "$HOME/tablet-xsdl/backup.XXXXXXXX")
if [ -e "$HOME/KlipperScreen/scripts/launch_KlipperScreen.sh" ]; then
    cp "$HOME/KlipperScreen/scripts/launch_KlipperScreen.sh" "$backup_dir/"
fi
echo "Backup: $backup_dir"
install -m 0755 scripts/launch_KlipperScreen.sh ~/KlipperScreen/scripts/launch_KlipperScreen.sh
nano ~/KlipperScreen/scripts/launch_KlipperScreen.sh
```

Change the `export ANDROID_SERIAL=...` assignment to the serial from `adb devices -l`; leave the validation below it unchanged. The launcher refuses the redacted default. Save, then check:

```sh
bash -n ~/KlipperScreen/scripts/launch_KlipperScreen.sh
grep '^export ANDROID_SERIAL' ~/KlipperScreen/scripts/launch_KlipperScreen.sh
systemctl cat KlipperScreen
```

The existing KlipperScreen unit must start `KlipperScreen-start.sh` and provide `KS_XCLIENT`, as in the tested setup. If yours differs, adapt using KlipperScreen's own documentation before restarting:

```sh
sudo systemctl restart KlipperScreen
journalctl -u KlipperScreen -n 30 --no-pager
systemctl is-active KlipperScreen klipper moonraker
```

## 8. Confirm on the screen

The interface should appear on the tablet and connect to the printer. Open **More** and go back to confirm the touch position. Menus are enough; do not move axes, extrude or heat for this first check. On the BTT:

```sh
adb forward --list
xset -display :100 -q
```

Expected: `tcp:6100 tcp:6000`, X11 `timeout: 0`, and visible, responsive menus. The tested XSDL does not support DPMS. Record your model/version and any deviations. For boot recovery, follow the optional [automatic reconnection](RECONEXAO.md) procedure. Physical cable removal, extended operation and Wi-Fi-disabled operation are still untested; use [rollback](MANUTENCAO.md) if needed.
