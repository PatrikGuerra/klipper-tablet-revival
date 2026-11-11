# Common problems

Follow the [main guide](COMECE_AQUI.md) first. Use this page to choose the next check; specific repair procedures are linked below.

| Symptom or question | What to check |
|---|---|
| `btt.local` does not resolve | Find the BTT's current IP in your router or network settings. The name did not resolve in the original session. |
| `adb devices -l` is empty | A **data-capable** cable, USB port, unlocked tablet and USB debugging. Do not proceed to XSDL before ADB works. |
| `unauthorized` | Accept the ADB authorization prompt on the tablet. |
| `no permissions` | Check VID/PID, `plugdev` membership, the [device-specific udev rule and ADB daemon restart](COMECE_AQUI.md#3-fix-usb-permissions-only-if-needed). This repository's rule is only for `18d1:0003`. |
| XSDL 1.20.51 installs but does not start | This happened on the NT-1710. Start with **1.11.40** on this model; the exact cause of the newer version's failure was not isolated. Do not downgrade over existing data without a backup. |
| `xfonts.tgz` fails with TLS/HTTPS | The old Android did not negotiate the HTTPS redirect. See the [font repair](INSTALACAO.md#old-android-tls-and-fonts), which requires pre-existing root access to the app. |
| `XKB: Couldn't compile keymap` | The original downgrade left incompatible files. See the [XKB repair](INSTALACAO.md#xkb-error-after-a-version-change); it is not a normal installation step. |
| `xset` does not respond | Check XSDL, [display/port and logs](INSTALACAO.md#x11-does-not-respond). `:0` uses port 6000; do not stop a process using a PID copied from another device. |
| Touch behaves like a touchpad or is offset | Choose **Desktop, No Emulation**. If that fails on the validated profile, see [TOUCH.md](TOUCH.md); do not force scaling because of the 800×480/800×444 difference alone. |
| Service is `active`, but the interface is absent | Check `adb forward --list`, `xset -display :100 -q`, logs and the **physical screen**. Service state does not prove rendering or touch. |
| The screen goes blank | X11 blanking is separate from Android settings. The launcher applies `xset s off`; check `timeout: 0` in `xset -q` and review Android locking. |
| Is root or a custom APK required? | No APK was created and the device was not rooted by this project. The unit already had an ADB root shell; only [internal repairs](INSTALACAO.md) and the [touch patch](TOUCH.md) depend on it. No rootless internal repair was validated. |
| Is Wi-Fi needed for the image? | The configured transport is ADB/USB; SSH uses the network only to administer the BTT. The tablet's Wi-Fi was on, so an isolated Wi-Fi-off test remains open. |
| Does it reconnect automatically? | Tablet and BTT reboots passed with the [supervisor](RECONEXAO.md). Physical cable removal, power loss, PIN locks, disabled debugging and revoked authorization are untested/not automatically fixed. |

The [tested NT-1710](TABLET_TESTADO.md) is a confirmed example, not a universal compatibility guarantee. A private repository is readable only to people with access, regardless of its topics.
