# CLAUDE.md

> Raiz do projeto Godot (`res://CLAUDE.md`). Mantido enxuto de propósito: cada pasta relevante ganha o seu próprio `CLAUDE.md`, criado junto com o primeiro arquivo de verdade dela. Aqui ficam só os princípios gerais e o que evita erro em qualquer parte do projeto — o resto vira ruído.

**Estado atual: o laço de entrar e sair de um planeta está fechado, com dois lugares para comparar.** Existe o espaço, finito e dando a volta nos quatro lados, com estrelas e dois corpos; chegar perto de um acende o convite, e a tecla abre a tela de regiões dele. Escolher uma região leva a nave, por piloto automático, ao ponto de aparecimento que a ficha define. Dentro dela, os lados dão a volta e subir devolve a tela de regiões. O `M` abre o mapa do sistema sem parar o voo.

| Lugar | Região | O que muda |
|---|---|---|
| Arvo | Bosque | gravidade de Terra, ar denso, mata alta |
| Vesk | Cratera | gravidade de Lua, vácuo, campo de asteroides |

O jogo abre num menu, e a nave nasce no espaço: o primeiro lugar é escolha do jogador. Vesk é protótipo declarado: a arte dele é gerada, não desenhada. Ainda não existem contratos, economia nem save. Do mapa abaixo, `common/` e `localization/` seguem sendo alvo, não retrato.

## Stack

Godot 4.7.2, GDScript com tipagem estática sempre que possível (`var massa: float`, `func pousar() -> void:`). O resto está em `docs/stack.md`.

O jogo é o descrito em `docs/conceito-de-jogo.md`: um jogo de pilotagem 2D inspirado em Lunar Lander, com duas vistas da mesma nave. Aquele documento manda no design, este aqui manda na implementação.

**IMPORTANT: a mecânica é constante e o lugar é livre.** Pousar é sempre a mesma coisa, e é por isso que cada planeta pode ser radicalmente diferente do anterior, inclusive surreal. Um planeta inteiro de doce é tão legítimo quanto um deserto de gelo. A ambientação industrial descreve a nave e o trabalho, nunca os lugares onde se pousa, e a herança do Lunar Lander é o voo, nunca o cenário. Não assuma bioma, paleta nem vegetação de um planeta: leia o `.tres` dele ou pergunte.

## Comandos

Binário `godot` no PATH, via Homebrew. Todos os comandos rodam da raiz do projeto.

| O quê | Comando |
|---|---|
| Abrir o editor | `godot -e --path .` |
| Rodar o jogo | `godot --path .` |
| Rodar uma cena isolada | `godot --path . --scene res://mundo/planetas/arvo/regioes/bosque/bosque_regiao.tscn` |
| Fotografar uma cena rodando | `godot --path . --scene res://tools/foto.tscn -- --cena res://<cena>.tscn --saida foto.png` |
| Conferir os critérios de voo | `godot --headless --path . --scene res://tools/voo_check.tscn` |
| Conferir se o cenário está apoiado | `godot --headless --path . --scene res://tools/cenario_check.tscn -- --regiao res://<região>.tscn` |
| Conferir a entrada e a saída de um planeta | `godot --headless --path . --scene res://tools/orbita_check.tscn` |
| Conferir a primeira tela | `godot --headless --path . --scene res://tools/menu_check.tscn` |
| Importar assets novos sem abrir a GUI | `godot --headless --path . --import` |
| Checar erro de sintaxe e de tipo num script | `godot --headless --path . --check-only --script res://<caminho>.gd` |

- **IMPORTANT:** `--check-only` sai com código **0 mesmo quando o script tem erro de parse**. Não encadeie com `&&` achando que falha — leia a saída e procure por `SCRIPT ERROR`.
- **IMPORTANT:** `--check-only` também **não carrega os autoloads**. Script que usa um deles acusa `Identifier not found` ali e funciona no jogo. Para esses, a verificação real é subir o jogo com `--quit-after`.
- **A cena principal é `ui/menu/menu.tscn`**, e ela abre `mundo/sistema/sistema.tscn`, que é a raiz do jogo: nave, câmera, interface e o nó onde a região entra. Trocar a cena inteira só é permitido nessa passagem, porque ali ainda não existe nave para preservar. Uma região também abre sozinha por `--scene`, sem nave, que é como se trabalha terreno.
- Não há framework de teste instalado. Se instalar um, documente o comando aqui.
- A ação `reiniciar` no mapa de entrada é ferramenta de dev, para iterar pouso sem fechar o jogo. O conceito não tem estado de fim, então ela nunca vira mecânica nem aparece para o jogador.

