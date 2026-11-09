# BTT Pi + tablet Android 4.2.2 como tela touchscreen do Klipper via USB

> Documento de referência e roteiro de implementação — 09/11/2026
> **Status:** solução tecnicamente plausível e documentada; **ainda não testada neste BTT Pi e neste tablet**.

## 1. Objetivo e requisitos

Transformar um **tablet com Android 4.2.2 (API 17)** em painel touchscreen dedicado de uma impressora 3D cujo host é um **BTT Pi com Klipper**.

**Requisitos definidos:**

- **USB obrigatório para a comunicação de dados**, sem depender de Wi-Fi para transmitir a interface.
- Exibir **KlipperScreen**, com controles como movimentação dos eixos, aquecimento, acompanhamento da impressão e demais funções do Klipper.
- O tablet deve funcionar como **terminal de exibição e toque**; o KlipperScreen e a integração com a impressora executam no BTT Pi.
- Em etapa posterior, a solução deve iniciar automaticamente quando a impressora/BTT Pi ligar.
- **Alimentação, carregamento e desligamento elétrico do tablet estão fora do escopo desta etapa**; serão resolvidos separadamente.
- Preferência por software existente, sem desenvolver ou compilar um APK novo se não houver necessidade.

### Como funciona, de fato

```text
BTT Pi (Linux)
 ├─ Klipper + Moonraker
 ├─ KlipperScreen (aplicação gráfica X11)
 └─ ADB (encaminhamento da conexão X11)
                │
                │ Cabo USB com dados / ADB
                ▼
Tablet Android 4.2.2
 └─ XServer XSDL (desenha a interface e envia eventos de toque)
```

**Importante:** não é vídeo HDMI bruto transmitido por USB. O Linux produz a interface gráfica X11; o Android, por meio do XServer XSDL, renderiza os elementos e encaminha os eventos de toque. Por isso o tablet **ainda usa sua CPU/GPU para renderizar**, mas a lógica de controle continua no BTT Pi.

## 2. Projetos e compatibilidade

