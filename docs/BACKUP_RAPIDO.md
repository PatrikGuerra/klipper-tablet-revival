# Backup com um comando, sem precisar de uma IA

O comando **`btt-backup` já foi instalado no BTT**. Ele reutiliza o método de arquivos + boot do backup completo anterior, acrescentando verificações e execução em segundo plano. Não é preciso abrir este chat para cada cópia.

## Usar a partir do computador

No PowerShell/terminal:

```sh
ssh -t <DeviceUser>@<DeviceHostIp> "sudo btt-backup --start"
```

Digite a senha de SSH quando solicitada. Você pode fechar a conexão depois da mensagem de início: o trabalho roda como serviço temporário do systemd no próprio BTT.

Para acompanhar:

```sh
ssh -t <DeviceUser>@<DeviceHostIp> "sudo btt-backup --status"
```

Se preferir entrar no SSH normalmente, execute lá:

```sh
sudo btt-backup --start
sudo btt-backup --status
```

O endereço IP pode mudar na sua rede. O comando depende de o BTT estar ligado e acessível; não é um serviço de nuvem.

## Antes de iniciar

1. Conecte o **mesmo pendrive** usado neste projeto.
2. Deixe a impressora ociosa: sem impressão, pausa ou alvo de aquecimento ativo.
3. Não inicie impressão nem atualize o sistema enquanto o backup estiver em captura.
4. Não retire o pendrive nem desligue o BTT até terminar.

Opcionalmente, faça apenas a verificação:

```sh
sudo btt-backup --check
```

Ela monta o pendrive se necessário, confere o equipamento e espaço, consulta o Moonraker e desmonta o pendrive se foi ela que o montou. **Não cria backup nem para serviços.** Se o Moonraker não responder ou os dados forem insuficientes, a cópia é recusada; o script não presume ociosidade.

## O que acontece automaticamente

1. Confere os UUIDs da raiz, boot e pendrive; o destino precisa ser USB e separado do cartão do sistema.
2. Bloqueia execuções simultâneas.
3. Verifica espaço de forma conservadora: uso atual da raiz + tamanho do boot + 1 GiB. Não conta com uma taxa de compressão garantida.
4. Cria uma **pasta nova com data, hora e sufixo único**, como `BTT-backup-2026-11-10_08-30-00-AbCdEf`. Não sobrescreve o backup anterior.
5. Salva layout de partições, UUIDs, pacotes, fstab, estado inicial e uma cópia do próprio script.
6. Para temporariamente o supervisor do tablet, KlipperScreen, Moonraker e Klipper, **somente se estavam ativos**. O supervisor também precisa parar, para não religar o painel no meio da captura.
7. Copia o prefixo de bootloader, a partição de boot e os arquivos persistentes da raiz, incluindo configurações, códigos, ambientes e dados da impressora.
8. Compacta e divide a raiz em partes de 1900 MiB, compatíveis com FAT32. Usa `pigz` com dois processos se já estiver instalado; caso contrário usa `gzip`. Não instala pacotes sozinho.
9. Religa os serviços anteriores assim que termina a captura, antes da verificação demorada.
10. Verifica gzip, leitura integral do tar e hashes SHA-256; registra `SUCCESS` somente se tudo passar.
11. Sincroniza e desmonta o pendrive se foi o script que o montou. Se já estava montado, mantém a montagem anterior.

Se houver falha ou interrupção normal, o script tenta religar os serviços e preserva a pasta parcial, marcada `FAILED`. Não apaga o backup antigo para abrir espaço. Interrupção de energia ou `kill -9` não permitem executar uma rotina de recuperação; não desligue o equipamento durante o trabalho.

## Como saber se terminou

```sh
sudo btt-backup --status
```

Fases: `PREFLIGHT`, `PREPARING`, `CAPTURING`, `VALIDATING`, `SUCCESS` ou `FAILED`.

O serviço temporário pode desaparecer da lista ao terminar; por isso o comando também mostra o registro persistente em `/var/lib/btt-backup`. Em uma pasta final válida, `RESULT.txt` contém:

```text
exit=0
status=SUCCESS
```