## Princípios de arquitetura

1. **Organize por função no jogo, depois por tipo de asset.** Nunca criar pasta de topo `scripts/`, `scenes/` ou `sprites/` — agrupar por tipo de asset só vale no último nível, ver "Estrutura da pasta-folha".
2. **Poucas pastas de topo.** Antes de criar uma direto em `res://`, verifique se ela não cabe numa que já existe.
3. **`mundo/` é lugar, `entities/` é o que fica dentro de um lugar.** Um planeta é lugar. A plataforma onde se pousa nele é entidade.
4. **Categoria com subtipos põe a classe base no topo da pasta** e os subtipos em pastas irmãs. Vale também para `Resource`: o script do esquema fica no nível da categoria, e os `.tres` que o instanciam ficam num `data/` abaixo.
5. **IMPORTANT:** todo sistema que roda em background o tempo todo é autoload em `utilities/`, sufixo `_manager.gd`, documentado em `utilities/CLAUDE.md` — nunca em outro lugar.
6. **IMPORTANT: grandeza física se escreve em unidade de verdade.** Metro, segundo, quilo e grau, nunca pixel. `Escala` converte na fronteira com a física do Godot, e `Escala.PIXELS_POR_METRO` é a única definição de quanto vale um pixel. Se você viu `px/s` dentro de um `.tres`, alguém errou.
7. **A pasta nasce com o primeiro arquivo.** Não crie pasta vazia para reservar lugar. O `CLAUDE.md` local entra no mesmo commit do primeiro arquivo dela.

## Mapa de pastas

```
res://
├── assets/              # só o que permeia o jogo inteiro: fonte, música, shader global
├── common/              # reutilizável, zero dependência deste jogo
├── docs/                # conceito e notas; tem .gdignore, o Godot não enxerga
├── entities/            # o que é instanciado dentro de um lugar
│   ├── nave/                # o jogador: uma cena, três modelos lidos de dados
│   ├── estruturas/          # construído e parado: plataforma, boca de mina, baliza
│   ├── carga/               # o que a nave embarca, larga ou recupera
│   ├── obstaculos/          # asteroide e destroço soltos na descida
│   └── cenario/             # vivo e sem função mecânica: fauna, planta, fumaça
├── localization/        # CSV de tradução; o .translation é gerado e ignorado no git
├── mundo/               # os lugares
│   ├── sistema/             # a vista de espaço: a cena que roda o jogo e a câmera
│   ├── planetas/<nome>/     # dados + corpo no espaço + região de superfície
│   ├── outposts/<nome>/     # o mesmo formato, para quem emite contrato
│   └── art/                 # arte que mais de um lugar usa: grão, estrela, partícula
├── tools/               # ferramenta de dev, não entra no build
├── ui/                  # HUD, tela de regiões, mapa, pausa, configurações
└── utilities/           # autoloads e helpers deste jogo
```

Duas pastas que pareceriam naturais não existem, de propósito:

- **Não existe `stages/`.** O jogo não tem fase. Tem um sistema contínuo e lugares dentro dele, e é assim que o glossário do conceito fala.
- **Não existe `config/`.** A opção do jogador é um `Resource` em `utilities/data/`, aplicado por um autoload, e a tela dela é `ui/configuracoes/`.

## Os lugares

**O jogo roda numa cena só.** `mundo/sistema/sistema.tscn` é a raiz: ela tem a nave, os corpos do sistema e um nó vazio onde a região entra. Chegar perto de um corpo acende o convite de entrada; a tecla para a nave e abre a tela de regiões daquele lugar; escolher uma região instancia o terreno dela ali dentro. Ganhar altitude devolve a tela de regiões.

**A nave é criada uma vez, quando o jogo abre, e nunca é recriada.** Entrar num planeta não destrói a nave. O terreno é que aparece em volta dela:

```
voando no espaço             dentro de uma região
Sistema                      Sistema
├── Nave                     ├── Nave    ← a mesma instância, sem interrupção
├── Corpos/Ferrum            ├── Corpos/Ferrum
├── Camera                   ├── Camera
└── LugarAtual               └── LugarAtual
                                 └── CrateraRegiao   ← o terreno entra aqui
```

