# References and provenance

Credit belongs to the maintainers and contributors of [KlipperScreen](https://github.com/KlipperScreen/KlipperScreen), [SDL Android / XServer XSDL](https://github.com/pelya/commandergenius), [Klipper](https://github.com/Klipper3d/klipper), [Moonraker](https://github.com/Arksine/moonraker) and [Android Platform Tools / ADB](https://developer.android.com/tools/adb). This repository integrates and documents them; it does not replace their authorship, support or licenses.

[DroidKlipp](https://github.com/CodeMasterCody3D/DroidKlipp) appeared in the initial research, but its scripts were not used. A pre-existing VNC app on the tablet was not changed. Neither project is a dependency of this installation.

## Primary sources used

- [KlipperScreen: Android / XServer XSDL / ADB](https://klipperscreen.readthedocs.io/en/latest/Android/) — official launcher example, service setup, mouse guidance and 1.11.40 note for Android 4. Accessed 2026-11-09.
- [KlipperScreen installation](https://klipperscreen.readthedocs.io/en/latest/Installation/) — reference; it was already installed and was not reinstalled.
- [Observed KlipperScreen commit](https://github.com/KlipperScreen/KlipperScreen/tree/34610ceae31e12a10cc980e20a1dec9976f97dd4) and [ADB launcher at that commit](https://github.com/KlipperScreen/KlipperScreen/blob/34610ceae31e12a10cc980e20a1dec9976f97dd4/scripts/sample-android-adb.sh) — source of the adapted launcher, under KlipperScreen's own rights and license.
- [Official SourceForge XServer XSDL downloads](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/) — APKs and fonts: [working 1.11.40](https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/XServer-XSDL-1.11.40.apk), [failed 1.20.51 on this tablet](https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/XServer-XSDL-1.20.51.apk), and [fonts](https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/xfonts.tgz).
- [Android ADB documentation](https://developer.android.com/tools/adb) — USB, installation and port forwarding.
- SDL Android source: [Settings.java](https://github.com/pelya/commandergenius/blob/sdl_android/project/java/Settings.java), [SettingsMenuMouse.java](https://github.com/pelya/commandergenius/blob/sdl_android/project/java/SettingsMenuMouse.java) and [Mouse.java](https://github.com/pelya/commandergenius/blob/sdl_android/project/java/Mouse.java) — settings layout, mouse modes and `LEFT_CLICK_NORMAL=0`. These are consulted branch sources, not a pinned 2016 snapshot.
- [SDL Android DataDownloader.java](https://github.com/pelya/commandergenius/blob/sdl_android/project/java/DataDownloader.java) — investigated the download marker; current source format differs from the old app, so the accepted specification was validated on the tablet.

The initial plan's hypotheses remain in Git history, outside the reproduction path. Where they differ, the [implementation record](HISTORICO.md) and observed evidence take precedence.

This repository contains the session documentation, a udev rule, helper scripts and an adaptation of KlipperScreen's launcher. It redistributes neither APKs nor the complete external source projects. Consult the original project's license before redistributing the launcher outside this context; no new blanket license supersedes third-party rights.
