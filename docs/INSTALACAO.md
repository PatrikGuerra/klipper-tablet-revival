# Reparos avançados do XServer XSDL

Para uma instalação nova, siga apenas [COMECE_AQUI.md](COMECE_AQUI.md). Os procedimentos abaixo documentam falhas **específicas** do NT-1710 testado; não são etapas obrigatórias. Use-os somente após confirmar o mesmo erro, a mesma versão do APK e o estado do seu tablet. Não limpe os dados do aplicativo nem faça downgrade sem preservar a instalação atual.

Todos os comandos são executados no BTT por SSH. Após `adb devices -l`, defina `TABLET_SERIAL='serial-exibido-pelo-adb'` no mesmo terminal. O aplicativo deve estar instalado antes dos reparos. Para diagnóstico de porta/display, use a [seção final](#x11-sem-resposta).

## Antes de alterar arquivos internos

**Exige shell ADB root já disponível no tablet.** O exemplar testado retornou `uid=0(root)`; este projeto não realizou root. Se `adb shell id` não retornar `uid=0`, **pare aqui**. Não há procedimento sem root validado para copiar arquivos internos; tente uma instalação limpa suportada pelo XSDL ou investigue outro método sem usar estes comandos.

```sh
adb -s "$TABLET_SERIAL" shell id
adb -s "$TABLET_SERIAL" shell ls -ld /data/data/x.org.server/files
```

Antes de **qualquer** reparo, pare o aplicativo e faça um backup único. Confira que `adb pull` e `tar -tf` terminam sem erro antes de prosseguir. A restauração completa desse TAR não foi testada.

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

## Fontes e Android com TLS antigo

No tablet testado, a 1.11.40 tentou obter `xfonts.tgz` por HTTP, foi redirecionada a HTTPS e falhou com `SSLHandshakeException / unsupported protocol`. O BTT conseguiu baixar o arquivo oficial. O hash observado está em [checksums.sha256](../checksums.sha256); compare-o antes de transferir.

```sh
curl -fL --connect-timeout 15 --max-time 180 \
  -o ~/tablet-xsdl/xfonts.tar.gz \
  https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/xfonts.tgz
sha256sum ~/tablet-xsdl/xfonts.tar.gz
adb -s "$TABLET_SERIAL" push ~/tablet-xsdl/xfonts.tar.gz /data/local/tmp/xfonts.tar.gz
adb -s "$TABLET_SERIAL" shell 'busybox gunzip -c /data/local/tmp/xfonts.tar.gz | busybox tar -xf - -C /data/data/x.org.server/files'
```

O BusyBox desse Android não aceitava `tar -z`. A árvore contém links simbólicos, por isso a extração no armazenamento externo falhou. Na sessão original a extração foi interrompida; as fontes resultantes permitiram iniciar o XSDL, mas a integridade de todas elas não foi auditada. **Numa reprodução, espere a conclusão e confira os erros.**

Só depois de confirmar as fontes, crie o marcador exigido por esta versão. Seu conteúdo é a especificação completa, **sem quebra de linha**, não apenas a URL:

```sh
printf %s :xfonts.tar.gz:http://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/xfonts.tgz/download > ~/tablet-xsdl/libsdl-DownloadFinished-2.flag
adb -s "$TABLET_SERIAL" push ~/tablet-xsdl/libsdl-DownloadFinished-2.flag /sdcard/Android/data/x.org.server/files/
```

O nome, índice e formato do marcador são específicos da 1.11.40. Se a pasta de destino não existir, pare e confira a versão instalada.

## Erro XKB após troca de versão

Na instalação original, a 1.20.51 iniciou com `X server failed to launch`; um downgrade para 1.11.40 com `adb install -r -d` preservou dados incompatíveis. Depois apareceram `XKB: Couldn't compile keymap` e `Failed to activate core devices`. **Não faça esse downgrade como teste inicial.** O caminho recomendado é começar com 1.11.40 no NT-1710.

Somente se esse mesmo erro ocorrer **após o backup acima**, extraia os arquivos do APK 1.11.40 já baixado. Confira que o APK é o mesmo usado no tablet e observe o dono atual da pasta interna antes de copiar:

```sh
adb -s "$TABLET_SERIAL" shell ls -ld /data/data/x.org.server/files
unzip -p ~/tablet-xsdl/XServer-XSDL-1.11.40.apk assets/data-1.tgz > "$backup_dir/data-1.tgz"
mkdir -p "$backup_dir/data-old"
tar -xzf "$backup_dir/data-1.tgz" -C "$backup_dir/data-old"
unzip -p ~/tablet-xsdl/XServer-XSDL-1.11.40.apk assets/binaries-armeabi-v7a.zip > "$backup_dir/binaries-old.zip"
unzip -p "$backup_dir/binaries-old.zip" usr/bin/xkbcomp > "$backup_dir/xkbcomp-old"
```

Pare se a extração falhar ou os arquivos esperados não existirem. Na sessão, `chown 10076:10076` foi necessário para os arquivos internos repostos. **Esse UID/GID não é universal.** Defina o proprietário observado no seu tablet antes de copiar; a condição abaixo impede a cópia enquanto o valor de exemplo não for alterado:

```sh
APP_OWNER='uid:gid-observados'
if [[ $APP_OWNER =~ ^[0-9]+:[0-9]+$ ]]; then
    adb -s "$TABLET_SERIAL" push "$backup_dir/data-old/usr" /data/data/x.org.server/files/ &&
    adb -s "$TABLET_SERIAL" shell mv /data/data/x.org.server/files/usr/bin/xkbcomp /data/data/x.org.server/files/usr/bin/xkbcomp.pre-repair &&
    adb -s "$TABLET_SERIAL" push "$backup_dir/xkbcomp-old" /data/data/x.org.server/files/usr/bin/xkbcomp &&
    adb -s "$TABLET_SERIAL" shell chmod 755 /data/data/x.org.server/files/usr/bin/xkbcomp &&
    adb -s "$TABLET_SERIAL" shell busybox chown -R "$APP_OWNER" /data/data/x.org.server/files/usr &&
    adb -s "$TABLET_SERIAL" shell ls -ld /data/data/x.org.server/files/usr
else
    echo 'Defina APP_OWNER com o UID:GID numérico observado antes de copiar.' >&2
fi
```

Não foi feita limpeza dos dados do aplicativo. O `xkbcomp.pre-repair` preservado é um link da instalação anterior; não é um rollback garantido.

## X11 sem resposta

Com XSDL aberto, o display final respondeu em `:0` (porta 6000):

```sh
adb -s "$TABLET_SERIAL" forward tcp:6100 tcp:6000
timeout 8 xset -display :100 -q
adb -s "$TABLET_SERIAL" shell netstat -lnt
adb -s "$TABLET_SERIAL" logcat -d -t 200 | grep -E 'XSDL|XKB|Fatal|setenv DISPLAY'
```

Durante as falhas, XSDL tentou `:1`, `:2` e `:3` (portas 6001–6003). Um `xsel` antigo também ocupava a porta 6000; foi identificado pelo processo real e encerrado, sem PID reutilizável. Inspecione a porta e o log **antes** de mudar o encaminhamento ou encerrar processos. `xset` responder confirma X11, não imagem/toque no tablet.