**IMPORTANT: nunca use `change_scene_to_file()` para entrar ou sair de um planeta.** Essa função destrói a árvore de cena inteira e monta outra no lugar. A nave morre e outra nasce parada, sem rotação e sem carga. Para o jogo não parecer quebrado você teria que copiar velocidade, ângulo, velocidade angular e porão antes da troca e reinjetar tudo depois. É onde mora o bug clássico desse tipo de jogo: a nave chega no planeta com velocidade zero ou com a inclinação resetada.

Sem recriação não existe transferência de estado: carga, massa e desgaste continuam sendo os da mesma nave, e a câmera continua seguindo o mesmo nó.

**O que a nave perde na troca é só a posição, e isso é escolha.** Ao entrar num lugar ela para onde está e reaparece no ponto que a ficha da região define, levada por um piloto automático curto. A versão anterior entrava descendo, sem nada ser recolocado, e entregava inércia contínua atravessando a atmosfera. Trocamos aquilo por isto de propósito: num jogo de lugares desenhados à mão, **onde a nave aparece é decisão de quem desenhou o lugar**, e não consequência da trajetória de chegada. O que sobrevive da promessa antiga é o que importa para o jogo: a nave é a mesma, e o mundo não é reconstruído.

O preço são três coisas, todas conhecidas. A cena do sistema fica residente na memória o tempo todo, o que é barato num jogo deste tamanho. O carregamento da região não pode travar o quadro, então região grande pede carregamento em segundo plano. E as coordenadas do espaço e as do terreno passam a conviver, que é a questão de escala ainda em aberto.

**Um lugar é uma pasta.** Planeta e outpost têm a mesma forma:

```
mundo/planetas/<nome>/
├── art/                     # arte do corpo, e o que mais de uma região usar
├── <nome>.tres              # gravidade, recurso, paleta, e a lista de regiões
├── <nome>_corpo.tscn        # como ele se vê na vista de espaço
└── regioes/<região>/        # uma pasta por superfície, com a arte dela
    ├── <região>.tres        # nome, cena e onde a nave aparece
    └── <região>_regiao.tscn # o terreno, onde se pousa
```

- **Um planeta tem várias regiões.** A ficha dele lista as fichas delas, e a tela de regiões lê essa lista sem carregar cena nenhuma: nome e assunto são dados leves, e o terreno só é instanciado quando o jogador escolhe descer.
- O nome do lugar prefixa as cenas. `corpo.tscn` repetido em oito pastas é inútil na busca rápida do editor.
- A região abre sozinha por `--scene`, sem o sistema. É assim que se testa um pouso sem voar até lá.
- O esquema do `Resource` é `mundo/planetas/planeta.gd`, no nível da categoria. Cada `<nome>.tres` é uma instância dele.
- A classe base de toda superfície é `mundo/regiao.gd`, um nível acima, porque planeta e outpost usam a mesma forma de cena.
- Uma região não conhece a nave nem a ficha do planeta. Quem entra no lugar chama `aplicar(planeta)`. Isso evita que a ficha e a cena apontem uma para a outra e mantém a região abrindo sozinha.
- **O padrão do projeto é o espaço:** gravidade zero e amortecimento zero. Um planeta repõe a gravidade localmente, com a `Area2D` da região dele, e sair dela é voltar ao vácuo sem escrever uma linha.
- Outpost usa `_regiao.tscn` também. O conceito reserva a palavra "região" para planeta, mas a cena tem a mesma forma e não vale inventar um segundo nome.

**A pasta por lugar existe justamente porque os lugares não se parecem.** Quase toda a arte de um planeta é só dele e vive no `art/` dele. `mundo/art/` fica pequeno de propósito: ali entra só o que é genérico de verdade, como grão de tela, campo de estrelas e partícula. A regra de subir o asset quando aparece um segundo dono continua valendo para o que é genérico. Ela não vale para arte de assunto: se dois planetas querem a mesma pedra de doce, o problema não é a pasta, são os dois planetas. Ver o risco de planetas intercambiáveis na seção 17 do conceito.

## Estrutura da pasta-folha

O princípio 1 tem duas metades. A segunda vive aqui: agrupar por tipo de asset é permitido **só no fim da árvore**, dentro da pasta da própria entidade, do próprio lugar, ou da categoria quando o asset serve a categoria inteira.

