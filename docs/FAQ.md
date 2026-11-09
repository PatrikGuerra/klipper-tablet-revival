# FAQ: dúvidas e problemas que apareceram

## Qual tablet funcionou?

**NT-1710 com Android 4.2.2 e ABI armeabi-v7a**, usando XServer XSDL **1.11.40**. Veja a [ficha do equipamento testado](TABLET_TESTADO.md). Isso é uma confirmação daquele exemplar, não uma garantia para todo Android antigo.

## Preciso de Wi-Fi para transmitir a interface?

A conexão configurada usa **ADB por USB**, com a porta 6100 do BTT encaminhada à 6000 do Android. O Wi-Fi do tablet estava ligado durante os testes; ainda falta fazer uma validação isolada com ele desligado. SSH pela rede serve para administrar o BTT e não é o canal gráfico do tablet.

## O tablet recebe um vídeo pronto?

Ele recebe conexões X11 e renderiza a interface com XSDL. KlipperScreen e a integração com a impressora executam no BTT. O Android ainda usa processador e memória para desenhar e receber toques.

## `btt.local` não funciona. O que fizemos?

O computador não resolveu esse nome. Usamos o IP informado pelo usuário, `<DeviceHostIp>`. Descubra o IP atual do seu BTT pelo roteador ou configuração da rede; o endereço pode ser diferente.

## O Linux vê o tablet, mas ADB mostra `no permissions`.