| Componente | Função | Decisão |
|---|---|---|
| [KlipperScreen](https://github.com/KlipperScreen/KlipperScreen) | Interface gráfica de controle da impressora | Usar no BTT Pi |
| [ADB](https://developer.android.com/tools/adb) | Canal de comunicação por USB e encaminhamento de portas | Usar |
| [XServer XSDL 1.20.51](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/XServer-XSDL-1.20.51.apk/download) | Servidor X11 no Android | **Primeira versão a testar** |
| [XServer XSDL 1.11.40](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/XServer-XSDL-1.11.40.apk/download) | Versão antiga do servidor X11 | **Plano B**, recomendado na documentação do KlipperScreen para Android 4 |
| [DroidKlipp — scripts Linux](https://github.com/CodeMasterCody3D/DroidKlipp) | Automatização via USB/ADB, monitoramento e reinicialização | Referência para adaptar **depois** |
| [DroidKlipp Android APK](https://github.com/CodeMasterCody3D/DroidKlipp-Android-APK) | APK customizado usado pelo DroidKlipp | **Não é a primeira escolha** para Android 4.2.2 |

**Compatibilidade do Android:** o Android 4.2.2 corresponde à API 17. A versão **XServer XSDL 1.20.51** é identificada em catálogos como compatível com Android **4.1+**. Versões posteriores como **1.20.52/1.20.53** exigem Android **5.0+** segundo os registros de versões consultados. A versão 1.20.51 é a **mais recente com compatibilidade declarada que foi confirmada** para Android 4.2.2; isso **não garante** desempenho ou funcionamento no tablet específico.

**ATENÇÃO — DroidKlipp não é substituível sem adaptação:** os scripts atuais do DroidKlipp procuram o pacote/atividade Android `droidklipp.x.org.server/x.org.server.MainActivity`. O XServer XSDL original tem outro identificador. Portanto, **não execute o instalador do DroidKlipp esperando que ele funcione diretamente com o APK antigo**. Primeiro valide o método USB/ADB **oficial do KlipperScreen**. Só depois, se necessário, adapte a detecção, inicialização e monitoramento.

## 3. Plano de implementação por etapas

### Etapa A — Diagnóstico não destrutivo no BTT Pi

Conectar ao BTT Pi por terminal (SSH para **administração**, não para a transmissão da tela) e executar:

```bash
cat /etc/os-release
uname -a
id
command -v adb || true
command -v git || true
ls -ld ~/KlipperScreen ~/KlipperScreen/scripts ~/.KlipperScreen-env 2>/dev/null || true
systemctl status KlipperScreen --no-pager 2>/dev/null || true
```

Verificar se Klipper, Moonraker e KlipperScreen estão instalados e funcionando. Registrar arquitetura Linux, versão do sistema e espaço livre antes de instalar pacotes. **Não presumir Raspberry Pi OS nem que todos os caminhos sejam os padrões.**

### Etapa B — Preparar Android e validar ADB

1. No tablet, habilitar **Opções do desenvolvedor → Depuração USB**.
2. Instalar o **XServer XSDL 1.20.51** pelo pacote disponibilizado na SourceForge. Caso falhe, testar a **1.11.40**.
3. Abrir o XServer XSDL ao menos uma vez. Para o teste inicial, deixá-lo na tela de espera.
4. Conectar o tablet à porta **USB de dados** do BTT Pi com um cabo de dados.
5. No BTT Pi, verificar e instalar ADB somente se necessário:

```bash
command -v adb
# Se o comando acima não encontrar adb, executar:
sudo apt update
sudo apt install adb
adb devices -l
```

> Em algumas distribuições Debian/derivadas o pacote pode se chamar `android-tools-adb`. Ajustar conforme o repositório disponível. Os comandos de instalação são **condicionais**: não precisam ser executados se o ADB já estiver instalado. **Não rodar comandos de instalação cegamente.**

Resultados esperados do `adb devices -l`:

- `device`: dispositivo autorizado e acessível.
- `unauthorized`: confirmar no tablet a autorização da chave RSA para depuração USB.
- Lista vazia: testar cabo, porta, modo USB, permissões/udev e reconhecimento do dispositivo pelo Linux (`lsusb`, `dmesg`).

O ADB é indispensável para **este caminho via USB**; o tablet não precisa estar no Wi-Fi para transmitir a interface.

### Etapa C — Instalar ou configurar KlipperScreen

Se o KlipperScreen não estiver instalado, seguir a [instalação oficial](https://klipperscreen.readthedocs.io/en/latest/Installation/) e validar seus pré-requisitos. Exemplo de instalação manual **apenas depois de avaliar a imagem e as dependências do BTT Pi**:

```bash
cd ~
git clone https://github.com/KlipperScreen/KlipperScreen.git
./KlipperScreen/scripts/KlipperScreen-install.sh
```

Usar o backend **X11** e, se necessário, habilitar o serviço durante a instalação.

Para ativar o script oficial de conexão USB/ADB, quando o repositório do KlipperScreen estiver em `~/KlipperScreen`:

```bash
cd ~/KlipperScreen/scripts
cp sample-android-adb.sh launch_KlipperScreen.sh
chmod +x launch_KlipperScreen.sh
```

Com **XServer XSDL já aberto no tablet**:

```bash
sudo service KlipperScreen restart
sudo systemctl status KlipperScreen --no-pager
```

A configuração acima segue a documentação do KlipperScreen para Android via ADB. **Não edite outros serviços ou instale o DroidKlipp em paralelo neste primeiro teste**: isso pode gerar conflito de processos e encaminhamentos X11.

### Etapa D — Ajustar toque e tela

No XServer XSDL, na abertura do aplicativo:

- `Change Device Configuration → Mouse Emulation Mode → Desktop, No Emulation` (nomes podem variar por versão): testar toques diretos.
- Para evitar que o servidor X apague a tela, em `Command line parameters, one argument per line`, inserir **em linhas separadas**:

```text
-s
0
```

- Ajustar orientação e resolução se os botões ficarem pequenos ou o toque não corresponder à posição mostrada.
- A documentação também recomenda **desativar DPMS** no cenário X11 para reduzir o risco de vazamentos de memória.

### Etapa E — Estabilidade e automação

Só depois de comprovar que **a interface é exibida e os toques funcionam via USB**:

1. Reiniciar o serviço e depois o BTT Pi; verificar reconexão.
2. Desconectar/reconectar o USB; observar o comportamento do ADB e do XServer.
3. Medir uso de memória e CPU do BTT Pi por período prolongado.
4. Criar automação mínima para iniciar o XServer XSDL no Android e recuperar o KlipperScreen em caso de falha.
5. Se usar os scripts do **DroidKlipp** como base, **adaptar o nome do pacote e da atividade Android**, além de revisar os serviços existentes. Evitar copiar todo o instalador sem entender suas alterações em `systemd` e `udev`.
6. Só considerar APK customizado se a versão antiga do XServer não atender às necessidades.

**Não misturar automação do DroidKlipp com o método oficial durante o diagnóstico.**

## 4. Diagnóstico e solução de problemas

| Sintoma | Verificações |
|---|---|
| `adb devices` não lista o tablet | Cabo com dados, USB, depuração habilitada, `lsusb`, `dmesg`, regras de permissão |
| `unauthorized` | Desbloquear Android e aceitar chave RSA de depuração |
| O APK não instala | Versão mínima do Android/API; tentar XServer XSDL 1.11.40 |
| XServer aberto, mas tela sem KlipperScreen | Serviço do KlipperScreen, script `launch_KlipperScreen.sh`, encaminhamento ADB, logs |
| A tela aparece, mas toque incorreto | Configuração de emulação de mouse, rotação e resolução |
| Interface congela com o tempo | Uso de RAM, possível vazamento X11/DPMS, reinício controlado, teste com versão antiga |
| Funciona manualmente, não depois de reiniciar | Dependência entre serviço, ADB autorizado e início da atividade Android |

Comandos úteis de inspeção:

```bash
adb devices -l
adb forward --list
sudo systemctl status KlipperScreen --no-pager
journalctl -u KlipperScreen -n 80 --no-pager
free -h
```

A documentação do KlipperScreen alerta que o XServer XSDL pode degradar desempenho e causar vazamentos de memória em certas instalações X11, particularmente se DPMS permanecer ativo. Isso precisa ser testado antes de instalar o tablet como painel definitivo.

## 5. Critérios de aceite

- [ ] `adb devices` identifica o tablet como `device` (sem Wi-Fi).
- [ ] XServer XSDL 1.20.51 inicia no Android 4.2.2 **ou** a versão 1.11.40 é usada como alternativa.
- [ ] KlipperScreen é renderizado no tablet **somente pelo USB**.
- [ ] Toques no tablet acionam corretamente os controles da interface.
- [ ] Movimentação de eixo é validada **com a impressora em condições seguras**, inicialmente com pequenos deslocamentos e supervisão.
- [ ] Não há travamentos ou crescimento excessivo de memória durante teste prolongado.
- [ ] Reconexão USB e reinicialização do BTT Pi têm comportamento documentado.
- [ ] Automação de início/reconexão é implementada apenas após a validação manual.
- [ ] Questões de alimentação/ligar e desligar foram deixadas para uma etapa separada.

## 6. Orientação para uso do Codex

O Codex será usado **para diagnosticar e configurar o BTT Pi**, não para transmitir a imagem. A conexão administrativa com o BTT Pi pode ser via SSH. Para evitar alterações desnecessárias e consumo excessivo de contexto:

1. Começar por comandos de diagnóstico **sem alterações no sistema**.
2. Usar a documentação oficial do KlipperScreen como fonte primária.
3. Executar instalação apenas com aprovação e explicando o impacto.
4. Trabalhar em etapas pequenas: ADB → APK → KlipperScreen → toque → estabilidade → automação.
5. Exibir somente trechos relevantes dos logs e resumir os resultados.
6. Não compilar APK nem clonar projetos adicionais sem evidência de necessidade.
7. Antes de alterar serviços e scripts, salvar cópia e prever rollback.

**Observação sobre tokens:** estimativas discutidas anteriormente (dezenas de milhares de tokens, dependendo da depuração) **não são cotas garantidas nem uma previsão verificável de consumo**. O uso real do Codex depende de modelo, tamanho do contexto, execuções e retrabalho; o plano acima busca diminuir as tentativas.

## 7. Informações que ainda precisam ser levantadas

- Modelo exato do tablet e arquitetura (ARMv7/ARMv8/x86), memória e resolução.
- Distribuição e versão do Linux instalada no BTT Pi.
- Estado atual dos serviços Klipper, Moonraker e KlipperScreen.
- Tipo de porta USB disponível no BTT Pi e detecção do tablet pelo ADB.
- Funcionamento real do XServer XSDL 1.20.51 no hardware; se falhar, resultado do teste com 1.11.40.

## 8. Fontes e links

1. [KlipperScreen — Android via XServer XSDL / ADB (documentação oficial)](https://klipperscreen.readthedocs.io/en/latest/Android/)
2. [KlipperScreen — instalação oficial](https://klipperscreen.readthedocs.io/en/latest/Installation/)
3. [XServer XSDL — repositório oficial de APKs na SourceForge](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/)
4. [XServer XSDL 1.20.51 — download](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/XServer-XSDL-1.20.51.apk/download)
5. [XServer XSDL 1.11.40 — download](https://sourceforge.net/projects/libsdl-android/files/apk/XServer-XSDL/XServer-XSDL-1.11.40.apk/download)
6. [Histórico e versões mínimas no APKMirror](https://www.apkmirror.com/apk/pelya/xserver-xsdl/)
7. [DroidKlipp — scripts Linux](https://github.com/CodeMasterCody3D/DroidKlipp)
8. [DroidKlipp — APK Android](https://github.com/CodeMasterCody3D/DroidKlipp-Android-APK)

**Segurança:** usar somente arquivos de fontes confiáveis, revisar scripts externos antes de executar como `sudo` e não expor o serviço ADB na rede. Habilitar depuração USB concede amplo controle ao host autorizado sobre o tablet.
