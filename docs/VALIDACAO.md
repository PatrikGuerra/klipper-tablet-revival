# Validação do material publicado

## Evidência da instalação

- `adb devices -l`: serial do NT-1710 em estado `device`.
- `xset -display :100 -q`: servidor X respondeu pelo encaminhamento USB.
- `systemctl is-active KlipperScreen klipper moonraker`: os três ativos.
- Logs de KlipperScreen: inicialização da impressora e leitura das temperaturas.
- Captura real do Android incluída em `images/klipperscreen-usb.png`.
- Confirmação física do usuário após a correção do touch: toque funcionando corretamente.

## Scripts do repositório

As cópias publicadas foram enviadas para `<DeviceHome>/tablet-xsdl` somente para verificação, sem substituir o launcher em uso:

```sh
bash -n ~/tablet-xsdl/launch_KlipperScreen.sh
bash -n ~/tablet-xsdl/diagnostico.sh
python3 -m py_compile ~/tablet-xsdl/patch_touch.py
python3 ~/tablet-xsdl/patch_touch.py ~/tablet-xsdl/touch-settings-before.cfg /tmp/revival-verify-20261109-a.cfg
cmp /tmp/revival-verify-20261109-a.cfg ~/tablet-xsdl/touch-settings-direct.cfg
python3 ~/tablet-xsdl/patch_touch.py /tmp/revival-verify-20261109-a.cfg /tmp/revival-verify-20261109-b.cfg
cmp /tmp/revival-verify-20261109-a.cfg /tmp/revival-verify-20261109-b.cfg
```

Todos concluíram com sucesso. O patch produziu **exatamente os mesmos bytes** da configuração aplicada e confirmada pelo usuário. Reaplicá-lo à configuração corrigida não mudou seu conteúdo (idempotência).

Os arquivos `.cfg` reais não foram publicados. O teste foi executado no BTT usando os backups já existentes; não foram inventados dados de calibração nem acionados controles da impressora.

## O que esta validação não cobre

O guia inteiro não foi repetido do zero: isso exigiria outro tablet ou reinstalação. O script de diagnóstico teve sua sintaxe conferida; seus comandos correspondem às inspeções usadas na sessão, mas não foi executado integralmente como um novo teste. Na etapa inicial não houve reboot; a etapa posterior de [supervisão da reconexão](RECONEXAO.md) executou os reboots reais e registra seus resultados. Teste prolongado e retirada física do cabo continuam pendentes. As diferenças entre o roteiro ideal e a recuperação real estão registradas em HISTORICO.md.

## Verificação final da automação

Depois dos testes reais, os scripts instalados **naquela sessão** coincidiam com os arquivos do repositório **antes** da anonimização e desta revisão. Os hashes antigos não identificam as versões publicadas agora; não servem para comprovar que uma instalação atual usa este commit. A configuração local do usuário/serial também faz o arquivo comum instalado diferir intencionalmente do modelo publicado.

Para conferir uma instalação nova, execute no BTT a partir da raiz do repositório:

```sh
printf '%s\0' scripts/*.sh | xargs -0 -n 1 bash -n
python3 -m py_compile scripts/patch_touch.py
sha256sum scripts/*.sh /usr/local/bin/tablet-usb-watchdog.sh /usr/local/lib/tablet-usb-common.sh
diff -u scripts/tablet-usb-watchdog.sh /usr/local/bin/tablet-usb-watchdog.sh
diff -u scripts/tablet-usb-common.sh /usr/local/lib/tablet-usb-common.sh
```

O `diff` do arquivo comum deve mostrar somente os valores locais configurados. Confira também o launcher instalado contra `scripts/launch_KlipperScreen-autoconnect.sh`; se usa o launcher inicial, compare com `scripts/launch_KlipperScreen.sh`, esperando a substituição do serial. Supervisor e KlipperScreen estavam habilitados no boot no teste original; a janela em foco era `x.org.server/.MainActivity`, e a captura final mostrava a interface conectada à impressora.
