# Toque direto: diagnóstico e correção

## O que estava errado

O usuário relatou toque impreciso. A inspeção mostrou:

| Item | Valor observado |
|---|---|
| Tela física Android | 800 × 480 |
| Área X11 | 800 × 444; barra de navegação Android ocupa a faixa restante |
| Transformação XInput | Matriz identidade |
| Calibração SDL | `[0, 0, 0, 0]`, preservada |
| `LeftClickMethod` | `7`, emulação por toque/timeout |
| `RelativeMouseMovement` | `true`, modo touchpad |
| `ShowScreenUnderFinger` | `0` |

Não se deve esticar as coordenadas para 800 × 480 apenas porque essa é a tela física: a superfície da aplicação era 800 × 444.

A correção aplicada foi **`LeftClickMethod=0` (clique normal) e `RelativeMouseMovement=false` (posição absoluta)**. A configuração de botão direito, a matriz X11, resolução e calibração não foram alteradas. O usuário confirmou: tudo funcionando corretamente.

## Preferência: menu do aplicativo

A documentação oficial recomenda, na abertura do XSDL: `Change Device Configuration → Mouse Emulation Mode → Desktop, No Emulation`. Os nomes variam por versão. Use esse menu em outras versões/perfis; o patch binário abaixo é restrito ao layout que observamos.

## Como foi feito nesta sessão

O arquivo `/data/data/x.org.server/files/libsdl-settings.cfg` usa blocos primitivos do Java `ObjectOutputStream`. A estrutura foi verificada contra `Settings.java`, `SettingsMenuMouse.java` e `Mouse.java` do projeto original.

O arquivo tinha 1.552 bytes, versão de formato 5, com 1.538 bytes de dados primitivos. Os offsets lógicos confirmados foram 41 para o inteiro de clique e 1457 para o booleano de movimento relativo. São **offsets nos dados concatenados**, não offsets brutos do arquivo com cabeçalhos Java.

O script `scripts/patch_touch.py` incorpora a mesma transformação aplicada, mas com interface de linha de comando e verificações adicionais. Ele recusa versões/tamanhos/offsets inesperados e não sobrescreve o arquivo de saída existente. Não é um editor universal de configurações SDL.

## Comandos reproduzíveis no BTT Pi

Requer acesso ADB root já existente neste tablet; não foi feito root durante o trabalho. Se `id` não mostrar `uid=0(root)`, pare: não há patch sem root validado. Escolha o serial mostrado por `adb devices -l` e anote o UID/GID do dono do arquivo antes de alterar.

```sh
TABLET_SERIAL='serial-exibido-pelo-adb'
adb -s "$TABLET_SERIAL" shell id
adb -s "$TABLET_SERIAL" shell ls -l /data/data/x.org.server/files/libsdl-settings.cfg
mkdir -p ~/tablet-xsdl
backup_dir=$(mktemp -d "$HOME/tablet-xsdl/touch.XXXXXXXX")
adb -s "$TABLET_SERIAL" pull /data/data/x.org.server/files/libsdl-settings.cfg "$backup_dir/touch-settings-before.cfg"
sudo systemctl stop KlipperScreen
adb -s "$TABLET_SERIAL" shell am force-stop x.org.server
adb -s "$TABLET_SERIAL" pull /data/data/x.org.server/files/libsdl-settings.cfg "$backup_dir/touch-settings-current.cfg"
cmp "$backup_dir/touch-settings-before.cfg" "$backup_dir/touch-settings-current.cfg"
```

Se o `cmp` indicar mudança concorrente, pare e analise a cópia atual. Caso contrário:

```sh
python3 scripts/patch_touch.py "$backup_dir/touch-settings-current.cfg" "$backup_dir/touch-settings-direct.cfg"
adb -s "$TABLET_SERIAL" push "$backup_dir/touch-settings-direct.cfg" /data/data/x.org.server/files/libsdl-settings.cfg
APP_OWNER='uid:gid-observados'
adb -s "$TABLET_SERIAL" shell chown "$APP_OWNER" /data/data/x.org.server/files/libsdl-settings.cfg
adb -s "$TABLET_SERIAL" shell am start -n x.org.server/.MainActivity
sudo systemctl start KlipperScreen
```

O UID 10076 foi observado somente neste tablet. Substitua `APP_OWNER` pelo UID:GID observado; não use literalmente `uid:gid-observados` nem presuma que 10076 vale para outro dispositivo.

Foi feita uma leitura posterior do arquivo no Android e comparação byte a byte com o arquivo aplicado. O serviço voltou ativo, o XServer respondeu e os logs confirmaram inicialização da impressora no KlipperScreen. Não foi necessário inserir valores de calibração manualmente.

## Reverter somente o toque

Pare KlipperScreen e XSDL, envie de volta `touch-settings-before.cfg` do diretório único exibido, corrija o proprietário para o UID real do app e reabra XSDL/serviço. Esse backup fica no BTT Pi e não é publicado no repositório.
