# Klipper Tablet Revival

> **KlipperScreen on an Android 4.2.2 tablet connected via USB.**

An older Android tablet restored as a KlipperScreen touchscreen panel over **USB**.

Validated on 2026-11-09: BTT Pi/CB1 with Debian 11 ARM64 and an **NT-1710, Android 4.2.2, ARMv7** tablet. The interface appeared on the tablet and the user confirmed correct touch behavior after disabling touchpad emulation.

![KlipperScreen running on the tablet](docs/images/klipperscreen-usb.png)

## Architecture

```text
Klipper + Moonraker → KlipperScreen on the BTT Pi
                              ↓ X11, DISPLAY=:100
                     ADB forward 6100 → 6000
                              ↓ USB cable
                  XServer XSDL 1.11.40 on Android
                              ↑ direct touch
```

SSH is used for administration. The BTT Pi and tablet transport the interface through ADB/USB. This is not HDMI video or mirroring: the tablet renders X11 and KlipperScreen runs on the BTT Pi. The tablet was also connected to Wi-Fi; disabling Wi-Fi for an isolated test was not performed in this session.

## Reproduce it

1. Follow the [main guide](docs/COMECE_AQUI.md) to display the interface and test touch.
2. If something fails, find the symptom in the [FAQ](docs/FAQ.md). [Advanced repairs](docs/INSTALACAO.md) are for specific errors; some require pre-existing root access.
3. Once the interface works, optionally install [automatic reconnection](docs/RECONEXAO.md).

Reference: [tested tablet](docs/TABLET_TESTADO.md), [touch](docs/TOUCH.md), [diagnosis and rollback](docs/MANUTENCAO.md), [implementation history](docs/HISTORICO.md), [validation](docs/VALIDACAO.md), [provenance](docs/REFERENCIAS.md), and [AI handoff](docs/CONTINUAR_COM_IA.md).

## Executable files and configuration

| File | Purpose |
|---|---|
| `scripts/launch_KlipperScreen.sh` | Initial-stage launcher based on the official example; kept as a reference |
| `scripts/diagnostico.sh` | System, ADB, and X11 inspection without installation or printer commands |
| `scripts/patch_touch.py` | Changes only click and relative movement in the validated XSDL Java format; creates a separate file |
| `scripts/launch_KlipperScreen-autoconnect.sh` | Current launcher with Android/X11 waiting and timed queries |
| `scripts/tablet-usb-watchdog.sh` | Panel recovery supervisor started by systemd |
| `scripts/tablet-usb-common.sh` | Shared ADB/X11 functions that select only the tablet |
| `config/70-btt-tablet-adb.rules` | USB permission limited to the observed VID/PID |
| `checksums.sha256` | Observed hashes of official downloads |

There is no one-shot installer: each step has a result you can verify. The scripts **require the real serial, user and home directory**; `<Device...>` values are redacted markers and make launchers fail explicitly. Passwords, tokens, APKs, system backups and printer configuration are not included. Obtain binaries from official sources.

## Result and limits

- ADB authorized, XSDL responding over USB, and KlipperScreen connected to Moonraker.
- Direct touch confirmed by the user; X11 screen blanking was disabled during the session.
- The agent did not trigger axis movement, extrusion, or heating.
- Real tablet and BTT reboots were tested: the interface recovered automatically. [See the procedure and limits](docs/RECONEXAO.md).
- The supervisor is enabled at boot and recovers ADB/XSDL and the KlipperScreen connection.
- Physical USB-cable disconnection and long-duration testing are still unvalidated. Power failures or disabled USB debugging require intervention.

## Credits

This result was made possible by the work of these projects:

| Project | Contribution to this solution |
|---|---|
| [KlipperScreen](https://github.com/KlipperScreen/KlipperScreen) | Interface and official Android/ADB launcher example adapted here |
| [SDL Android / XServer XSDL, by pelya and contributors](https://github.com/pelya/commandergenius) | Android display server and code used to understand touch and downloads |
| [Klipper](https://github.com/Klipper3d/klipper) | Firmware/ecosystem for the controlled printer |
| [Moonraker](https://github.com/Arksine/moonraker) | API connecting KlipperScreen to the printer |
| [Android Platform Tools / ADB](https://developer.android.com/tools/adb) | USB communication and X11 connection forwarding |

Thanks to the maintainers and contributors of these projects. Our contribution is recording the integration, adjustments, and evidence for this hardware. The original projects retain their rights and licenses.

