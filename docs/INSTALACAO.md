# Reprodução passo a passo

Se esta é sua primeira leitura, siga primeiro o [guia acompanhado](COMECE_AQUI.md), que indica onde executar cada comando e o resultado esperado. Este documento guarda os detalhes técnicos e os reparos específicos. Consulte também a [FAQ](FAQ.md) e a [ficha do tablet validado](TABLET_TESTADO.md).

Este guia separa o caminho recomendado para uma instalação nova dos reparos que foram necessários na sessão real. Ajuste serial, usuário e caminhos ao seu equipamento. Execute os comandos Linux no BTT Pi por SSH.

## 1. Diagnóstico inicial

```sh
ssh <DeviceUser>@<DeviceHostIp>
cat /etc/os-release
uname -m
id
df -h /
free -h
command -v adb
lsusb
ls -ld ~/KlipperScreen ~/.KlipperScreen-env
systemctl is-active klipper moonraker KlipperScreen
systemctl cat KlipperScreen
```

O nome `btt.local` não resolveu no computador desta sessão; o IP fornecido pelo usuário funcionou. A senha não está no repositório. Encontramos KlipperScreen já instalado e ativo, portanto não clonamos nem reinstalamos o projeto.

Identificação USB: `18d1:0003`, Android/AllWinner. Outros dispositivos: webcam Microsoft e pendrive Kingston; nenhum deles deve receber alterações.

## 2. ADB e permissão USB

Habilite a depuração USB no Android. Instale somente se ADB estiver ausente:

```sh
sudo apt-get update
sudo apt-get install -y adb
adb devices -l
```

Foram instalados oito pacotes, cerca de 2,8 MB adicionais; nenhum pacote existente foi atualizado. O tablet inicialmente apareceu com `no permissions`, embora `<DeviceUser>` já estivesse em `plugdev`.

Copie `config/70-btt-tablet-adb.rules` deste repositório para o BTT. Antes de substituir uma regra existente, faça uma cópia com outro nome fora de `/etc/udev/rules.d`.

```sh
sudo install -m 0644 config/70-btt-tablet-adb.rules /etc/udev/rules.d/70-btt-tablet-adb.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --action=add --subsystem-match=usb --attr-match=idVendor=18d1 --attr-match=idProduct=0003
adb kill-server
adb start-server
adb devices -l
```

O reinício do daemon ADB foi necessário: a permissão já estava `root:plugdev`, modo `0660`, mas o daemon ainda reportava o estado antigo. Não executar ADB como root no BTT para contornar isso.

Resultado esperado: serial `<DeviceSerialNumber>`, estado `device`. Se aparecer `unauthorized`, aceite a autorização no Android.

```sh
adb -s <DeviceSerialNumber> shell getprop ro.product.model
adb -s <DeviceSerialNumber> shell getprop ro.build.version.release
adb -s <DeviceSerialNumber> shell getprop ro.product.cpu.abi
```

## 3. Obter e instalar XServer XSDL

Para este tablet, a versão funcional foi **1.11.40**. A 1.20.51 instalou mas falhou ao iniciar o servidor X. Comece pela versão validada neste hardware.

```sh
mkdir -p ~/tablet-xsdl
curl -fL --connect-timeout 15 --max-time 180 \
  -o ~/tablet-xsdl/XServer-XSDL-1.11.40.apk \
  https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/XServer-XSDL-1.11.40.apk
sha256sum ~/tablet-xsdl/XServer-XSDL-1.11.40.apk
adb -s <DeviceSerialNumber> install ~/tablet-xsdl/XServer-XSDL-1.11.40.apk
adb -s <DeviceSerialNumber> shell am start -n x.org.server/.MainActivity
```

Compare o hash com `checksums.sha256`. Na sessão real, para substituir a 1.20.51 recém-instalada, foi usado `adb install -r -d ...1.11.40.apk`. A troca manteve dados incompatíveis da versão anterior, exigindo reparos. Essa sequência não deve ser o ponto de partida de uma instalação nova.

