# Qual tablet deu certo?

O equipamento validado foi um **NT-1710**, identificado pelo próprio Android. O usuário confirmou que a interface e o toque ficaram funcionando corretamente. Não identificamos com segurança a marca comercial, quantidade de RAM, capacidade total de armazenamento ou versão do fabricante; esses dados não devem ser deduzidos apenas pelo nome do modelo.

| Característica | Valor confirmado |
|---|---|
| Modelo Android | `NT-1710` |
| Nome interno do dispositivo | `NT-1710` |
| Produto | `nuclear_basic` |
| Android | **4.2.2** |
| ABI | `armeabi-v7a` — ARM de 32 bits |
| Identificação USB | `18d1:0003`, descrito pelo Linux como Android/AllWinner |
| Serial ADB desta unidade | `<DeviceSerialNumber>` — outro exemplar terá seu próprio serial |
| Superfície Android | 800 × 480 pixels |
| Superfície do aplicativo/X11 | 800 × 444 pixels, com barra Android ocupando a faixa restante |
| XServer XSDL que funcionou | **1.11.40** |
| XServer XSDL que falhou | 1.20.51: APK instalou, servidor X não iniciou |
| Acesso ADB preexistente | Shell retornou `uid=0(root)`; este projeto não fez root |
| Toque final | Movimento absoluto e clique normal, sem emulação de touchpad |
| Calibração SDL | `[0, 0, 0, 0]`, preservada |

O acesso root preexistente foi importante para reparar os arquivos internos do aplicativo. Isso não significa que todo tablet Android 4.2.2 permita os mesmos comandos.

## Host usado junto com ele

BTT Pi/CB1, imagem BTT-CB1 2.3.4, Debian 11 Bullseye ARM64, cerca de 1 GB de RAM. Klipper, Moonraker e KlipperScreen já estavam instalados. Foi utilizado um cabo USB com dados; a alimentação elétrica não foi modificada.

## O que foi confirmado na prática

1. Linux reconheceu o tablet USB.
2. ADB passou a mostrar `device` após ajustar permissões.
3. O XServer respondeu pelo encaminhamento USB.
4. KlipperScreen mostrou menus e temperaturas recebidas do Moonraker.
5. Depois de desativar o modo touchpad, o usuário confirmou o toque correto.

Atualização: foram executados reboots reais do tablet e do BTT, com recuperação automática da interface após instalar o supervisor. Veja [backup e reconexão](BACKUP_E_RECONEXAO.md). Ainda não foram comprovados: retirada física/reconexão do cabo, funcionamento por muitas horas ou teste com Wi-Fi desligado. A conexão gráfica configurada usa USB, mesmo que o Android também esteja no Wi-Fi.

## Como comparar com o seu tablet

No BTT, com ADB instalado e tablet autorizado, execute:

```sh
adb devices -l
# Substitua SEU_SERIAL pelo valor mostrado na primeira coluna.
adb -s SEU_SERIAL shell getprop ro.product.model
adb -s SEU_SERIAL shell getprop ro.product.device
adb -s SEU_SERIAL shell getprop ro.product.name
adb -s SEU_SERIAL shell getprop ro.build.version.release
adb -s SEU_SERIAL shell getprop ro.product.cpu.abi
adb -s SEU_SERIAL shell id
```

Se Android, ABI ou permissões forem diferentes, trate como outro ambiente. Use o menu do XSDL para configurar o toque; o patch binário deste projeto é restrito ao perfil testado.