`checksum-validation.txt` deve mostrar `OK` para o prefixo de boot, imagem de boot e todas as partes da raiz. A última execução concluída é identificada separadamente no status: não confunda um resultado antigo com o trabalho atual ainda em andamento.

Para ver o log ao vivo no BTT:

```sh
sudo journalctl -u btt-system-backup -f
```

Para sair **apenas da visualização do log**, pressione Ctrl+C. Isso não cancela o serviço. Para interromper o backup:

```sh
sudo btt-backup --stop
```

Aguarde a parada e confira se os serviços voltaram. A cópia interrompida não deve ser usada como backup validado.

## Onde o backup fica

Na raiz do pendrive cadastrado, em uma nova pasta `BTT-backup-DATA_HORA-SUFIXO`. O backup anterior `BTT-backup-2026-11-09-before-autoconnect` permanece separado.

Arquivos principais:

| Arquivo | Conteúdo |
|---|---|
| `root.tar.gz.part-*` | Sistema de arquivos raiz, compactado e dividido |
| `boot-partition.img.gz` | Imagem da partição FAT de boot |
| `boot-prefix.bin` | Região anterior à primeira partição, incluindo bootloader/tabela |
| `partition-table.sfdisk` / `.json` | Layout do cartão |
| `disks.txt`, `fstab.txt`, `packages.txt` | Informações para recuperação |
| `root-inventory.txt` | Lista dos arquivos arquivados |
| `SHA256SUMS` | Hashes dos arquivos de dados |
| `RESULT.txt`, `progress.log`, `root-tar.log` | Resultado, fases e avisos |
| `RESTORE.txt` | Orientações para recuperação em outro Linux |

O formato é **backup dos arquivos persistentes e estruturas de boot**, não uma imagem bruta única do cartão. `/dev`, `/proc`, `/sys`, `/run`, `/tmp`, `/mnt`, `/media` e `lost+found` são excluídos. Boot é copiado separadamente. Outros volumes persistentes inesperados fazem a execução parar para não serem omitidos silenciosamente.

O Linux permanece ligado: não é um snapshot atômico de todos os serviços. Um retorno não zero do tar, inclusive arquivo alterado durante a cópia, é tratado como falha nesta versão reutilizável. Sockets ignorados que não causam erro são recriados pelos serviços.

## Equipamento cadastrado

| Item | UUID |
|---|---|
| Raiz do BTT | `10ee7f0c-c457-4a96-8da8-13398de6c273` |
| Boot | `AEBD-0084` |
| Pendrive | `05B1-3EBC` |

Se trocar ou formatar o pendrive, o UUID pode mudar. O script vai recusar o destino até os identificadores serem revisados com `lsblk`, evitando gravar no disco errado. Não depende de o pendrive continuar se chamando `/dev/sda1`.

## Instalar novamente ou atualizar

No BTT, na raiz deste repositório:

```sh
bash -n scripts/backup_btt_full.sh
sudo install -m 0755 scripts/backup_btt_full.sh /usr/local/bin/btt-backup
sudo btt-backup --check
```

Preserve uma cópia do comando anterior antes de substituir uma versão instalada. `--run` serve para execução em primeiro plano; nesse modo mantenha o SSH aberto. O uso recomendado é `--start`.

## Validação desta versão

Foram conferidos sintaxe, pré-verificação real no BTT e proteções com dados de teste: ociosa aceita; impressão, pausa, aquecimento, estado desconhecido e dados ausentes recusados. O teste de falha usa um serviço fictício para conferir o registro `FAILED` e a tentativa de restauração sem interromper serviços reais.

A cópia completa anterior de 2,9 GiB já foi feita e validada. Não foi iniciada outra cópia integral apenas para testar esta interface reutilizável; o código de captura usa o mesmo método, com proteções adicionais. A restauração em outro cartão continua sem teste físico. [Detalhes do backup anterior e recuperação](BACKUP_E_RECONEXAO.md).

O conteúdo do backup pode incluir senhas e chaves. Ele fica no pendrive, nunca é enviado ao GitHub por este script.
