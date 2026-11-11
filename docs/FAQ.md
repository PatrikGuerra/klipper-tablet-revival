# Problemas comuns

Siga primeiro o [guia principal](COMECE_AQUI.md). Esta página ajuda a escolher o próximo passo; os procedimentos específicos ficam nos documentos vinculados.

| Sintoma ou dúvida | O que conferir |
|---|---|
| `btt.local` não resolve | Descubra o IP atual do BTT no roteador ou na configuração de rede. O nome não resolveu na sessão original. |
| `adb devices -l` vazio | Cabo **de dados**, porta USB, tablet desbloqueado e depuração USB habilitada. Não avance para XSDL antes de ADB funcionar. |
| `unauthorized` | Aceite a autorização ADB na tela do tablet. |
| `no permissions` | Confira VID/PID, grupo `plugdev`, [regra udev restrita e reinício do daemon ADB](COMECE_AQUI.md#3-corrija-permissões-somente-se-necessário). A regra deste repo é só para `18d1:0003`. |
| XSDL 1.20.51 instala, mas não inicia | Isso ocorreu no NT-1710. Comece com **1.11.40** nesse modelo; a causa exata da falha da 1.20.51 não foi isolada. Não faça downgrade sobre dados existentes sem backup. |
| `xfonts.tgz` falha com TLS/HTTPS | O Android antigo não negociou o redirecionamento HTTPS. Veja [reparo de fontes](INSTALACAO.md#fontes-e-android-com-tls-antigo), que exige acesso root preexistente ao app. |
| `XKB: Couldn't compile keymap` | Após o downgrade original havia arquivos incompatíveis. Veja [reparo XKB](INSTALACAO.md#erro-xkb-após-troca-de-versão); não é etapa normal de instalação. |
| `xset` não responde | Verifique XSDL, [display/porta e logs](INSTALACAO.md#x11-sem-resposta). `:0` usa 6000; não encerre processos por PID copiado de outro equipamento. |
| Toque parece touchpad ou deslocado | Use **Desktop, No Emulation**. Se falhar no perfil validado, veja [TOUCH.md](TOUCH.md); não force escala só pela diferença 800×480/800×444. |
| Serviço `active`, mas sem interface | Confirme `adb forward --list`, `xset -display :100 -q`, logs e a **tela física**; serviço ativo não comprova desenho/toque. |
| A tela apaga | O descanso X11 é separado do Android. O launcher aplica `xset s off`; confira `timeout: 0` em `xset -q` e revise bloqueio do Android. |
| Preciso de root ou APK customizado? | Não foi criado APK nem feito root. O exemplar já tinha shell ADB root; somente os [reparos internos](INSTALACAO.md) e o [patch de toque](TOUCH.md) dependem dele. Sem root, não há reparo interno validado aqui. |
| Preciso de Wi-Fi para a imagem? | O transporte configurado é ADB/USB; SSH usa rede só para administrar o BTT. O tablet estava com Wi-Fi ligado, então o teste isolado com Wi-Fi desligado ainda falta. |
| Reconecta sozinho? | Reboots do tablet e BTT passaram com o [supervisor](RECONEXAO.md). Remoção física do cabo, falta de energia, PIN, depuração desativada e autorização revogada não foram validados/recuperados automaticamente. |

O [NT-1710 testado](TABLET_TESTADO.md) é um exemplo confirmado, não uma garantia de compatibilidade universal.