```
entities/<categoria>/<entidade>/
├── art/                 # sprites, animações, texturas só dessa entidade
├── data/                # os .tres dessa entidade
├── sound/               # sons só dessa entidade
├── <entidade>.tscn
└── <entidade>.gd
```

- `art/`, `data/` e `sound/` existem só na pasta da entidade, do lugar ou da categoria — nunca como pasta de topo.
- Asset que serve à **categoria inteira** ganha a pasta um nível acima. A chama do motor vale para os três modelos, então ela é `entities/nave/art/`, não da pasta de um modelo. A entidade nunca alcança dentro da pasta de outra: se aparece um segundo dono, o asset sobe um nível.
- Omita a pasta que estiver vazia; crie quando aparecer o primeiro arquivo.
- O script de mesmo nome é o caso comum, não uma obrigação. Variação que só muda número e arte compartilha o script e a cena da categoria, como fazem os três modelos da nave.
- O ganho é esse: tudo que descreve uma entidade está numa pasta só, então criar e depurar essa entidade têm um lugar único para olhar.

## Onde colocar coisa nova

| Você quer adicionar... | Vai em... |
|---|---|
| Planeta novo | `mundo/planetas/<nome>/` |
| Outpost novo | `mundo/outposts/<nome>/` |
| Região nova num planeta | `mundo/planetas/<nome>/regioes/<região>/`, e uma linha na lista da ficha do planeta |
| Terreno ou ponto de coleta | dentro da pasta da região dele |
| Arte que mais de um lugar usa | `mundo/art/` |
| Modelo novo da nave | `.tres` em `entities/nave/data/modelos/`, arte em `entities/nave/art/` |
| Módulo, slot ou equipamento | `entities/nave/data/modulos/` |
| Plataforma, baliza ou construção fixa do mundo | `entities/estruturas/` |
| Lugar de pouso demarcado de um ponto de coleta | `entities/estruturas/` — ver seção 10 do conceito |
| Carga solta, recurso mineral, destroço | `entities/carga/` |
| Asteroide ou obstáculo móvel da descida | `entities/obstaculos/` |
| Bicho, planta que balança, fumarola, qualquer enfeite animado | `entities/cenario/` |
| Arte, som ou dado de uma entidade específica | `art/`, `sound/` ou `data/` dentro da pasta dela |
| Tela, HUD ou elemento de interface | `ui/` |
| Texto exibido ao jogador | `localization/`, e no script use a chave de tradução |
| Opção do menu de configurações | `Resource` em `utilities/data/`; a tela é `ui/configuracoes/` |
| Sistema persistente que roda o tempo todo | `utilities/`, como autoload `_manager.gd` |
| Helper deste jogo, chamado sob demanda, sem estado global | `utilities/`, sem o sufixo `_manager` |
| Sistema genérico, sem nada deste jogo dentro | `common/` |
| Trilha sonora, fonte ou asset global | `assets/` |
| Ferramenta de dev que não entra no build | `tools/` |

Se nada encaixar, pare e pense em qual pasta de topo faz mais sentido antes de criar uma nova (princípio 2).

`entities/cenario/` é para o que parece vivo e não faz nada: fauna, planta que balança, fumarola, poeira levantada pelo motor. A regra que segura a categoria é a seção 10 do conceito. Cenário nunca vira tarefa, nunca disputa leitura com o lugar de pouso e nunca entra no save, porque vive na cena da região e morre com ela. No instante em que uma dessas três cair, a coisa deixou de ser cenário e mudou de pasta.

## Dados: os Resource do jogo

O conceito é orientado a dado, e é aí que está o maior ganho do Godot neste projeto. Uma definição vira `.tres` em vez de virar código.

| Esquema | Onde mora | O que descreve |
|---|---|---|
| `Planeta` | `mundo/planetas/planeta.gd` | gravidade em m/s², arrasto do ar, recurso, as regiões e a luz do lugar |
| `FichaDeRegiao` | `mundo/ficha_de_regiao.gd` | nome, cena do terreno e onde a nave aparece ao chegar |
| `Outpost` | `mundo/outposts/outpost.gd` | que contratos ele emite |
| `Contrato` | `mundo/outposts/contrato.gd` | recurso, quantidade, planeta, evento, pagamento |
| `ModeloDeNave` | `entities/nave/modelo_de_nave.gd` | massa em kg, empuxo em g, limites de pouso em m/s e graus |
| `Modulo` | `entities/nave/modulo.gd` | massa e capacidades da peça |
| `RecursoMineral` | `entities/carga/recurso_mineral.gd` | massa e valor do que se coleta |

