# CLAUDE.md

> Raiz do projeto Godot (`res://CLAUDE.md`). Mantido enxuto de propósito: cada subpasta relevante tem seu próprio `CLAUDE.md` com os detalhes locais (o Claude Code carrega esses arquivos adicionalmente quando entra na pasta). Aqui ficam só os princípios gerais e os pontos que evitam erro em qualquer parte do projeto — o resto vira ruído.

## Stack

- Godot 4.x
- GDScript, com tipagem estática sempre que possível (`var speed: float`, `func foo() -> void:`)

## Comandos

Godot 4.7 via Homebrew, binário `godot` no PATH. Todos os comandos rodam da raiz do projeto.

| O quê | Comando |
|---|---|
| Abrir o editor | `godot -e --path .` |
| Rodar o jogo | `godot --path .` |
| Rodar uma cena isolada | `godot --path . --scene res://stages/<fase>/<fase>.tscn` |
| Importar assets novos sem abrir a GUI | `godot --headless --path . --import` |
| Fotografar uma cena rodando | `godot --path . --scene res://tools/screenshot.tscn -- --scene res://<cena>.tscn --out shot.png` |
| Conferir os critérios de voo | `godot --headless --path . --scene res://tools/voo_check.tscn` |
| Compilar um sprite `.pix` para PNG | `.venv/bin/python .claude/skills/pixel-art/scripts/build_sprite.py <arquivo>.pix` |
| Preparar o ambiente da ferramenta de sprite (uma vez) | `python3 -m venv .venv && .venv/bin/pip install -r .claude/skills/pixel-art/requirements.txt` |
| Checar erro de sintaxe e de tipo num script | `godot --headless --path . --check-only --script res://<caminho>.gd` |

- **IMPORTANT:** `--check-only` sai com código **0 mesmo quando o script tem erro de parse**. Não encadeie com `&&` achando que falha — leia a saída e procure por `SCRIPT ERROR`.
- **IMPORTANT:** `--check-only` também **não carrega os autoloads**. Script que usa um deles acusa `Identifier not found` ali e funciona no jogo. Para esses, a verificação real é subir o jogo (`--quit-after`) ou rodar `voo_check`.
- **Não existe cena principal.** A fase de protótipo de voo foi apagada e o mapa de verdade ainda não foi montado, então `run/main_scene` está vazio e toda fase sobe por `--scene`. Assim que a primeira região existir, aponte `run/main_scene` para ela.
- **IMPORTANT:** a ferramenta de sprite roda no **ambiente virtual do projeto** (`.venv/bin/python`), nunca em `python3`. O python do sistema, no macOS, recusa instalar pacote, então `python3 build_sprite.py` falha com erro de Pillow ausente por mais que o Pillow esteja instalado em algum outro lugar. As dependências estão em `.claude/skills/pixel-art/requirements.txt`, com versão fixa; a `.venv/` em si não é versionada e se refaz com o comando da tabela em poucos segundos.
- Não há framework de teste instalado (GUT, GdUnit4). Se instalar um, documente o comando aqui.

## Princípios de arquitetura

1. Organize primeiro por função no jogo, depois por tipo de asset. Nunca criar pastas de topo do tipo `scripts/`, `scenes/`, `sprites/` — agrupar por tipo de asset só vale no último nível, ver "Estrutura da pasta-folha".
2. Poucas pastas de topo. Antes de criar uma pasta nova direto em `res://`, verifique se ela não cabe dentro de uma existente.
3. `entities/` = irmão do player na scene tree. `stages/` = pai do player. Detalhes em `entities/CLAUDE.md`.
4. Categorias com subtipos usam classe base no topo da pasta + subpastas irmãs por subtipo. Detalhes em `entities/items/CLAUDE.md`.
5. **IMPORTANT:** todo sistema que roda em background o tempo todo é autoload em `utilities/`, sufixo `_manager.gd`, documentado em `utilities/CLAUDE.md` — nunca em outro lugar.

## Mapa de pastas