## 4. Fontes e Android com TLS antigo

A 1.11.40 tentou obter `xfonts.tgz` por HTTP, foi redirecionada para HTTPS e falhou com `SSLHandshakeException / unsupported protocol`. O download no BTT Pi funcionou:

```sh
curl -fL --connect-timeout 15 --max-time 180 \
  -o ~/tablet-xsdl/xfonts.tar.gz \
  https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/xfonts.tgz
sha256sum ~/tablet-xsdl/xfonts.tar.gz
```

O arquivo observado tem 68.058.013 bytes. Copiá-lo apenas para o armazenamento externo não resolveu: o app tentou retomar o download. Copiar a árvore extraída para o armazenamento externo falhou em links simbólicos. A solução final colocou as fontes na pasta **interna** do app, preservando os links.

Este tablet fornece shell ADB como `uid=0(root)` de fábrica/estado preexistente; **não fizemos root**. Os comandos de reparo interno abaixo dependem desse acesso. Em outro tablet sem root, não execute supondo que funcionará; use uma instalação limpa/configuração suportada pelo aplicativo.

```sh
adb -s <DeviceSerialNumber> shell id
adb -s <DeviceSerialNumber> push ~/tablet-xsdl/xfonts.tar.gz /data/local/tmp/xfonts.tar.gz
adb -s <DeviceSerialNumber> shell 'busybox gunzip -c /data/local/tmp/xfonts.tar.gz | busybox tar -xf - -C /data/data/x.org.server/files'
```

O BusyBox do Android não aceitava `tar -z`; por isso usamos `gunzip | tar`. A sessão de extração foi interrompida após longa espera, mas a árvore criada foi suficiente para o servidor funcionar; não foi feita uma auditoria de integridade de todas as fontes. Para reprodução, aguarde a conclusão e verifique eventuais erros.

O app também usa um marcador de download. No formato desta versão, o conteúdo é a especificação completa, **sem quebra de linha**, e não apenas a URL:

```sh
printf %s :xfonts.tar.gz:http://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/xfonts.tgz/download > ~/tablet-xsdl/libsdl-DownloadFinished-2.flag
adb -s <DeviceSerialNumber> push ~/tablet-xsdl/libsdl-DownloadFinished-2.flag /sdcard/Android/data/x.org.server/files/
```

Não crie o marcador antes de disponibilizar as fontes. O caminho e o índice do marcador são específicos desta versão.

## 5. Reparos após a troca de versão — somente se necessários

A configuração X11 estava ausente, e o `xkbcomp` era um link para a biblioteca da versão anterior. O erro foi `XKB: Couldn't compile keymap` / `Failed to activate core devices`.

Preserve os arquivos antes de reparar. Na sessão houve uma cópia do arquivo de configuração no BTT e um arquivo `/sdcard/xsdl-before-repair.tar` no tablet; a restauração completa desse TAR não foi testada. A tentativa inicial de `adb pull` da árvore inteira falhou em um link quebrado e **não constitui backup completo**.

```sh
adb -s <DeviceSerialNumber> shell am force-stop x.org.server
adb -s <DeviceSerialNumber> shell busybox tar -cf /sdcard/xsdl-before-repair.tar -C /data/data/x.org.server files
unzip -p ~/tablet-xsdl/XServer-XSDL-1.11.40.apk assets/data-1.tgz > ~/tablet-xsdl/data-1.tgz
mkdir -p ~/tablet-xsdl/data-old
tar -xzf ~/tablet-xsdl/data-1.tgz -C ~/tablet-xsdl/data-old
adb -s <DeviceSerialNumber> push ~/tablet-xsdl/data-old/usr /data/data/x.org.server/files/
unzip -p ~/tablet-xsdl/XServer-XSDL-1.11.40.apk assets/binaries-armeabi-v7a.zip > ~/tablet-xsdl/binaries-old.zip
unzip -p ~/tablet-xsdl/binaries-old.zip usr/bin/xkbcomp > ~/tablet-xsdl/xkbcomp-old
adb -s <DeviceSerialNumber> shell mv /data/data/x.org.server/files/usr/bin/xkbcomp /data/data/x.org.server/files/usr/bin/xkbcomp.pre-repair
adb -s <DeviceSerialNumber> push ~/tablet-xsdl/xkbcomp-old /data/data/x.org.server/files/usr/bin/xkbcomp
adb -s <DeviceSerialNumber> shell chmod 755 /data/data/x.org.server/files/usr/bin/xkbcomp
```