`Contrato` fica com o outpost de propósito: o conceito diz que um contrato pertence a quem o emitiu, e a pasta repete isso. O mineral é `RecursoMineral`, e não `Recurso`, porque num código em português `Recurso` se confunde com o `Resource` do próprio Godot.

- **IMPORTANT:** um `Resource` é compartilhado por padrão, e um `.tres` **descreve**, ele não guarda estado de partida. O que o jogador acumula — créditos, contratos aceitos, o que está no porão, ponto de coleta esgotado — vive no autoload de campanha e vai para o save. Escrever no `.tres` durante o jogo corrompe o dado de design e o commit seguinte mostra isso.
- Quando uma cena precisa da própria cópia de um `Resource`, use `duplicate()` ou marque `resource_local_to_scene`.
- Quando algo precisa reagir a um dado que mudou, prefira o sinal `changed` do `Resource` a ligar mais um fio manualmente.

## Grupos e camadas de colisão

Grupo serve para achar quem está na cena **agora**. Nunca use grupo como banco de dados: o que precisa sobreviver ao descarregamento da região vive no save.

| Grupo | Quem entra |
|---|---|
| `planetas` | cada corpo na vista de espaço |
| `outposts` | idem, para quem emite contrato |
| `pontos_de_coleta` | o lugar demarcado onde a nave pousa |
| `carga_solta` | o que ficou para trás e persiste |
| `solto` | peça de cenário que flutua de propósito, para `cenario_check` não acusar |

Camada de colisão **sempre** é nomeada em `project.godot` antes de ser usada. Camada sem nome vira número solto na revisão. Hoje existem `terreno`, `naves` e `ponto_de_pouso`. Carga, obstáculo e gatilho de região entram quando o primeiro corpo precisar delas.

Em script, use `set_collision_mask_value(3, true)` em vez de conta de bit. O número fica legível e a intenção não depende de decorar máscara.

## Escala e unidades

O jogo mede em metro, segundo, quilo e grau. `utilities/escala.gd` guarda as duas constantes que fecham a conta:

| | |
|---|---|
| `PIXELS_POR_METRO` | 5, então a nave tem 5,8 m e a tela é uma área de pouso de 128 por 72 metros |
| `G_TERRA` | 9,80665 m/s² |

A ficha de Arvo diz `gravidade = 9.80665`, e é a região que converte para pixel ao aplicar. O empuxo da nave é declarado em g, não em Newton, porque é isso que um projetista de módulo de pouso olha: abaixo de 1 g a nave não sai do chão da Terra, entre 2 e 3 o pouso perdoa erro. Como a força vira `massa × aceleração`, aceitar carga derruba o empuxo em g sozinho, sem ninguém recalcular nada.

`tools/voo_check.tscn` mede a gravidade em queda livre e compara com a ficha. É a prova de que o número não é decorativo.

## Estado global

Comece com **um** autoload: `campanha_manager.gd`, dono dos créditos, dos contratos aceitos e do que o mundo lembra, e responsável por salvar e carregar. Separar a persistência num segundo autoload é fácil depois, quando a costura doer. Antes disso é costura inventada.

`depuracao_manager.gd` entra quando o primeiro `print` virar permanente: sinalizadores por assunto, mais um rótulo em tela ligado por tecla, em vez de `print` espalhado que ninguém tira depois.

O save vive em `user://`, nunca em `res://`. Escrita em `res://` funciona no editor e falha no build exportado.

A troca de vista **não** é autoload. Ela é trabalho do script da cena `sistema`, e só existe enquanto ela roda. Autoload é para o que atravessa o jogo inteiro, não para o que ficou global por preguiça.

## Composição e herança

- **Módulo é dado, não nó.** A nave é um corpo só. Os três modelos são a mesma `nave.tscn` lendo `.tres` diferentes, inclusive a forma de colisão.
- **Nó separado só quando a peça tem comportamento por quadro e é reusada.** Estabilização angular e contato das pernas são os candidatos reais. O resto é função.
- **Nunca instancie um nó para chamar uma função e morrer.** Isso é uma função.
- **Sinal para cima e para os lados, chamada de função para baixo.** Quando algo distante precisa reagir a algo que não é da conta dele, sinal.
- **Script que precisa de `#region` para ser navegável quase sempre são dois scripts.** Separe simulação de apresentação antes de dobrar o arquivo.

