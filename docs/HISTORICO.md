# Implementation record

Date: 2026-11-09, America/Sao_Paulo. This record separates observed results from the original planning ideas. It is **not** the recommended step sequence; use [the main guide](COMECE_AQUI.md) for that.

## Confirmed environment

| Component | Observed value |
|---|---|
| Host | BTT Pi / BTT-CB1 2.3.4 Bullseye image |
| OS | Debian GNU/Linux 11, aarch64, kernel 5.16.17-sun50iw9 |
| User / SSH | `<DeviceUser>`, in `plugdev` and `sudo`; `<DeviceHostIp>` worked, `btt.local` did not resolve |
| RAM / root disk | About 986 MiB RAM; 57 GiB root disk, about 51 GiB free initially |
| Tablet | NT-1710, product `nuclear_basic`, Android 4.2.2, `armeabi-v7a` |
| Tablet USB | VID:PID `18d1:0003`, ADB serial `<DeviceSerialNumber>` |
| Working XSDL | `x.org.server/.MainActivity`, version 1.11.40 |
| KlipperScreen | Already installed, commit `34610ceae31e12a10cc980e20a1dec9976f97dd4` |
| Klipper in logs | `v0.13.0-464-g48f0b3cad` |
| Services | Klipper, Moonraker and KlipperScreen active |

## What actually happened

1. The original plan was treated as a reference, not run blindly. `btt.local` did not resolve; the owner-provided IP allowed SSH.
2. Read-only USB inspection found the tablet, a Microsoft LifeCam VX-500 webcam and a Kingston flash drive. The latter two were not changed.
3. ADB was missing and installed from Debian packages without a general upgrade. The tablet appeared as `no permissions`. A device-specific `18d1:0003` udev rule (`0660`, `plugdev`) fixed permissions; restarting the ADB daemon cleared its stale state. A first rule write lost quotes across shells and was corrected.
4. Official XSDL 1.20.51 installed but reported `X server failed to launch`. Version 1.11.40, cited by the KlipperScreen Android guide for Android 4, was installed with `-r -d`, retaining incompatible data. New installations should **start with 1.11.40** on this hardware.
5. The old Android could not negotiate the font download's HTTPS redirect. The BTT downloaded official fonts and transferred them through ADB. Copying only the archive did not work; extracting to external storage failed on symbolic links. Fonts were placed in the internal app directory. Extraction was interrupted after a long wait; the resulting tree worked, but complete font integrity was not audited.
6. A marker containing only the URL was rejected. The complete version-specific download specification was accepted.
7. X11 files were missing and `xkbcomp` pointed at the prior-version binary. Files from the **same 1.11.40 APK** were restored. An attempted `pm clear` was stopped during review before execution; app data was preserved. An Android TAR backup was made, but full restore was not tested.
8. While XSDL failed, it tried other display numbers, and an old `xsel` held port 6000. The actual process was identified and stopped. The final XSDL listened on display `:0`/port 6000; ADB forwarding and `xset -display :100 -q` responded.
9. A launcher based on KlipperScreen's example set an explicit serial, used a start command compatible with Android 4.2.2, and disabled X11 blanking. The KlipperScreen systemd unit itself was preserved; only that service was restarted.
10. A screen capture showed KlipperScreen menus and Moonraker temperatures. No axis movement, extrusion or heating was triggered.
11. The user's touch report prompted inspection: the XInput matrix was identity, SDL calibration unchanged, and XSDL's usable area 800×444. The problem was relative/touchpad movement and timeout clicking. After backing up settings, only those two values were changed. The user confirmed correct touch.

## Final state and limits

At the end of the first phase, the interface and touch worked, but reboots and reconnection had not yet been tested. Later on the same date, a supervisor was installed and separate BTT/tablet reboots, app recovery and foreground restoration were tested; see [automatic reconnection](RECONEXAO.md). Physical USB cable removal, Wi-Fi-off operation and extended monitoring remain untested. No DroidKlipp, custom APK or power-supply modification was used.

The image [klipperscreen-usb.png](images/klipperscreen-usb.png) predates the touch fix. It proves the interface appeared; the later user confirmation is the evidence for correct physical touch.