Foi usado `chown 10076:10076` para os arquivos internos repostos. **10076 é o UID observado do app neste tablet**, não um valor universal. Verifique o proprietário atual antes de repetir:

```sh
adb -s <DeviceSerialNumber> shell ls -ld /data/data/x.org.server/files
adb -s <DeviceSerialNumber> shell busybox chown -R 10076:10076 /data/data/x.org.server/files/usr
```

Não houve limpeza dos dados do aplicativo. A tentativa de `pm clear` foi bloqueada pela revisão automática antes de executar, e o caminho seguido foi o reparo preservando configurações.

## 6. Validar o XServer pelo USB

```sh
adb -s <DeviceSerialNumber> shell am start -n x.org.server/.MainActivity
adb -s <DeviceSerialNumber> forward tcp:6100 tcp:6000
timeout 8 xset -display :100 -q
```

Esperado: resposta com teclado, ponteiro, fontes e estado de descanso. Durante as falhas o XSDL tentou displays `:1`, `:2` e `:3`; nesses casos a porta é `6000 + display`. Inspecione:

```sh
adb -s <DeviceSerialNumber> shell netstat -lnt
adb -s <DeviceSerialNumber> logcat -d -t 200 | grep -E 'XSDL|XKB|Fatal|setenv DISPLAY'
```

Um processo antigo `xsel` continuava segurando a porta 6000. Ele foi identificado com `ps` e encerrado pelo PID observado naquele momento; os PIDs não são reproduzíveis. Após reabrir o app, o display voltou a `:0` e a resposta X11 funcionou em `tcp:6000`.

## 7. Direcionar o KlipperScreen ao tablet

O serviço já usava `User=<DeviceUser>` e definia `KS_XCLIENT` com o Python do ambiente do KlipperScreen e `screen.py`. A unidade systemd não foi alterada.

O launcher personalizado não existia. Antes de criar/substituir em outra instalação, faça backup do arquivo existente. Copie o launcher deste repositório:

```sh
install -m 0755 scripts/launch_KlipperScreen.sh ~/KlipperScreen/scripts/launch_KlipperScreen.sh
bash -n ~/KlipperScreen/scripts/launch_KlipperScreen.sh
sudo systemctl restart KlipperScreen
journalctl -u KlipperScreen -n 30 --no-pager
```

Diferenças em relação ao exemplo oficial: serial explícito, `am start` compatível com Android 4.2.2, `xset s off` e tentativa de desativar DPMS. O XServer deste tablet reporta que não suporta DPMS.

O loop original limita tentativas, mas cada `xset` não tem timeout individual no launcher; portanto o limite não representa necessariamente 60 segundos de tempo real. A detecção de bloqueio via NFC também depende do Android e não foi validada neste tablet.

## 8. Corrigir toque e validar

Siga [TOUCH.md](TOUCH.md). O problema não era matriz de calibração: era emulação de touchpad e clique com timeout. O usuário confirmou o funcionamento correto após a mudança.

Verificações finais:

```sh
adb devices -l
adb forward --list
systemctl is-active KlipperScreen klipper moonraker
xset -display :100 -q
```

Abra menus sem comandos físicos para conferir o toque. Validação de movimento, aquecimento, reinicialização e estabilidade prolongada continua fora do que foi executado nesta sessão.
