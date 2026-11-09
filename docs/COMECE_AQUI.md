# Comece aqui: do tablet conectado à interface funcionando

Bem-vindo! A ideia é simples: o BTT executa o KlipperScreen e o tablet desenha a interface e recebe seus toques. Este guia explica **onde executar**, **o que observar** e **quando seguir**. O [histórico](HISTORICO.md) registra os detalhes da instalação original; ele não precisa ser repetido inteiro em um equipamento novo.

## Antes de começar

Você precisa de:

- BTT com Klipper, Moonraker e KlipperScreen já funcionando. Se o último estiver ausente, faça primeiro a [instalação oficial](https://klipperscreen.readthedocs.io/en/latest/Installation/).
- Tablet Android compatível e cabo USB que transmita dados.
- Acesso SSH ao BTT, senha/sudo quando necessário e possibilidade de desbloquear o Android.
- Acesso a este repositório. Ele é privado: o GitHub deve autorizar sua conta.

Neste projeto foram usados `<DeviceUser>`, `<DeviceHostIp>` e o serial `<DeviceSerialNumber>`. **Troque pelos valores do seu equipamento.** Não digite literalmente textos como `SEU_SERIAL` ou `IP_DO_BTT`.

### Onde cada coisa acontece

| Local | O que fazer |
|---|---|
| Seu computador | Abrir SSH para o BTT |
| Terminal SSH do BTT | Instalar ADB, consultar USB, copiar arquivos, iniciar KlipperScreen |
| Tela do tablet | Habilitar depuração, aceitar autorização e escolher o modo de toque |

## 1. Acesse o BTT e obtenha o guia

**No computador:**

```sh
ssh <DeviceUser>@IP_DO_BTT
```

**Já dentro do BTT:**

```sh
git clone https://github.com/PatrikGuerra/klipper-tablet-revival.git
cd ~/klipper-tablet-revival
cat /etc/os-release
systemctl is-active klipper moonraker KlipperScreen
lsusb
```

**Confira:** os três serviços devem aparecer como `active`, e `lsusb` deve identificar o Android. No hardware testado, o tablet é `18d1:0003`. Se não for esse VID/PID, não aplique a regra USB deste projeto sem adaptar. Não altere outros periféricos, discos ou webcam.

Se `git clone` pedir autenticação, use sua forma habitual de acesso ao GitHub. Não coloque tokens dentro de scripts ou URLs salvas. Se a pasta já existir, entre nela e confira `git status`; não clone por cima.

## 2. Ative a depuração USB no Android

Na tela do tablet, procure **Configurações → Opções do desenvolvedor → Depuração USB**. Se as opções não aparecerem, a forma de habilitá-las depende do fabricante. Conecte o cabo ao BTT e deixe o tablet desbloqueado.

**No BTT:**

```sh
command -v adb
```

Se não aparecer nenhum caminho:

```sh
sudo apt-get update
sudo apt-get install -y adb
```

Depois:

```sh
adb devices -l
```

**Confira:** copie o serial e procure `device`. Para `unauthorized`, aceite a autorização na tela. Para `no permissions`, vá à etapa seguinte. Se a lista estiver vazia, veja a [FAQ](FAQ.md) antes de instalar outros programas.

## 3. Corrija permissões somente se necessário

Esta regra é para **18d1:0003**. No BTT, confira `id`: o usuário precisa estar no grupo `plugdev`. Neste equipamento ele já estava; se você alterar grupos, encerre e abra a sessão SSH para o novo grupo valer.

```sh
cd ~/klipper-tablet-revival
id
ls -l /etc/udev/rules.d/70-btt-tablet-adb.rules
```

Se o arquivo já existir, preserve uma cópia antes de substituí-lo:

```sh
mkdir -p ~/tablet-xsdl/backups
sudo cp /etc/udev/rules.d/70-btt-tablet-adb.rules ~/tablet-xsdl/backups/70-btt-tablet-adb.rules.before
```

Se ele não existir, pule esse `cp`. Então:

```sh
sudo install -m 0644 config/70-btt-tablet-adb.rules /etc/udev/rules.d/70-btt-tablet-adb.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --action=add --subsystem-match=usb --attr-match=idVendor=18d1 --attr-match=idProduct=0003
adb kill-server
adb start-server
adb devices -l
```

**Confira:** agora precisa aparecer `device`. Não prossiga com erro de permissão.

## 4. Instale e abra o XServer XSDL

Para o NT-1710 testado, usamos **1.11.40**. Não é preciso instalar a versão que falhou primeiro.

**No BTT:**

```sh
mkdir -p ~/tablet-xsdl
curl -fL --connect-timeout 15 --max-time 180 \
  -o ~/tablet-xsdl/XServer-XSDL-1.11.40.apk \
  https://downloads.sourceforge.net/project/libsdl-android/apk/XServer-XSDL/XServer-XSDL-1.11.40.apk
sha256sum ~/tablet-xsdl/XServer-XSDL-1.11.40.apk
```

**Confira o hash:** `69e015154e115465a27495a624a3445544886ba05fd16068a73738a0c19848e2`.

Se o app ainda não estiver instalado:

```sh
adb -s SEU_SERIAL install ~/tablet-xsdl/XServer-XSDL-1.11.40.apk
adb -s SEU_SERIAL shell am start -n x.org.server/.MainActivity
```

**Confira:** a instalação deve mostrar `Success`. O app pode precisar extrair/baixar dados na primeira abertura. Aguarde. Se mostrar erro de fontes/HTTPS, siga a seção **Fontes e Android com TLS antigo** de [INSTALACAO.md](INSTALACAO.md#4-fontes-e-android-com-tls-antigo). Se uma versão mais nova já estiver instalada, não faça downgrade às cegas: veja a FAQ e preserve os dados primeiro.

## 5. Escolha toque direto

**No tablet, na abertura do XSDL:** entre em **Change Device Configuration → Mouse Emulation Mode → Desktop, No Emulation**. Os nomes podem variar. O objetivo é movimento absoluto e clique normal, sem modo touchpad.

Se o menu não resolver no perfil exato testado, [TOUCH.md](TOUCH.md) contém o patch validado e seu rollback. Não use o patch em arquivos de versões diferentes.

## 6. Confira a conexão X11 pelo USB

**No BTT, com XSDL aberto:**

```sh
adb -s SEU_SERIAL forward tcp:6100 tcp:6000
timeout 8 xset -display :100 -q
```

**Confira:** deve aparecer uma lista com teclado, ponteiro e fontes. Essa resposta prova a comunicação com o servidor X; ainda não prova que KlipperScreen está aparecendo.

Se `xset` não existir, instale o pacote Debian que o fornece:

```sh
sudo apt-get install -y x11-xserver-utils
```

Se houver timeout ou `unable to open display`, veja [FAQ](FAQ.md). Não reinicie Klipper ou Moonraker para corrigir um problema do XServer.

## 7. Ative o launcher do KlipperScreen

**No BTT:**

```sh
cd ~/klipper-tablet-revival
mkdir -p ~/tablet-xsdl/backups
ls -l ~/KlipperScreen/scripts/launch_KlipperScreen.sh
```

Se já existir, copie para backup antes de continuar:

```sh
cp ~/KlipperScreen/scripts/launch_KlipperScreen.sh ~/tablet-xsdl/backups/launch_KlipperScreen.before.sh
```

Se não existir, pule esse `cp`. Copie e edite o serial:

```sh
install -m 0755 scripts/launch_KlipperScreen.sh ~/KlipperScreen/scripts/launch_KlipperScreen.sh
nano ~/KlipperScreen/scripts/launch_KlipperScreen.sh
```

Altere a linha `export ANDROID_SERIAL="<DeviceSerialNumber>"` para o serial mostrado pelo seu ADB. Salve. Confira:

```sh
bash -n ~/KlipperScreen/scripts/launch_KlipperScreen.sh
grep ANDROID_SERIAL ~/KlipperScreen/scripts/launch_KlipperScreen.sh
systemctl cat KlipperScreen
```

**Confira:** `bash -n` deve terminar sem erro; o serial deve ser o correto. O serviço existente deve iniciar `KlipperScreen-start.sh` e definir `KS_XCLIENT`, como no ambiente validado. Se usar outro mecanismo de inicialização, adapte com a documentação oficial antes de prosseguir.

```sh
sudo systemctl restart KlipperScreen
journalctl -u KlipperScreen -n 30 --no-pager
systemctl is-active KlipperScreen klipper moonraker
```

**Confira no tablet:** a interface deve aparecer e mostrar a conexão com a impressora. Serviço `active` sozinho não confirma imagem ou toque.

## 8. Faça um teste simples e confira o resultado

Na tela, abra **More** e volte. O botão deve responder onde seu dedo encosta. Para esta primeira verificação, menus são suficientes; não é necessário movimentar eixos nem aquecer nada.

**No BTT:**

```sh
adb forward --list
xset -display :100 -q
```

**Confira:** encaminhamento `tcp:6100 tcp:6000`; descanso X11 com `timeout: 0`. O XSDL testado informa que não suporta DPMS.

Pronto: você reproduziu as verificações principais! Registre modelo, versão e resultado. Para recuperar o painel automaticamente após reboot, siga a etapa adicional de [supervisão da reconexão](RECONEXAO.md), testada no BTT e tablet deste projeto. Teste prolongado e reconexão física do cabo continuam pendentes. Se precisar desfazer, consulte [MANUTENCAO.md](MANUTENCAO.md).