## Convenções de nomenclatura

- `snake_case` para arquivos e pastas; `PascalCase` para `class_name`.
- Sufixo consistente indicando a classe base estendida (ex.: `_modulo.gd` para tudo que `extends Modulo`).
- Sufixo `_manager.gd` exclusivamente para autoloads.
- Cena e script do mesmo objeto sempre no mesmo diretório, mesmo nome base.
- Cena de lugar leva o nome do lugar como prefixo: `<nome>_corpo.tscn`, `<nome>_regiao.tscn`.
- **IMPORTANT:** mover arquivo **sempre** pelo dock de arquivos do editor, nunca por `mv` ou pelo Finder. O Godot referencia por UID e conserta os caminhos sozinho quando o movimento passa por ele. O `.uid` de um script e o `.import` de uma imagem andam junto com o arquivo.

## Padrão de commit

Formato: `tipo(escopo): assunto`

- **Assunto** em português, verbo no presente (`adiciona`, `corrige`, `move`), minúsculo, sem ponto final, até 72 caracteres.
- **Escopo** = a pasta de topo afetada: `entities`, `mundo`, `ui`, `utilities`, `assets`, `common`, `localization`, `tools`. Use `meta` para o que é do repositório e não do jogo (`CLAUDE.md`, `.gitignore`, `project.godot`). Nunca invente escopo fora dessa lista. Omita quando o commit atravessa tudo, e no tipo `docs`, que já implica a pasta.
- **Tipos:**

| Tipo | Quando |
|---|---|
| `feat` | mecânica ou sistema novo |
| `content` | conteúdo novo usando sistema que já existe (planeta, entidade, módulo, arte) |
| `fix` | correção de bug |
| `refactor` | reorganiza sem mudar comportamento — inclui mover ou renomear pasta |
| `perf` | performance |
| `docs` | `CLAUDE.md` ou `docs/` |
| `chore` | project settings, `.gitignore`, ferramentas, dependências |

- **Corpo** (opcional, linha em branco antes, quebra em 72 colunas): explica o *porquê*. O diff já mostra o *o quê* — não descreva arquivo por arquivo.

Exemplos:

```
content(mundo): adiciona o planeta ferrum
feat(utilities): adiciona campanha_manager com save e load
refactor(mundo): move o campo de estrelas para mundo/art
docs: documenta a estrutura de lugar
```

### Regras para o Claude

- **IMPORTANT:** não commite nem faça push sem o usuário pedir explicitamente.
- Um commit = uma mudança lógica. Se o assunto precisa de "e", provavelmente são dois commits.
- Mudança de estrutura anda junto com a documentação dela: criou pasta de topo ou autoload, este arquivo e o `CLAUDE.md` local entram no **mesmo** commit.
- Cena e script do mesmo objeto sempre no mesmo commit — `.tscn` sem o `.gd` que ele referencia quebra o projeto de quem der pull. Vale também para o `.import` e o `.uid` de um arquivo novo.
- Nunca commitar `.godot/`, `.DS_Store` nem arquivo de export com credencial.

## Instruções específicas para o Claude Code (economia de contexto)

- **IMPORTANT:** não faça varredura ampla do projeto antes de começar uma tarefa. Use o mapa e a tabela acima para ir direto na pasta certa, e deixe o `CLAUDE.md` local dela carregar os detalhes.
- Para entender uma entidade ou um lugar, leia só a pasta dele: script, cena e dados. Não leia a pasta-mãe inteira.
- Antes de assumir a API de um autoload, confira a tabela em `utilities/CLAUDE.md`. Só abra o arquivo se precisar de um detalhe que a tabela não cobre.
- Ao criar pasta de topo ou autoload novo, atualize este arquivo e o `CLAUDE.md` local no mesmo commit.
- Quando o mapa acima e o disco discordarem, o disco tem razão. Corrija o mapa.

## Manutenção

- Versione este arquivo e os `CLAUDE.md` locais no git.
- Rode `/init` depois que as primeiras pastas existirem de verdade, para revisar este arquivo contra a estrutura real.
- Revise a cada 3–6 meses ou após mudança grande de conceito.
