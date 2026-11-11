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

## Para reproduzir

1. Siga o [guia principal](docs/COMECE_AQUI.md) para chegar à primeira imagem e testar o toque.
2. Se algo falhar, escolha o sintoma na [FAQ](docs/FAQ.md). Os [reparos avançados](docs/INSTALACAO.md) são apenas para erros específicos e alguns exigem root preexistente.
3. Com a interface funcionando, instale a [reconexão automática](docs/RECONEXAO.md), se desejar.

Referência: [tablet testado](docs/TABLET_TESTADO.md), [toque](docs/TOUCH.md), [diagnóstico e rollback](docs/MANUTENCAO.md), [evidências históricas](docs/HISTORICO.md), [validação](docs/VALIDACAO.md), [procedência](docs/REFERENCIAS.md) e [roteiro para IA](docs/CONTINUAR_COM_IA.md).

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

Não há instalador único: a execução por etapas permite conferir cada resultado. Os scripts **exigem configurar serial, usuário e diretório reais**; valores `<Device...>` são apenas marcadores e fazem os launchers falharem de forma explícita. Não foram incluídos senhas, tokens, APKs, backups do sistema ou configurações da impressora. Obtenha binários das fontes oficiais.

## Result and limits

- ADB authorized, XSDL responding over USB, and KlipperScreen connected to Moonraker.
- Direct touch confirmed by the user; X11 screen blanking was disabled during the session.
- The Microsoft webcam remained untouched.
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

## For reproduction

You can follow the guide manually or give it to an AI with terminal tools, authorized SSH access to the BTT, and ADB access to the tablet. [The AI guide](docs/CONTINUAR_COM_IA.md) explains the context and verification points. The AI must verify responses from your own hardware; having the guide does not guarantee compatibility with every tablet.

Repository topics help organize the project. While it remains private, only users with access can find and read its content.

Scripts based on external projects retain the provenance listed in [References](docs/REFERENCIAS.md). This repository documents a specific installation; it does not claim authorship of KlipperScreen or XServer XSDL.
