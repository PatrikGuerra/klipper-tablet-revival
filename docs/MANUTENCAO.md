# Diagnóstico e rollback

Para sintomas, use a [FAQ](FAQ.md). No BTT, escolha o serial exibido por `adb devices -l` e rode o diagnóstico somente de leitura (a consulta ADB pode iniciar o daemon local):

```sh
TABLET_SERIAL='serial-exibido-pelo-adb'
bash scripts/diagnostico.sh "$TABLET_SERIAL"
```

## Desativar a integração

Pare primeiro o supervisor, para que ele não reabra XSDL. O launcher personalizado não existia antes **no equipamento testado**; em outra instalação, restaure o launcher original salvo no diretório de backup informado no [guia principal](COMECE_AQUI.md) ou na [instalação do supervisor](RECONEXAO.md). Não apague uma configuração anterior de terceiros.

```sh
sudo systemctl disable --now tablet-usb-watchdog
sudo systemctl stop KlipperScreen
mkdir -p ~/tablet-xsdl
backup_dir=$(mktemp -d "$HOME/tablet-xsdl/rollback.XXXXXXXX")
mv ~/KlipperScreen/scripts/launch_KlipperScreen.sh "$backup_dir/"
echo "Launcher desativado: $backup_dir"
sudo systemctl start KlipperScreen
```

Sem launcher personalizado, o comportamento volta a depender do `KlipperScreen-start.sh` e da configuração preexistente. Se o serviço não subir, confira `journalctl -u KlipperScreen -n 40 --no-pager` e o backup correspondente. Para retirar a regra USB exclusiva, mova-a para fora de `/etc/udev/rules.d`, recarregue udev e reconecte apenas o tablet; não remova o pacote ADB automaticamente.

## Backups no Android

- Configuração de toque anterior: `touch-settings-before.cfg` no BTT; veja [TOUCH.md](TOUCH.md).
- Antes de reparar XSDL, o [guia de reparos](INSTALACAO.md) cria um TAR único em `/sdcard` e o copia ao BTT. Restauração integral não testada.
- `xkbcomp.pre-repair`, quando criado, aponta para a instalação anterior; não é alternativa funcional garantida.

Nunca restaure um TAR completo sobre o aplicativo em execução. Examine conteúdo, proprietário e versão antes. Ainda faltam testes com Wi-Fi desligado, desconexão física do cabo e operação prolongada; reboots do BTT/tablet e retomada do XSDL foram testados.
