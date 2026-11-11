# Advanced XServer XSDL repairs

For a new installation, follow only [the main guide](COMECE_AQUI.md). The procedures below record **specific failures** on the tested NT-1710. They are not required steps. Use them only after confirming the same error, APK version and device state. Do not clear app data or downgrade without preserving the current installation.

Run all commands on the BTT over SSH. After `adb devices -l`, set `TABLET_SERIAL='serial-shown-by-adb'` in the same shell. XSDL must already be installed. If X11 does not respond, check [the final section](#x11-does-not-respond).

## Before changing internal files

**Requires pre-existing ADB root shell on the tablet.** The tested unit returned `uid=0(root)`; this project did not root it. If `adb shell id` does not return `uid=0`, **stop here**. No rootless method for writing internal app files was validated. Try a clean XSDL-supported installation or investigate another approach; do not run these commands without access.

```sh
adb -s "$TABLET_SERIAL" shell id
adb -s "$TABLET_SERIAL" shell ls -ld /data/data/x.org.server/files
```

Before **either** repair, stop the app and make a unique backup. Confirm `adb pull` and `tar -tf` succeed before changing anything. Restoring this entire TAR has not been tested.

```sh
mkdir -p ~/tablet-xsdl
backup_dir=$(mktemp -d "$HOME/tablet-xsdl/repair.XXXXXXXX")
android_backup="xsdl-before-repair-$(date -u +%Y%m%dT%H%M%SZ)-$$.tar"
adb -s "$TABLET_SERIAL" shell am force-stop x.org.server
adb -s "$TABLET_SERIAL" shell busybox tar -cf "/sdcard/$android_backup" -C /data/data/x.org.server files
adb -s "$TABLET_SERIAL" pull "/sdcard/$android_backup" "$backup_dir/$android_backup"
tar -tf "$backup_dir/$android_backup" >/dev/null
echo "Backup: $backup_dir/$android_backup"
```

## Old Android TLS and fonts

On the tested tablet, XSDL 1.11.40 requested `xfonts.tgz` over HTTP, was redirected to HTTPS, and failed with `SSLHandshakeException / unsupported protocol`. The BTT downloaded the official archive. Compare its recorded hash in [checksums.sha256](../checksums.sha256) before transferring it.

```sh
curl -fL --connect-timeout 15 --max-time 180 \
  -o ~/tablet-xsdl/xfonts.tar.gz \
  https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/xfonts.tgz
sha256sum ~/tablet-xsdl/xfonts.tar.gz
adb -s "$TABLET_SERIAL" push ~/tablet-xsdl/xfonts.tar.gz /data/local/tmp/xfonts.tar.gz
adb -s "$TABLET_SERIAL" shell 'busybox gunzip -c /data/local/tmp/xfonts.tar.gz | busybox tar -xf - -C /data/data/x.org.server/files'
```

This Android's BusyBox did not support `tar -z`. The font tree contains symbolic links, so extraction to external Android storage failed. In the original session extraction was interrupted; the resulting tree let XSDL run, but the completeness of every font was **not** audited. For a reproduction, wait for extraction to finish and inspect errors.

Only after confirming the fonts, create the marker required by this version. Its content is the **full specification without a newline**, not just a URL:

```sh
printf %s :xfonts.tar.gz:http://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/xfonts.tgz/download > ~/tablet-xsdl/libsdl-DownloadFinished-2.flag
adb -s "$TABLET_SERIAL" push ~/tablet-xsdl/libsdl-DownloadFinished-2.flag /sdcard/Android/data/x.org.server/files/
```

The marker name, index and format are specific to 1.11.40. If the destination directory is absent, stop and verify the installed version.

## XKB error after a version change

In the original installation, 1.20.51 failed with `X server failed to launch`. Downgrading to 1.11.40 with `adb install -r -d` preserved incompatible data, followed by `XKB: Couldn't compile keymap` and `Failed to activate core devices`. **Do not perform that downgrade as an initial test.** Start with 1.11.40 on the NT-1710.

Only if the same error occurs **after the backup above**, extract files from the already-downloaded 1.11.40 APK. Confirm it is the APK installed on the tablet and note the current owner of the internal directory:

```sh
adb -s "$TABLET_SERIAL" shell ls -ld /data/data/x.org.server/files
unzip -p ~/tablet-xsdl/XServer-XSDL-1.11.40.apk assets/data-1.tgz > "$backup_dir/data-1.tgz"
mkdir -p "$backup_dir/data-old"
tar -xzf "$backup_dir/data-1.tgz" -C "$backup_dir/data-old"
unzip -p ~/tablet-xsdl/XServer-XSDL-1.11.40.apk assets/binaries-armeabi-v7a.zip > "$backup_dir/binaries-old.zip"
unzip -p "$backup_dir/binaries-old.zip" usr/bin/xkbcomp > "$backup_dir/xkbcomp-old"
```

Stop if extraction failed or the expected files are missing. The original session needed `chown 10076:10076` for restored internal files. **This UID/GID is not universal.** Set the owner observed on your tablet before copying; the condition below prevents copying when the sample value is unchanged:

```sh
APP_OWNER='observed-uid:gid'
if [[ $APP_OWNER =~ ^[0-9]+:[0-9]+$ ]]; then
    adb -s "$TABLET_SERIAL" push "$backup_dir/data-old/usr" /data/data/x.org.server/files/ &&
    adb -s "$TABLET_SERIAL" shell mv /data/data/x.org.server/files/usr/bin/xkbcomp /data/data/x.org.server/files/usr/bin/xkbcomp.pre-repair &&
    adb -s "$TABLET_SERIAL" push "$backup_dir/xkbcomp-old" /data/data/x.org.server/files/usr/bin/xkbcomp &&
    adb -s "$TABLET_SERIAL" shell chmod 755 /data/data/x.org.server/files/usr/bin/xkbcomp &&
    adb -s "$TABLET_SERIAL" shell busybox chown -R "$APP_OWNER" /data/data/x.org.server/files/usr &&
    adb -s "$TABLET_SERIAL" shell ls -ld /data/data/x.org.server/files/usr
else
    echo 'Set APP_OWNER to the observed numeric UID:GID before copying files.' >&2
fi
```

App data was not cleared. The saved `xkbcomp.pre-repair` links to the previous installation and is not a guaranteed rollback.

## X11 does not respond

With XSDL open, the final display responded at `:0` (port 6000):

```sh
adb -s "$TABLET_SERIAL" forward tcp:6100 tcp:6000
timeout 8 xset -display :100 -q
adb -s "$TABLET_SERIAL" shell netstat -lnt
adb -s "$TABLET_SERIAL" logcat -d -t 200 | grep -E 'XSDL|XKB|Fatal|setenv DISPLAY'
```

During failures XSDL tried `:1`, `:2` and `:3` (ports 6001–6003). An old `xsel` process also held port 6000; it was identified and stopped by its actual PID. Inspect ports and logs **before** changing forwarding or stopping processes. A successful `xset` response proves X11, not visible image or touch.
