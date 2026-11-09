# Registro da implementação

Data: 09/11/2026, fuso America/Sao_Paulo. Este registro distingue resultados observados de sugestões do roteiro inicial.

## Ambiente confirmado

| Componente | Resultado |
|---|---|
| Host | BTT Pi / imagem identificada como BTT-CB1 2.3.4 Bullseye |
| Sistema | Debian GNU/Linux 11, aarch64, kernel 5.16.17-sun50iw9 |
| Usuário | <DeviceUser>, membro de plugdev e sudo |
| SSH usado | <DeviceHostIp>; `btt.local` não resolveu na máquina de administração |
| RAM | Cerca de 986 MiB |
| Disco raiz | 57 GiB, cerca de 51 GiB livres no diagnóstico inicial |
| Tablet | NT-1710, produto nuclear_basic, Android 4.2.2, armeabi-v7a |
| USB tablet | VID:PID 18d1:0003, serial ADB <DeviceSerialNumber> |
| XSDL funcional | x.org.server/.MainActivity, versão 1.11.40 |
| KlipperScreen | Já instalado, commit 34610ceae31e12a10cc980e20a1dec9976f97dd4 |
| Klipper observado nos logs | v0.13.0-464-g48f0b3cad |
| Serviços | Klipper, Moonraker e KlipperScreen ativos |

## Sequência real

1. Leitura do roteiro original como referência, sem executar cegamente suas instruções.
2. Tentativa de SSH por `btt.local` falhou na resolução. O IP informado pelo usuário permitiu o acesso.
3. Inspeção somente de leitura confirmou três periféricos USB: tablet, webcam Microsoft LifeCam VX-500 e pendrive Kingston. Não houve alteração nos dois últimos.
4. ADB estava ausente; instalado com dependências pelos repositórios Debian. Não foi feito upgrade geral.
5. Tablet detectado, mas `no permissions`. A primeira escrita da regra perdeu aspas na passagem entre shells e foi corrigida. Foi aplicada a regra exclusiva `18d1:0003`, modo 0660, grupo plugdev. Após reiniciar o daemon ADB, estado `device`.
6. XSDL 1.20.51, obtido no SourceForge oficial, instalou com sucesso. Ao abrir, exibiu `X server failed to launch`.
7. XSDL 1.11.40 foi instalado por cima com `-r -d`, mantendo dados. É a alternativa citada pela documentação oficial para Android 4.
8. O app falhou ao baixar fontes por incompatibilidade TLS do Android antigo. O BTT baixou o arquivo oficial e transferiu por ADB.
9. Apenas copiar o arquivo compactado não resolveu: o app tentou retomar o download. A cópia da árvore para o armazenamento externo falhou em links simbólicos. Foram disponibilizadas fontes na pasta interna do app; a extração foi interrompida após longa espera, mas a árvore resultante permitiu o funcionamento. Integridade integral das fontes não foi auditada.
10. O marcador de download contendo apenas a URL foi rejeitado/removido pelo app. O marcador com a especificação completa da versão antiga foi aceito.
11. Foram encontrados arquivos X11 ausentes e um `xkbcomp` apontando para binário da versão anterior. Repostos arquivos de `assets/data-1.tgz` e o binário ARMv7 não PIE de `assets/binaries-armeabi-v7a.zip`, ambos do APK 1.11.40.
12. A tentativa de limpar dados via `pm clear x.org.server` foi bloqueada antes da execução pela revisão automática. Não foi contornada; foi seguido o reparo de arquivos preservando dados. Uma cópia TAR foi gerada no tablet antes da troca do xkbcomp; restauração integral não testada.
13. Durante as falhas, o XSDL mudou de número de display e um `xsel` antigo manteve a porta 6000 ocupada. O processo foi identificado e encerrado. A instância final passou a escutar no display :0, porta 6000.
14. `adb forward tcp:6100 tcp:6000` e `xset -display :100 -q` responderam corretamente.
15. Criado launcher baseado no exemplo já presente no KlipperScreen: serial definido, `am start` no Android antigo, descanso desativado via xset. Unidade systemd preservada. Reiniciado apenas o serviço KlipperScreen.
16. Captura do Android confirmou a interface do KlipperScreen e temperaturas do Moonraker. Nenhum comando físico de impressora foi executado.
17. Usuário relatou toque errado. Matriz XInput identidade, superfície 800×444, calibração SDL sem ajustes; configuração revelava modo touchpad (`relative=true`) e clique 7.
18. Backup da configuração, parada de KlipperScreen/XSDL, alteração mínima para movimento absoluto e clique normal. Leitura posterior confirmou o arquivo aplicado. Usuário confirmou que estava funcionando muito bem.

## Estado final e limitações

O painel funciona e o toque foi confirmado fisicamente pelo usuário. Não houve teste de isolamento desligando Wi-Fi, mas a conexão X11 configurada usa o encaminhamento ADB USB, não o IP do tablet. Reinício completo, reconexão USB e monitoramento prolongado não foram testados. O início da atividade Android está no launcher, mas não há watchdog, DroidKlipp, APK customizado, alteração de alimentação ou automação adicional.

A captura em `images/klipperscreen-usb.png` é anterior à correção do touch; comprova a imagem, enquanto a confirmação posterior do usuário comprova a experiência de toque.
