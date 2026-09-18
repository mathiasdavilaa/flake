# macro-mouse

Cliques de mouse automatizados (farm/auto-clicker), disparados por um
bind do mango e controlados por unit systemd `--user`.

- **Ligar/desligar:** `SUPER+F8` (definido em `mango/binds.conf`,
  chama o comando `macro-toggle`)
- **Editar posições / criar macro novo:** este arquivo, seção
  [Adicionar um macro](#adicionar-um-macro)
- **Algo quebrou:** seção [Troubleshooting](#troubleshooting)

## Como funciona

`macro-mouse`, `macro-toggle` e `get-mousepos` são empacotados via
`pkgs.writeShellScriptBin` em `modules/features/macro/default.nix` e
expostos no PATH via `home.packages` — não são mais symlinks dentro
de `~/.config/mango/scripts`.

```
SUPER+F8
   │
   ▼
macro-toggle <macro>     (roda como filho do mango, comando no PATH)
   │  systemctl --user is-active?
   │  ├─ sim → stop
   │  └─ não → start
   ▼
systemd --user: macro-mouse@<macro>.service
   │  (template definido em modules/features/macro/default.nix)
   ▼
macro-mouse <macro>        (gerado via pkgs.writeShellScriptBin)
   │  loop: pra cada posição cadastrada → click_at(x, y)
   ▼
ydotool mousemove (relativo) + ydotool click
```

Três peças, cada uma resolvendo um problema específico:

### 1. `macro-toggle` — por que não dá só `systemctl start`

`systemctl --user start` numa unit que já está ativa **não faz nada**
(nem erro). Se o bind chamasse `start` direto, o primeiro F8 ligava e
todos os seguintes eram no-op — não dava pra parar. O toggle checa
`is-active` e decide entre `start`/`stop`. Antes de dar `start`, ele
também para qualquer outro `macro-mouse@*.service` que esteja
rodando, pra nunca ter dois macros clicando ao mesmo tempo.

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
   (`mmsg get cursorpos` — a mesma fonte que `get-mousepos` usa
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

### 3. Resolução — desktop (1920x1080, 2 monitores) vs. laptop (1920x1200)

As posições de cada macro são guardadas em coordenada **local ao
monitor** (relativa ao canto superior esquerdo dele), junto com a
resolução em que foram medidas (`<PREFIXO>_REF`). Em qualquer
resolução diferente, o script reescala proporcionalmente. Se
preferir medir à mão numa resolução específica em vez de confiar no
reescalonamento (mais preciso, mas dá mais trabalho), declare um
array `<PREFIXO>_POSITIONS_<LARGURA>x<ALTURA>` — quando ele existir,
é usado literalmente (sem reescalonar).

A resolução **e a origem** do monitor focado são detectadas via
`mmsg` (reflete `monitorrule`/mudanças em tempo real, ao contrário
de ler o EDID). O script pega `width`, `height`, `x` e `y` do
monitor focado — o `x`/`y` é a posição desse monitor no espaço
global de coordenadas (essencial no seu desktop, que tem **dois
monitores lado a lado**: o segundo monitor não começa em `x=0`, e
sem somar esse offset o clique sairia no monitor errado sempre que
o foco não estivesse no monitor onde o macro foi medido). Se o seu
`mmsg` não expuser `x`/`y` no JSON, o script cai pra offset `0,0`
automaticamente — mesmo comportamento de antes, sem quebrar nada.

Se a detecção errar, force com:

```bash
MACRO_RES=1920x1080 macro-mouse portal
```

Isso também vale como variável de ambiente na unit systemd, se
quiser fixar por máquina em vez de confiar na detecção (nesse caso
o offset de monitor não é aplicado — assume origem `0,0`).

## Adicionar um macro

Cada macro é um arquivo próprio em `macros/*.macro`
(`modules/features/macro/macros/`), carregado automaticamente pelo
`macro-mouse` — **não precisa editar `macro-mouse.sh` nem
`default.nix`**. Duas formas de criar um:

### Guiado (`--capture`) — recomendado

```bash
macro-mouse --capture minecraft
```

Aperta ENTER com o mouse em cima de cada ponto que o macro deve
clicar; `q` + ENTER termina. O comando já detecta o monitor focado,
guarda as posições em coordenada **local** a ele (funciona em
qualquer monitor do desktop, não só onde você capturou) e imprime
um bloco pronto pra colar:

```
# macro: minecraft

MINECRAFT_REF="1920x1080"
MINECRAFT_POSITIONS=(
    "500 300"
    "800 500"
)

MACRO_ALIASES+=(
    [minecraft]=MINECRAFT
)
```

Salve isso em `modules/features/macro/macros/minecraft.macro`
(nome do arquivo é só organização, não precisa bater com o nome do
macro), `nrs`, e já dá pra usar.

### Na mão

1. Crie `macros/<nome>.macro` seguindo o padrão
   `<PREFIXO>_REF` / `<PREFIXO>_POSITIONS` (posições em
   pixel, relativas ao canto superior esquerdo do monitor onde
   foram medidas):
   ```bash
   MINECRAFT_REF="1920x1080"
   MINECRAFT_POSITIONS=(
       "500 300"
       "800 500"
   )
   MACRO_ALIASES+=(
       [minecraft]=MINECRAFT
   )
   ```
   Opcional: `<PREFIXO>_POSITIONS_<LARGURA>x<ALTURA>` pra medidas
   feitas à mão numa resolução específica (usado literalmente, sem
   reescalonar). Opcional: `<PREFIXO>_DELAY="0.3"` sobrescreve o
   delay padrão só pra esse macro.

2. Descubra as coordenadas: `get-mousepos` (mostra a posição do
   cursor ao vivo) ou `macro-mouse --pos` (uma leitura só).

3. **Teste sem clicar de verdade:**
   ```bash
   macro-mouse minecraft --dry-run
   ```

4. **Teste uma volta só, de verdade:**
   ```bash
   macro-mouse minecraft --once
   ```

5. **Use:**
   ```bash
   macro-toggle minecraft
   ```
   (ou adicione um bind novo em `binds.conf`, mesmo padrão do F8)

### Flags e variáveis — referência rápida

| Uso                                  | Efeito                                   |
| ------------------------------------- | ----------------------------------------- |
| `macro-mouse <macro>`                 | inicia, loop infinito                     |
| `macro-mouse <macro> --once`          | uma volta só                              |
| `macro-mouse <macro> --dry-run`       | só imprime, não move nada                 |
| `macro-mouse --capture [nome]`        | modo guiado, gera um `.macro` pronto      |
| `macro-mouse --list`                  | lista macros cadastrados                  |
| `macro-mouse --pos`                   | imprime a posição atual do cursor         |
| `MACRO_RES=WxH`                       | força a resolução (offset de monitor = 0) |
| `MACRO_DELAY=segundos`                | delay padrão entre cliques                |
| `<PREFIXO>_DELAY=segundos`            | delay só pra aquele macro                 |

## Troubleshooting

**Bind não faz nada:** confira se `macro-toggle` está no PATH —
`which macro-toggle` (vem de `home.packages` via
`pkgs.writeShellScriptBin`, então sempre fica executável; não
depende mais de bit de execução no git). Se não achar, `nrs` não
rodou ou o `home-manager-<user>.service` falhou — confira com
`systemctl --user status home-manager-$(whoami).service`.

**F8 liga mas não desliga:** normalmente indica que o bind voltou
a chamar `systemctl start` direto em vez de passar pelo
`macro-toggle`.

**Clica no monitor errado / em posições aleatórias:** veja a seção
[Cliques por movimento relativo](#2-cliques-por-movimento-relativo-não---absolute)
acima — é exatamente o problema que esse design resolve. Se ainda
assim desviar, confirme que o `devicerule` de `accel_profile:0` em
`devices.conf` foi aplicado (`mmsg get all-devices` deve mostrar
`ydotoold virtual device` com aceleração zerada) e que o `nrs` +
`mmsg reload_config` rodaram depois da edição.

**Mudei o script/config e nada mudou:** `macro-mouse` e
`macro-toggle` são pacotes (`pkgs.writeShellScriptBin`) injetados no
`home.packages` e na unit systemd — qualquer edição precisa de `nrs`
+ `systemctl --user daemon-reload` (a unit referencia o caminho do
`macro-mouse` no store, então uma troca de geração já cobre isso).
Já `binds.conf` é symlink (`xdg.configFile`) pro store — também
precisa de `nrs`, e além disso o mango só relê a config quando você
manda (`SUPER,r` ou `mmsg reload_config`), não sozinho.

**`mmsg: command not found` dentro do serviço:** o `mmsg` some do
`PATH` de um serviço systemd `--user` se não estiver em
`environment.systemPackages` (nível sistema) — pacotes de um
devShell (ex: zed) não contam. `jq` é explicitamente adicionado no
`Path` da unit em `default.nix` pelo mesmo motivo.
