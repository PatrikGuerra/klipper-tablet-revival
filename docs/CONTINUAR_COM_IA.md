# Continuar ou reproduzir com a ajuda de uma IA

Este material foi organizado para uma pessoa **ou uma IA com ferramentas adequadas** entender o resultado e executar as etapas. Com terminal, acesso SSH autorizado, senha/sudo quando necessário e acesso ADB ao tablet, outra IA pode conduzir o mesmo tipo de diagnóstico e configuração. O resultado precisa ser verificado no hardware: não basta copiar comandos ou supor que todo Android seja igual.

Uma IA somente de texto pode orientar, mas alguém precisará executar os comandos. Mesmo uma IA com terminal pode precisar que uma pessoa habilite depuração, aceite autorização USB, conecte o cabo e teste o toque físico. Compartilhe credenciais somente pelo meio apropriado da sua sessão, nunca por commit no repositório.

## Texto que você pode entregar a outra IA

> Quero usar um tablet Android como painel do KlipperScreen por USB/ADB. Leia README.md, docs/COMECE_AQUI.md, docs/TABLET_TESTADO.md e docs/FAQ.md antes de agir. Use docs/INSTALACAO.md e docs/TOUCH.md para os reparos específicos. Inspecione o estado real do meu BTT e tablet; não assuma que o serial, UID, VID/PID ou caminhos serão iguais ao exemplar NT-1710 documentado. Faça cópias antes de alterações, execute uma etapa por vez e confira a saída esperada. Preserve Klipper, Moonraker e periféricos que não fazem parte do painel. Não acione movimentos, aquecimento ou extrusão para testar a interface. Não limpe dados do Android para resolver erros sem discutir o impacto. Dê preferência ao menu de toque do XSDL; use o patch binário só quando ele validar o perfil. No final, separe o que foi comprovado do que ainda falta testar. Não envie senhas, tokens ou backups locais ao GitHub.

## Informações que a IA deve levantar

| Pergunta | Como verificar |
|---|---|
| Qual é o host correto? | IP/SSH informado pelo proprietário e resposta do sistema |
| O KlipperScreen já existe? | Diretórios, `systemctl cat` e estado dos serviços |
| Qual USB é o tablet? | `lsusb` e `adb devices -l`, preservando os demais dispositivos |
| Qual é o Android/ABI? | `getprop` do dispositivo selecionado |
| Há acesso interno ao aplicativo? | `adb shell id` e permissões; não presumir root |
| O servidor gráfico responde? | Encaminhamento ADB e `xset -display :100 -q` |
| O toque é direto? | Configuração SDL e confirmação física da pessoa |
| O que realmente foi validado? | Logs, comparação dos arquivos, imagem e feedback do usuário |

## Pontos para parar e investigar

- Serial diferente: adaptar o launcher, não selecionar outro USB por engano.
- VID/PID diferente: revisar a regra udev antes de instalar.
- Configuração binária rejeitada: usar o menu ou estudar a versão, sem remover proteções.
- Acesso negado ao Android: não presumir que os reparos root funcionarão.
- Erros XKB/TLS: consultar a FAQ e os arquivos da mesma versão do APK.
- Serviço ativo sem imagem: verificar X11 e a tela antes de declarar sucesso.

O objetivo é uma execução compreensível e verificável. Registre adaptações e novos resultados para que a próxima pessoa também consiga acompanhar.