```
res://
├── assets/              # ver assets/CLAUDE.md — só o que permeia o jogo inteiro
├── common/              # ver common/CLAUDE.md — reutilizável, zero dependência deste jogo
├── config/              # ver config/CLAUDE.md — opções expostas ao jogador
├── docs/                # notas e referências avulsas; tem .gdignore, o Godot não enxerga
├── entities/            # ver entities/CLAUDE.md
│   ├── estruturas/          # o que é construído e fica parado no mundo
│   ├── items/               # ver entities/items/CLAUDE.md
│   ├── player/              # ver entities/player/CLAUDE.md
│   └── ui/                  # ver entities/ui/CLAUDE.md
├── localization/        # ver localization/CLAUDE.md — textos localizados
├── stages/              # ver stages/CLAUDE.md
│   └── art/                 # ver stages/art/CLAUDE.md — arte compartilhada entre fases
├── tools/               # ver tools/CLAUDE.md — ferramenta de dev, não entra no build
└── utilities/           # ver utilities/CLAUDE.md
```

## Estrutura da pasta-folha

O princípio 1 tem duas metades. A segunda vive aqui: agrupar por tipo de asset é permitido **só no fim da árvore**, dentro da pasta da própria entidade ou fase — ou da categoria, quando o asset serve a categoria inteira.

```
entities/<categoria>/<entidade>/
├── art/                 # sprites, animações, texturas só dessa entidade
├── data/                # Resources (.tres) dessa entidade
├── sound/               # sons só dessa entidade
├── <entidade>.tscn
└── <entidade>.gd
```

- `art/`, `data/` e `sound/` existem só na pasta da entidade ou na da categoria dela — nunca como pasta de topo.
- Asset que serve à **categoria inteira**, e não a uma entidade, ganha `art/`, `data/` ou `sound/` na pasta da própria categoria (ex.: `entities/player/data/modelos.tres`, a lista de modelos, e `entities/player/art/chama_1.png`, a chama que os três usam). A entidade nunca alcança dentro da pasta de outra entidade: se um segundo dono aparece, o asset sobe um nível.
- Omita a que estiver vazia; crie quando aparecer o primeiro arquivo.
- O script de mesmo nome é o caso comum, não uma obrigação: variação que só muda número e arte compartilha o script da categoria, como fazem os três modelos da nave (ver `entities/player/CLAUDE.md`).
- O ganho é esse: tudo que descreve uma entidade está numa pasta só, então tanto criar quanto depurar essa entidade tem um único lugar pra olhar.

## Onde colocar coisa nova (tabela de decisão rápida)

| Você quer adicionar... | Vai em... |
|---|---|
| Novo personagem ou NPC | `entities/<categoria>/` |
| Novo item/upgrade/habilidade | `entities/items/<subtipo>/` (crie o subtipo se não existir) |
| Plataforma, outpost, mina ou construção fixa do mundo | `entities/estruturas/` |
| Lugar de pouso demarcado de um ponto de coleta | `entities/estruturas/` — ver seção 10 do conceito |
| Modelo novo da nave do jogador | `entities/player/<modelo>/` — ver `entities/player/CLAUDE.md` |
| Nova tela ou elemento de UI | `entities/ui/` |
| Arte, som ou dado de uma entidade específica | `art/` / `sound/` / `data/` dentro da pasta da própria entidade |
| Nova fase/área/mapa | `stages/<nome>/` — a receita de terreno está em `stages/CLAUDE.md` |
| Arte usada por mais de uma fase (grão, estrela, pedra) | `stages/art/` |
| Trilha sonora, fonte ou asset global do jogo | `assets/` |
| Texto exibido ao jogador | `localization/` (no script, use a chave de tradução) |
| Opção do menu de configurações | `config/` (a tela em si é `entities/ui/`) |
| Novo sistema persistente global (roda o tempo todo) | `utilities/`, como autoload — atualize `utilities/CLAUDE.md` |
| Helper deste jogo, chamado sob demanda, sem estado global | `utilities/`, sem o sufixo `_manager` |
| Sistema genérico sem dependência do jogo | `common/` |

