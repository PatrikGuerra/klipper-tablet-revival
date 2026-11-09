# Referências e procedência

## Fontes primárias usadas

- [KlipperScreen: Android / XServer XSDL / ADB](https://klipperscreen.readthedocs.io/en/latest/Android/) — cópia do launcher de exemplo, início do serviço, orientação de mouse e observação de usar 1.11.40 no Android 4. Página consultada em 09/11/2026.
- [KlipperScreen: instalação](https://klipperscreen.readthedocs.io/en/latest/Installation/) — referência; KlipperScreen já estava instalado e não foi reinstalado.
- [Código do KlipperScreen](https://github.com/KlipperScreen/KlipperScreen) — commit observado `34610ceae31e12a10cc980e20a1dec9976f97dd4`.
- [Launcher ADB no commit observado](https://github.com/KlipperScreen/KlipperScreen/blob/34610ceae31e12a10cc980e20a1dec9976f97dd4/scripts/sample-android-adb.sh) — base do launcher adaptado; o projeto KlipperScreen mantém sua licença e direitos originais.
- [SourceForge oficial: XServer XSDL](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/) — origem dos APKs e fontes.
- [APK 1.11.40](https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/XServer-XSDL-1.11.40.apk) — versão funcional.
- [APK 1.20.51](https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/XServer-XSDL-1.20.51.apk) — versão testada que falhou ao iniciar neste tablet.
- [Arquivo de fontes](https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/xfonts.tgz) — salvo como `xfonts.tar.gz` no BTT.
- [ADB: documentação Android](https://developer.android.com/tools/adb) — transporte USB, instalação e encaminhamento de portas.
- [SDL Android: Settings.java](https://github.com/pelya/commandergenius/blob/sdl_android/project/java/Settings.java) — layout de serialização das configurações; fonte da branch consultada, não snapshot histórico fixado da versão 2016.
- [SDL Android: SettingsMenuMouse.java](https://github.com/pelya/commandergenius/blob/sdl_android/project/java/SettingsMenuMouse.java) — associação entre movimento relativo, clique e modos de emulação.
- [SDL Android: Mouse.java](https://github.com/pelya/commandergenius/blob/sdl_android/project/java/Mouse.java) — constante `LEFT_CLICK_NORMAL=0`.
- [SDL Android: DataDownloader.java](https://github.com/pelya/commandergenius/blob/sdl_android/project/java/DataDownloader.java) — investigação dos marcadores de download. O formato atual difere do antigo; a especificação aceita foi validada no tablet.

## O que não foi utilizado

O roteiro inicial mencionava DroidKlipp, VNC e eventual APK customizado. Não foram instalados, desenvolvidos ou integrados durante esta implementação. O app VNC preexistente no tablet não foi alterado.

O documento original contém recomendações e hipóteses anteriores ao teste. Quando houver divergência, o histórico e a evidência desta instalação prevalecem como registro do que aconteceu.

## Escopo de autoria

Este repositório reúne documentação da sessão, regra udev, scripts auxiliares e adaptação do launcher oficial. Não redistribui APKs nem incorpora código-fonte completo dos projetos externos. O launcher é derivado do exemplo do KlipperScreen; consulte a licença do projeto original antes de redistribuí-lo fora deste contexto. Não foi atribuída uma nova licença genérica que substitua direitos de terceiros.
