# Diagnóstico e rollback

Atualização: o sistema agora tem [backup completo e supervisor de reconexão](BACKUP_E_RECONEXAO.md). Os comandos abaixo também descrevem a fase inicial da instalação. Para reverter o painel, pare primeiro o supervisor, evitando que ele reabra o aplicativo enquanto você trabalha.

## Verificações rápidas

```sh
bash scripts/diagnostico.sh <DeviceSerialNumber>
```

| Sintoma | Verificação/ação |
|---|---|
| Host não resolve `btt.local` | Usar o IP atual do BTT; o endereço documentado pode mudar pelo DHCP |
| ADB sem dispositivo | Cabo de dados, depuração USB e lsusb; preservar webcam/pendrive |
| `no permissions` | Conferir regra udev, grupo plugdev e modo do nó USB; reiniciar daemon ADB |
| `unauthorized` | Aceitar autorização no Android desbloqueado |
| Falha no download das fontes | Ver logs de TLS; obter no BTT pela fonte oficial |
| Erro XKB/core devices | Conferir configuração X11 e xkbcomp da mesma versão do APK |
| XSDL sem resposta | Conferir display/porta nos logs; `:0` é 6000, `:1` é 6001 |
| Toque parece touchpad | Desativar movimento relativo e usar clique normal; ver TOUCH.md |
| Tela apaga | Conferir `xset -display :100 -q`, timeout esperado 0; configuração Android é separada |
| Serviço ativo mas sem tela | `active` não prova renderização; verificar resposta X11, logs e imagem |

## Arquivos alterados no BTT

- Pacote `adb` e suas dependências.
- `/etc/udev/rules.d/70-btt-tablet-adb.rules`.
- `<DeviceHome>/KlipperScreen/scripts/launch_KlipperScreen.sh`, antes inexistente.
- Downloads, reparos e backups sob `<DeviceHome>/tablet-xsdl`.

Não foram alterados Klipper, Moonraker, a unidade systemd do KlipperScreen, webcam ou pendrive. O daemon ADB foi iniciado/reiniciado; só o serviço KlipperScreen foi parado/reiniciado durante os ajustes.

## Voltar ao modo anterior do KlipperScreen

O launcher personalizado não existia antes. Para desativá-lo sem apagar:

```sh
sudo systemctl disable --now tablet-usb-watchdog
sudo systemctl stop KlipperScreen
mv ~/KlipperScreen/scripts/launch_KlipperScreen.sh ~/tablet-xsdl/launch_KlipperScreen.desativado.sh
sudo systemctl start KlipperScreen
```

Isso devolve a seleção ao script original `KlipperScreen-start.sh`; o funcionamento anterior com X local depende do hardware/configuração que já existiam. Se já havia launcher em outra instalação, restaure o backup correspondente em vez deste procedimento.

Para retirar a regra exclusiva, mova-a para uma pasta de backup fora de `/etc/udev/rules.d`, recarregue udev e reconecte apenas o tablet quando conveniente. Não remova ADB/dependências automaticamente: podem ser úteis para manutenção e não é necessário removê-los para reverter o launcher.

## Android

- Backup do touch: `<DeviceHome>/tablet-xsdl/touch-settings-before.cfg` no BTT.
- Configuração aplicada: `touch-settings-direct.cfg`.
- Backup interno: `/sdcard/xsdl-before-repair.tar` no tablet, restauração completa não testada.
- Link antigo do xkbcomp: `xkbcomp.pre-repair` ao lado do binário reposto; aponta para a instalação anterior e não é uma alternativa funcional garantida.

Não restaure um TAR completo sobre o aplicativo em execução. Examine seu conteúdo e a versão instalada antes de qualquer recuperação. APKs e fontes têm hashes registrados, mas não houve verificação criptográfica independente da identidade do autor além do download da fonte oficial e da instalação pelo Android.

## Próximos testes opcionais

1. Confirmar imagem/toque com Wi-Fi do tablet desligado.
2. Desconectar/reconectar fisicamente somente o tablet e observar recuperação.
3. Medir memória/CPU por horas antes de considerar painel definitivo.

Esses itens são pendências. Reboots separados do BTT e tablet, recuperação do XSDL e supervisão via systemd já foram implementados/testados; veja o registro da nova etapa.
