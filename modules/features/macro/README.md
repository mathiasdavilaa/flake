# macro-mouse

Cliques de mouse automatizados (farm/auto-clicker), disparados por um
bind do mango e controlados por unit systemd `--user`.

- **Ligar/desligar:** `SUPER+F8` (definido em `mango/binds.conf`,
  chama `mango/scripts/macro-toggle.sh`)
- **Editar posições / criar macro novo:** este arquivo, seção
  [Adicionar um macro](#adicionar-um-macro)
- **Algo quebrou:** seção [Troubleshooting](#troubleshooting)

## Como funciona

```
SUPER+F8
   │
   ▼
mango/scripts/macro-toggle.sh <macro>     (roda como filho do mango)
   │  systemctl --user is-active?
   │  ├─ sim → stop
   │  └─ não → start
   ▼
systemd --user: macro-mouse@<macro>.service
   │  (template definido em modules/features/macro/default.nix)
   ▼
macro-mouse.sh <macro>        (gerado via pkgs.writeShellScript)
   │  loop: pra cada posição cadastrada → click_at(x, y)
   ▼
ydotool mousemove (relativo) + ydotool click
```

Três peças, cada uma resolvendo um problema específico:

### 1. `macro-toggle.sh` — por que não dá só `systemctl start`

`systemctl --user start` numa unit que já está ativa **não faz nada**
(nem erro). Se o bind chamasse `start` direto, o primeiro F8 ligava e
todos os seguintes eram no-op — não dava pra parar. O toggle checa
`is-active` e decide entre `start`/`stop`.

Ele também importa `MANGO_INSTANCE_SIGNATURE`, `WAYLAND_DISPLAY` e
`XDG_RUNTIME_DIR` pro ambiente do systemd `--user` antes de dar
`start` (`systemctl --user import-environment ...`). Sem isso, o
`mmsg` chamado *de dentro* do serviço não acha o socket do
compositor — o bind roda como filho do mango e tem essas variáveis,
mas um serviço systemd não herda isso sozinho.

### 2. Cliques por movimento relativo, não `--absolute`

`ydotool mousemove --absolute` **não é confiável em setups
multi-monitor**. O dispositivo virtual que o ydotool cria aparece
pro mango como tipo `pointer` (não `touch`/`tablet`), e o mango só
permite fixar num monitor específico (`devicerule=...,monitor:`)
pra esses dois tipos — não pra `pointer`. Na prática, isso significa
que as coordenadas absolutas acabam mapeadas pro monitor "errado",
**independente de qual estiver com foco**.

A solução foi trocar o mecanismo de clique: cada `click_at(x, y)`

1. pergunta pro mango onde o cursor está *de verdade* agora
   (`mmsg get cursorpos` — a mesma fonte que `get-mousepos.sh` usa
   pra você medir posições manualmente);
2. calcula o delta até o alvo;
3. manda esse delta pro `ydotool mousemove` (sem `--absolute`).

Isso funciona em qualquer monitor, porque não depende de nenhum
mapeamento absoluto — só anda a partir de onde o cursor já está. E
como cada clique relê a posição real antes de se mover, erros não
acumulam ao longo de várias voltas do macro.

Pré-requisito pra isso ser preciso: o dispositivo virtual do
ydotool precisa estar **sem aceleração de ponteiro** (senão o delta
relativo não bate 1:1 com o pixel — aceleração distorce movimentos
pequenos vs. grandes). Isso é feito uma vez em
`mango/devices.conf`, sem afetar seu mouse de verdade:

```
devicerule=name:ydotoold virtual device,accel_profile:0,accel_speed:0
```

### 3. Resolução — desktop (1920x1080) vs. laptop (1920x1200)

As posições de cada macro são guardadas junto com a resolução em
que foram medidas (`<PREFIXO>_REF`). Em qualquer resolução diferente,
o script reescala proporcionalmente. Se preferir medir à mão numa
resolução específica em vez de confiar no reescalonamento (mais
preciso, mas dá mais trabalho), declare um array
`<PREFIXO>_POSITIONS_<LARGURA>x<ALTURA>` — quando ele existir, é
usado literalmente.

A resolução é detectada automaticamente via `mmsg` (reflete
`monitorrule`/mudanças feitas em tempo real, ao contrário de ler o
EDID do monitor). Se a detecção errar — por exemplo, mais de um
monitor e o "focado" não é o que você quer — force com:

```bash
MACRO_RES=1920x1080 macro-mouse.sh portal
```

Isso também vale como variável de ambiente na unit systemd, se
quiser fixar por máquina em vez de confiar na detecção.

## Adicionar um macro

Tudo em `macro-mouse.sh`, sem mexer em nenhum `case`/`if`:

1. **Descubra as coordenadas.** Ou com o mouse:
   ```bash
   ~/.config/mango/scripts/get-mousepos.sh
   ```
   Ou uma leitura rápida e única:
   ```bash
   ~/.config/mango/scripts/macro-mouse.sh --pos
   ```

2. **Declare o array de posições** e a resolução em que foram
   medidas:
   ```bash
   MINECRAFT_REF="1920x1080"
   MINECRAFT_POSITIONS=(
       "500 300"
       "800 500"
   )
   ```
   Opcional: `MINECRAFT_DELAY="0.3"` sobrescreve o delay entre
   cliques só pra esse macro (padrão: `$MACRO_DELAY` ou `0.5s`).

3. **Registre o nome** (e apelidos, se quiser) em `MACRO_ALIASES`:
   ```bash
   declare -A MACRO_ALIASES=(
       [portal]=PORTAL
       [minecraft]=MINECRAFT   # ← nova linha
   )
   ```

4. **Teste sem clicar de verdade:**
   ```bash
   ~/.config/mango/scripts/macro-mouse.sh minecraft --dry-run
   ```
   Mostra cada clique planejado (posição atual, alvo, delta)
   sem mexer no mouse.

5. **Teste uma volta só, de verdade:**
   ```bash
   ~/.config/mango/scripts/macro-mouse.sh minecraft --once
   ```

6. **Use:**
   ```bash
   ~/.config/mango/scripts/macro-toggle.sh minecraft
   ```
   (ou adicione um bind novo em `binds.conf`, mesmo padrão do F8)

### Flags e variáveis — referência rápida

| Uso                                  | Efeito                                   |
| ------------------------------------- | ----------------------------------------- |
| `macro-mouse.sh <macro>`              | inicia, loop infinito                     |
| `macro-mouse.sh <macro> --once`       | uma volta só                              |
| `macro-mouse.sh <macro> --dry-run`    | só imprime, não move nada                 |
| `macro-mouse.sh --list`               | lista macros cadastrados                  |
| `macro-mouse.sh --pos`                | imprime a posição atual do cursor         |
| `MACRO_RES=WxH`                       | força a resolução                         |
| `MACRO_DELAY=segundos`                | delay padrão entre cliques                |
| `<PREFIXO>_DELAY=segundos`            | delay só pra aquele macro                 |

## Troubleshooting

**Bind não faz nada:** confira permissão de execução —
`ls -la ~/.config/mango/scripts/macro-toggle.sh` precisa mostrar
`x`. O home-manager preserva o modo do arquivo tal como está no
git; se faltar, `chmod +x` no repo, `git add`, rebuild.

**F8 liga mas não desliga:** normalmente indica que o bind voltou
a chamar `systemctl start` direto em vez de passar pelo
`macro-toggle.sh`.

**Clica no monitor errado / em posições aleatórias:** veja a seção
[Cliques por movimento relativo](#2-cliques-por-movimento-relativo-não---absolute)
acima — é exatamente o problema que esse design resolve. Se ainda
assim desviar, confirme que o `devicerule` de `accel_profile:0` em
`devices.conf` foi aplicado (`mmsg get all-devices` deve mostrar
`ydotoold virtual device` com aceleração zerada) e que o `nrs` +
`mmsg dispatch reload_config` rodaram depois da edição.

**Mudei o script/config e nada mudou:** `macro-mouse.sh` é injetado
dentro da unit systemd via `pkgs.writeShellScript` — qualquer edição
precisa de `nrs` + `systemctl --user daemon-reload`. Já
`macro-toggle.sh` e `binds.conf` são só symlinks (`xdg.configFile`)
pro store — também precisam de `nrs`, a não ser que você troque pra
`mkOutOfStoreSymlink` (aí edições nesses dois arquivos específicos
valem na hora, sem rebuild).

**`mmsg: command not found` dentro do serviço:** o `mmsg` some do
`PATH` de um serviço systemd `--user` se não estiver em
`environment.systemPackages` (nível sistema) — pacotes de um
devShell (ex: zed) não contam. `jq` é explicitamente adicionado no
`Path` da unit em `default.nix` pelo mesmo motivo.
