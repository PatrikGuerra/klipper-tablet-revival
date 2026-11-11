# Which tablet worked?

The validated device was an **NT-1710**, identified by Android itself. The user confirmed that the interface and touch worked correctly. The commercial brand, RAM quantity, total storage capacity, and manufacturer version were not identified reliably; do not infer them from the model name alone.

| Characteristic | Confirmed value |
|---|---|
| Android model | `NT-1710` |
| Internal device name | `NT-1710` |
| Product | `nuclear_basic` |
| Android | **4.2.2** |
| ABI | `armeabi-v7a` — 32-bit ARM |
| USB identification | `18d1:0003`, described by Linux as Android/AllWinner |
| ADB serial for this unit | `<DeviceSerialNumber>` — another unit will have its own serial |
| Android surface | 800 × 480 pixels |
| App/X11 surface | 800 × 444 pixels, with the Android bar using the remaining strip |
| Working XServer XSDL | **1.11.40** |
| Failed XServer XSDL | 1.20.51: APK installed but the X server did not start |
| Pre-existing ADB access | Shell returned `uid=0(root)`; this project did not root the device |
| Final touch | Absolute movement and normal click, without touchpad emulation |
| SDL calibration | `[0, 0, 0, 0]`, preserved |

The pre-existing root access was important for repairing internal application files. This does not mean every Android 4.2.2 tablet allows the same commands.

## Host used with it

BTT Pi/CB1, BTT-CB1 2.3.4 image, Debian 11 Bullseye ARM64, about 1 GB of RAM. Klipper, Moonraker, and KlipperScreen were already installed. A data-capable USB cable was used; power was not changed.

## What was confirmed in practice

1. Linux recognized the USB tablet.
2. ADB showed `device` after permissions were corrected.
3. The XServer responded through USB forwarding.
4. KlipperScreen displayed menus and temperatures received from Moonraker.
5. After disabling touchpad mode, the user confirmed correct touch behavior.

Update: real tablet and BTT reboots were performed, with automatic interface recovery after installing the supervisor. See [automatic reconnection](RECONEXAO.md). Physical cable removal/reconnection, many-hours operation, and testing with Wi-Fi disabled are still unproven. The configured graphics connection uses USB even if Android is also connected to Wi-Fi.

## How to compare your tablet

On the BTT, with ADB installed and the tablet authorized, run:

```sh
adb devices -l
TABLET_SERIAL='serial-exibido-pelo-adb'
adb -s "$TABLET_SERIAL" shell getprop ro.product.model
adb -s "$TABLET_SERIAL" shell getprop ro.product.device
adb -s "$TABLET_SERIAL" shell getprop ro.product.name
adb -s "$TABLET_SERIAL" shell getprop ro.build.version.release
adb -s "$TABLET_SERIAL" shell getprop ro.product.cpu.abi
adb -s "$TABLET_SERIAL" shell id
```

If Android, ABI, or permissions differ, treat it as a different environment. Use the XSDL menu to configure touch; this repository's binary patch is restricted to the tested profile.