Se nada da tabela encaixar, pare e pense em qual pasta de topo faz mais sentido antes de criar uma nova (princípio 2).

## Convenções de nomenclatura

- `snake_case` para arquivos e pastas; `PascalCase` para `class_name`.
- Sufixo consistente indicando a classe base estendida (ex.: `_item.gd` para tudo que `extends Item`).
- Sufixo `_manager.gd` exclusivamente para autoloads.
- Cena e script do mesmo objeto sempre no mesmo diretório, mesmo nome base (`plataforma_de_pouso.tscn` + `plataforma_de_pouso.gd`).

## Padrão de commit

Formato: `tipo(escopo): assunto`

- **Assunto** em português, verbo no presente (`adiciona`, `corrige`, `move`), minúsculo, sem ponto final, até 72 caracteres.
- **Escopo** = a pasta de topo afetada: `entities`, `stages`, `utilities`, `assets`, `common`, `config`, `localization`. Use `meta` para o que é do repositório e não do jogo (`CLAUDE.md`, `.gitignore`, `project.godot`). Nunca invente escopo que não seja uma dessas. Omita quando o commit atravessa tudo — e no tipo `docs`, que já implica a pasta.
- **Tipos:**

| Tipo | Quando |
|---|---|
| `feat` | mecânica ou sistema novo |
| `content` | conteúdo novo usando sistema que já existe (entidade, fase, item, arte) |
| `fix` | correção de bug |
| `refactor` | reorganiza sem mudar comportamento — inclui mover ou renomear pasta |
| `perf` | performance |
| `docs` | `CLAUDE.md` ou `docs/` |
| `chore` | project settings, `.gitignore`, ferramentas, dependências |

- **Corpo** (opcional, linha em branco antes, quebra em 72 colunas): explica o *porquê*. O diff já mostra o *o quê* — não descreva arquivo por arquivo.

Exemplos:

```
content(entities): adiciona picareta de ferro
feat(utilities): adiciona save_manager com autosave a cada 5 min
refactor(stages): move grão de rocha para stages/art
docs: documenta convenção de pasta-folha
```

### Regras para o Claude

- **IMPORTANT:** não commite nem faça push sem o usuário pedir explicitamente.
- Um commit = uma mudança lógica. Se o assunto precisa de "e", provavelmente são dois commits.
- Mudança de estrutura anda junto com sua documentação: criou pasta de topo ou autoload, o `CLAUDE.md` da raiz e o local correspondente entram no **mesmo** commit (ver Manutenção).
- Cena e script do mesmo objeto sempre no mesmo commit — `.tscn` sem o `.gd` que ele referencia quebra o projeto de quem der pull. Vale também para o `.import` de um asset novo.
- Nunca commitar `.godot/`, `.DS_Store` nem arquivo de export com credencial.
- Commits feitos pelo Claude Code levam o trailer `Co-Authored-By: Claude` automaticamente; não remova nem duplique.

## Instruções específicas para o Claude Code (economia de contexto)

- **IMPORTANT:** não faça varredura ampla do projeto (nada de `find` recursivo ou ler `res://` inteiro) antes de começar uma tarefa. Use o mapa e a tabela acima pra ir direto na pasta certa, e deixe o `CLAUDE.md` local dela carregar os detalhes.
- Para entender uma entidade específica, leia só a pasta dela (script + cena + dados), não a pasta-mãe inteira.
- Antes de assumir a API de um autoload, confira a tabela em `utilities/CLAUDE.md`; só abra o arquivo se precisar de um detalhe que a tabela não cobre.
- Ao criar pasta de topo ou autoload novo, atualize este arquivo e o `CLAUDE.md` local correspondente no mesmo commit.

## Manutenção

- Depois que o projeto Godot existir de fato, rode `/init` pra revisar este arquivo contra a estrutura real, e `/doctor` periodicamente — ele sugere cortar o que o Claude já deriva sozinho do código.
- Versione este arquivo e os `CLAUDE.md` locais no git.
- Revise a cada 3–6 meses ou após mudança grande de modelo.
