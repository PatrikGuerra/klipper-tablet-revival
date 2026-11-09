# Klipper Tablet Revival

Um tablet Android antigo, recuperado como painel touchscreen do KlipperScreen por **USB**.

Validado em 09/11/2026: BTT Pi/CB1 com Debian 11 ARM64 e tablet **NT-1710, Android 4.2.2, ARMv7**. A interface apareceu no tablet e o usuário confirmou que o toque ficou correto após desativar a emulação de touchpad.

![KlipperScreen funcionando no tablet](docs/images/klipperscreen-usb.png)

## Arquitetura

```text
Klipper + Moonraker → KlipperScreen no BTT Pi
                              ↓ X11, DISPLAY=:100
                     ADB forward 6100 → 6000
                              ↓ cabo USB
                  XServer XSDL 1.11.40 no Android
                              ↑ toque direto
```

SSH é usado para administração. O transporte da interface entre o BTT Pi e o tablet usa ADB/USB. Não é vídeo HDMI nem espelhamento: o tablet renderiza X11, e o KlipperScreen executa no BTT Pi. O tablet estava também conectado ao Wi-Fi; desligar o Wi-Fi para um teste isolado não foi feito nesta sessão.

## Documentação

- [Instalação e reprodução passo a passo](docs/INSTALACAO.md)
- [Histórico real, versões e evidências](docs/HISTORICO.md)
- [Touch: diagnóstico e correção](docs/TOUCH.md)
- [Diagnóstico, manutenção e rollback](docs/MANUTENCAO.md)
- [Referências e procedência dos arquivos](docs/REFERENCIAS.md)
- [Validação dos scripts e evidências](docs/VALIDACAO.md)
- [Roteiro original de planejamento](docs/REFERENCIA_ORIGINAL.md)

## Arquivos executáveis e configuração

| Arquivo | Uso |
|---|---|
| `scripts/launch_KlipperScreen.sh` | Launcher usado no BTT, baseado no exemplo oficial; serial deve ser ajustado para outro tablet |
| `scripts/diagnostico.sh` | Inspeção do sistema, ADB e X11, sem instalação nem comandos de impressora |
| `scripts/patch_touch.py` | Corrige somente clique e movimento relativo no formato Java do XSDL validado; gera outro arquivo |
| `config/70-btt-tablet-adb.rules` | Permissão USB exclusiva para o VID/PID observado |
| `checksums.sha256` | Hashes observados dos downloads oficiais |

Não há instalador automático: a execução por etapas permite conferir cada resultado. Não foram incluídos senhas, tokens, APKs, backups completos do Android ou configurações da impressora. Os binários devem ser obtidos das fontes oficiais.

## Resultado e limites

- ADB autorizado, XSDL respondendo via USB, KlipperScreen conectado ao Moonraker.
- Toque direto confirmado pelo usuário; descanso do X11 desativado durante a sessão.
- Webcam Microsoft e pendrive de backup permaneceram intactos.
- Nenhum movimento de eixo, extrusão ou aquecimento foi acionado pelo agente.
- Reconexão do cabo, reinicialização completa e teste prolongado ainda não validados.
- O launcher inicia a atividade Android quando o serviço sobe; não foi criado watchdog nem automação adicional.

## Nomes considerados

1. `klipper-tablet-revival` — escolhido pelo usuário.
2. `klipper-tablet-bridge`
3. `klipper-usb-panel`
4. `klipper-touch-link`
5. `klipper-pocket-screen`

Scripts baseados em projetos externos mantêm a procedência indicada em [Referências](docs/REFERENCIAS.md). Este repositório documenta uma instalação específica; não reivindica autoria do KlipperScreen ou XServer XSDL.
