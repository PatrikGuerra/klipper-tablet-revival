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

Depois dos testes reais, os hashes SHA-256 dos três scripts instalados foram comparados às cópias deste repositório e coincidiram:

| Arquivo | SHA-256 |
|---|---|
| `tablet-usb-common.sh` | `a309e1a9faca36cb2fd8607060243a7937b1141de16b7d532a6437d53298d6eb` |
| `tablet-usb-watchdog.sh` | `1fa394dee5a8abfa79ce94a84be670f3f57a786f3c6d2e9b5a22a4e739c6e30d` |
| `launch_KlipperScreen-autoconnect.sh` | `933e9b93bbf53d11197befc47f657df4e3c42993e4ca72adc5d4fe2679e76c7d` |

Supervisor e KlipperScreen estavam habilitados no boot; supervisor, KlipperScreen, Klipper e Moonraker estavam ativos. A janela em foco no Android era `x.org.server/.MainActivity`, e a captura final mostrou a interface conectada à impressora.