Aplicamos uma regra udev exclusiva para `18d1:0003`, com grupo `plugdev` e modo `0660`. Mesmo com a permissão corrigida, o daemon ADB manteve o erro até executar `adb kill-server` e `adb start-server`. O passo a passo está em [COMECE_AQUI.md](COMECE_AQUI.md#3-corrija-permissões-somente-se-necessário).

## A lista do ADB está vazia ou mostra `unauthorized`.

São verificações gerais, não o erro principal desta instalação: confira cabo com dados, porta USB, depuração e tablet desbloqueado. Para `unauthorized`, aceite a chave do BTT na tela. Não instale outros servidores gráficos antes de o ADB funcionar.

## A 1.20.51 instalou, mas o servidor X não abriu.

Isso aconteceu aqui: apareceu `X server failed to launch`. A versão que funcionou foi **1.11.40**, alternativa citada na documentação oficial para Android 4. Não identificamos uma causa única comprovada para a falha da 1.20.51.

## Posso instalar a versão antiga por cima da nova?

Na sessão usamos `adb install -r -d`, mas isso manteve dados incompatíveis. Depois foi preciso reparar arquivos X11 e o xkbcomp. Para reproduzir em um dispositivo novo, comece pela versão validada. Se já tiver dados/configuração, preserve-os antes de escolher uma migração; este guia não orienta apagar o app automaticamente.

## O aplicativo trava ao baixar `xfonts.tgz`.

O erro observado foi de TLS: o Android antigo não conseguiu negociar o HTTPS após um redirecionamento do SourceForge. Baixamos as fontes oficiais no BTT e transferimos pelo USB. A recuperação completa, incluindo pasta interna e marcador de download, está em [INSTALACAO.md](INSTALACAO.md#4-fontes-e-android-com-tls-antigo). Ela dependeu de acesso root já existente no tablet.

## Copiei o arquivo de fontes, mas ele tenta baixar de novo.

Copiar apenas o `.tar.gz` para o armazenamento externo não bastou: o app tentou retomar a conexão. Foi necessário disponibilizar os arquivos extraídos e o marcador no formato exato da versão antiga. Um marcador contendo só a URL foi rejeitado; o aceito continha `:xfonts.tar.gz:` seguido da URL completa, sem quebra de linha.

## A cópia das fontes acusa `Operation not permitted`.

A árvore contém links simbólicos que não foram aceitos no armazenamento externo Android. A solução final foi extrair na pasta interna do aplicativo. Não atribua isso ao pendrive de backup: ele não participou da instalação.

## BusyBox diz que `tar -z` é inválido.

O BusyBox desse Android não tinha essa opção. Usamos `busybox gunzip -c arquivo | busybox tar -xf - -C destino`. Use o destino específico do aplicativo indicado no guia e confira os erros; não extraia na raiz do Android.

## Aparece `XKB: Couldn't compile keymap` ou `Failed to activate core devices`.

Após o downgrade, faltavam arquivos de teclado X11 e o `xkbcomp` ainda apontava para binário da versão anterior. Reparamos os arquivos a partir do **mesmo APK 1.11.40**, preservando a configuração. Veja [os comandos de reparo](INSTALACAO.md#5-reparos-após-a-troca-de-versão--somente-se-necessários).

## Por que não limpamos os dados do aplicativo?

A tentativa foi bloqueada pela revisão automática antes de executar porque apagaria dados persistentes. Seguimos com cópias e reparo dos arquivos, preservando configurações. `pm clear` não faz parte do procedimento recomendado aqui.

## `xset` não responde, mas XSDL está aberto.

Confira os logs e `adb shell netstat -lnt`. Durante as falhas o XSDL tentou displays diferentes: `:0` usa 6000, `:1` usa 6001 e assim por diante. Também havia um processo antigo `xsel` segurando a porta 6000. Identificamos o processo real, encerramos somente ele e reabrimos o app; o estado final voltou a `:0`. Não copie PIDs de exemplos para matar processos.

## O toque está deslocado ou funciona como um touchpad.

No caso real era **movimento relativo + clique com timeout**, e não uma matriz de calibração errada. Ajustamos para movimento absoluto e clique normal; o usuário confirmou que ficou correto. Use primeiro o menu **Desktop, No Emulation**. [TOUCH.md](TOUCH.md) explica o patch restrito ao arquivo validado.

## Por que aparecem 800 × 480 e 800 × 444?

800 × 480 é a superfície Android. O app tinha 800 × 444 disponíveis; a barra de navegação ocupa a faixa restante. Não force uma escala de toque só por essa diferença: neste caso a matriz já estava correta.

## O patch Python recusou meu arquivo de configuração.

Isso é intencional: ele verifica versão, tamanho, offsets e modo conhecido antes de alterar bytes. O arquivo pode pertencer a outra versão ou configuração. Use os menus do XSDL; não remova as verificações para forçar um patch desconhecido.

## A tela pode apagar mesmo com o tablet carregando?

Sim. O descanso do X11 é separado das opções Android. O launcher aplica `xset s off`; confirmamos `timeout: 0`. Ele também tenta desativar DPMS, mas o servidor testado informa que não suporta DPMS. Outras configurações de bloqueio do Android devem ser verificadas no próprio tablet.

## Preciso de root, DroidKlipp ou de um APK novo?

Não desenvolvemos APK nem instalamos DroidKlipp. O tablet já fornecia shell ADB root, usado nos reparos internos. Isso não demonstra que um tablet sem root precise ser modificado; nele, os reparos descritos podem não ser possíveis e o caminho deve ser reavaliado.

## Funciona sozinho depois de ligar ou reconectar?

Agora há um supervisor habilitado no boot. Fizemos reboots reais do tablet e do BTT e a interface voltou automaticamente, sem reabrir o aplicativo manualmente. Ele aguarda o Android terminar de iniciar, recupera o encaminhamento USB/XSDL e reinicia somente KlipperScreen. O teste físico de retirar/recolocar o cabo continua pendente. Veja [instalação e resultados da supervisão](RECONEXAO.md).

## O supervisor pode reiniciar minha impressora se o tablet cair?

Ele não reinicia BTT, Klipper ou Moonraker. Recupera apenas XSDL e KlipperScreen. Os reboots do BTT e tablet foram testes explícitos de instalação com a impressora ociosa, não ações automáticas do supervisor.

## A reconexão é garantida em qualquer situação?

Os reboots documentados passaram no hardware testado. O supervisor não conserta cabo defeituoso, falta de alimentação, autorização ADB revogada, PIN de bloqueio ou depuração USB desativada. A recuperação depende desses pré-requisitos; não há um prazo universal de segundos. Um Android lento pode levar mais tempo para completar o boot e desenhar a interface.

## Outra IA consegue fazer isso seguindo o repositório?

Uma IA com terminal e acesso autorizado ao SSH/ADB pode executar e verificar as etapas. Ela precisa observar o equipamento, adaptar serial/caminhos e pedir ações físicas quando necessário. O guia não concede acesso nem garante que qualquer modelo de tablet seja compatível. Veja o [roteiro para continuidade com IA](CONTINUAR_COM_IA.md).

## As tags vão permitir que qualquer pessoa encontre o projeto?

Os tópicos ajudam a classificar o conteúdo, mas **um repositório privado continua privado**. Somente pessoas com acesso podem ler o material. Publicar para todo mundo é uma decisão separada do proprietário.
