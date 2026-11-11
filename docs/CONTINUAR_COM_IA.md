# Continue or reproduce with AI assistance

This material is organized so that a person **or an AI with suitable tools** can understand the result and perform the steps. With a terminal, authorized SSH access, a password/sudo when needed, and ADB access to the tablet, another AI can perform the same diagnosis and configuration. The result must be verified on hardware: copying commands or assuming that every Android device is identical is insufficient.

A text-only AI can provide guidance, but someone must run the commands. Even an AI with a terminal may need a person to enable debugging, accept USB authorization, connect the cable, and test physical touch. Share credentials only through the appropriate channel in your session; never commit them to the repository.

## Prompt to give another AI

> I want to use an Android tablet as a KlipperScreen panel over USB/ADB. Read README.md, docs/COMECE_AQUI.md, docs/TABLET_TESTADO.md, and docs/FAQ.md before acting. Use docs/INSTALACAO.md and docs/TOUCH.md for specific fixes. Inspect the real state of my BTT and tablet; do not assume the serial, UID, VID/PID, or paths match the documented NT-1710 sample. Back up files before changes, perform one step at a time, and check expected output. Preserve Klipper, Moonraker, and peripherals outside the panel. Do not trigger movement, heating, or extrusion when testing the interface. Do not clear Android data to fix errors without discussing the impact. Prefer the XSDL touch menu; use the binary patch only when it validates the profile. At the end, separate what is proven from what still needs testing. Do not send passwords, tokens, or private backups to GitHub.

## Information the AI must collect

| Question | How to verify |
|---|---|
| What is the correct host? | Owner-provided IP/SSH and the system response |
| Is KlipperScreen already present? | Directories, `systemctl cat`, and service state |
| Which USB device is the tablet? | `lsusb` and `adb devices -l`, preserving other devices |
| What are the Android/ABI values? | `getprop` on the selected device |
| Is internal app access available? | `adb shell id` and permissions; do not assume root |
| Does the display server respond? | ADB forwarding and `xset -display :100 -q` |
| Is touch direct? | SDL configuration and physical confirmation from the person |
| What was actually validated? | Logs, file comparison, image, and user feedback |

## Stop-and-investigate points

- Different serial: adapt the launcher; do not select another USB device by mistake.
- Different VID/PID: review the udev rule before installing it.
- Rejected binary configuration: use the menu or study the version without removing safeguards.
- Android access denied: do not assume root-based repairs will work.
- XKB/TLS errors: consult the FAQ and files from the same APK version.
- Active service without an image: check X11 and the screen before declaring success.

The goal is understandable, verifiable execution. Record adaptations and new results so the next person can follow them.
