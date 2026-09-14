# mundo/

Os lugares. O que fica **dentro** de um lugar mora em `entities/`.

## A cena que roda o jogo

`sistema/sistema.tscn` é a raiz: nave, câmera, estrelas, os corpos do sistema, a interface e o nó `LugarAtual`. A região de um lugar entra e sai como filha de `LugarAtual`, e a nave é criada uma vez e nunca recriada.

**IMPORTANT:** nunca use `change_scene_to_file()` para entrar ou sair de um lugar. O porquê está na seção "Os lugares" do `CLAUDE.md` da raiz.

## As três vistas

Um lugar tem duas formas: `<nome>_corpo.tscn`, como ele se vê de longe, e a cena de cada região, a superfície. `corpo_no_espaco.gd` é a classe base da primeira, como `regiao.gd` é da segunda. A diferença entre as duas é que **o corpo conhece a ficha do planeta** e a região não: o corpo é colocado à mão no sistema e precisa dizer que lugar é aquele, enquanto a região tem que continuar abrindo sozinha por `--scene`.

| Vista | A nave | O que se vê |
|---|---|---|
| `ESPACO` | voando, solta | o sistema, com os corpos e as estrelas |
| `ORBITA` | parada e guardada | a tela de regiões do corpo, sem nave |
| `SUPERFICIE` | voando, solta | a região escolhida, com a câmera perto |

`CHEGANDO` é o intervalo entre as duas últimas: o terreno já está na cena e a nave vai por piloto automático até o ponto que a ficha da região definiu. O jogador não comanda nada nesse trecho.

**Entrar não é atravessar.** Chegar perto de um corpo acende o destaque e o convite; a tecla para a nave onde ela está e abre a tela de regiões. Sair é o contrário: ganhar altitude devolve a tela de regiões do mesmo corpo, e fechar a tela devolve a nave ao espaço, parada exatamente onde ela ficou.

**Onde a nave aparece é escolha, não trajetória.** É a diferença entre esta versão e a anterior, que entrava descendo sobre o corpo sem nada ser recolocado. Aquilo dava inércia contínua e tirava do projetista o controle de onde a nave chega, que é o que um lugar desenhado à mão precisa ter. `tools/orbita_check.tscn` guarda a promessa nova: a chegada termina no ponto da ficha, e termina parada.

**O espaço é finito e dá a volta nos quatro lados.** Sair por cima é entrar por baixo, sair pela direita é entrar pela esquerda. O conceito pede um sistema finito, e fechar o espaço em vez de cercá-lo evita tanto a parede invisível quanto a deriva infinita. O tamanho é o `Rect2` exportado em `sistema.tscn`, e é calibração: hoje cabem umas três telas de espaço em cada direção, e ele cresce quando entrarem mais corpos. **Cruzar a borda não é um evento, e não deve parecer um.** O movimento não muda, a câmera pula junto sem deslizar e sem ler o salto como aceleração, e o campo de estrelas fecha porque o tamanho do sistema é múltiplo do mosaico dele. Quem atravessa só descobre olhando o mapa. Medido: o mesmo ponto do espaço, alcançado direto e atravessando a borda, dá o mesmo quadro.

**Dentro de uma região, os lados dão a volta.** Sair pela esquerda é entrar pela direita, sem tocar em velocidade, ângulo nem giro: a região é uma tela, não há mapa ao lado para onde ir, e sumir pela borda seria pior. Para baixo está o chão, e para cima está a tela de regiões.

## O lugar de hoje

Só Arvo existe, com uma região, o Outpost. Vesk, Elde, Oren e o Bosque foram apagados em 2026-09-14, e lugar novo nasce com a receita de cenário da skill `pixel-art-sprite` (`reference/receita-de-cenario.md`).

| | Arvo |
|---|---|
| gravidade | 9,81 m/s² |
| ar | denso, 0,25 |
| regiões | Outpost |
| o que atrapalha | o deque estreito entre os postes |

Em Arvo o ar freia por você e o erro se corrige.

A seção 17 do conceito avisa do risco de planetas intercambiáveis, e a regra contra isso continua valendo para o próximo: diferenciar por **gravidade e relevo**, não só por cor. **A grade de tile pode mudar de lugar para lugar**; o que precisa ser igual é a densidade de pixel.

## Um lugar é uma pasta

```
mundo/planetas/arvo/
├── art/                        # arte do corpo, e o que mais de uma região usar
├── arvo.tres                   # a ficha: gravidade, recurso, e a lista de regiões
├── arvo_corpo.tscn             # como ele se vê na vista de espaço
└── regioes/outpost/            # uma pasta por superfície
    ├── art/                    # arte só desta região, com a fonte .pix em art/fonte/
    ├── sound/                  # som só desta região
    ├── outpost.tres            # nome, cena e onde a nave aparece
    ├── outpost_tileset.tres    # os tiles do chão, com colisão
    └── outpost_regiao.tscn     # o terreno, onde se pousa
```

O nome do lugar prefixa as cenas. `regiao.tscn` repetido em oito pastas é inútil na busca rápida do editor.

## O contrato da região

`regiao.gd` é a classe base de toda superfície, inclusive a do outpost, que é uma região como as outras. Uma região **não conhece a nave e não conhece a ficha do planeta**. Quem entra num lugar é que aplica as condições dele, chamando `aplicar(planeta)`. Isso mantém duas coisas:

- a região abre sozinha por `--scene`, que é como se testa um pouso sem voar até lá;
- a ficha e a cena não apontam uma para a outra, o que evitaria carregamento circular.

A gravidade chega por uma `Area2D` que substitui a do projeto na área da região. A ficha declara em metros por segundo ao quadrado, e a região converte para pixel com `Escala`. Arvo roda com gravidade de Terra, 9,81, e arrasto de ar de 0,25. O padrão do projeto é o espaço: gravidade zero e amortecimento zero. Um planeta repõe a gravidade localmente, e sair dela é voltar ao vácuo sem escrever uma linha.

## Uma região é uma tela, e a câmera quase não anda

Decisão da primeira versão, não do conceito: a região inteira cabe em 640 por 360, que é a tela base escalada 2x para 720p. Isso garante de graça a promessa da seção 6 de que a nave nunca some da tela, e é o Lunar Lander original.

Na superfície a câmera segue a nave dentro de `limites_da_camera()`, que numa região de uma tela é quase uma linha: ela fica estacionada no terreno e sobe só a margem de saída, para a nave não sumir enquanto ganha altitude para voltar à tela de regiões. Para baixo e para os lados não há folga nenhuma, porque fora da região é o vazio, e mostrar o vazio ao lado do terreno denunciaria que o lugar é um retângulo.

No espaço a câmera segue a nave livre e afastada. A troca entre os dois enquadramentos acontece atrás da tela de regiões, então ela é instantânea: ninguém vê o instante, e não há transição para suavizar.

## O relevo é pintado na cena

O terreno é um `TileMapLayer` pintado direto na cena da região, com o tileset dela. Colisão vem do tileset, declarada tile a tile, e a linha de colisão é a borda de cima do tile de topo: a nave assenta onde o chão é desenhado.

## A luz é do planeta, não da cena

A ficha traz `cor_ambiente` e `cor_do_ceu`, e `aplicar()` empurra as duas para a região: a primeira num `CanvasModulate`, a segunda no polígono de céu. A exceção é a região com `luz_propria`, que usa as cores declaradas nela: hoje só o Outpost, que é trabalho humano e pode destoar do planeta. O céu é desenhado dentro da cena de propósito, e não é a cor de fundo da janela. Céu que não escurece junto com o resto denuncia na hora que a luz é falsa.

Em cima desse ambiente vêm os emissivos, que é o que a seção 14 do conceito pede. Hoje são dois: os sinais do deque do Outpost e a chama do motor. Todos usam a mesma máscara em `assets/luz_redonda.png`, e quem dá caráter é cor e energia no nó.

A luz do lugar de pouso mora no `sinal_de_pouso`, que escuta o `ponto_de_coleta`. A seção 10 exige que o lugar demarcado se separe do terreno pela silhueta **e** pela luz, então demarcação sem luz própria seria demarcação quebrada.

## Profundidade: vários planos, não dois

O Outpost desenha em várias distâncias, e é isso que tira a cena da aparência de parede plana. O detalhe de cada plano está na receita de cenário da skill.

| Plano | z | O que tem |
|---|---|---|
| Fundo | −10 | céu em faixas, nuvens, montanhas longe e meio, a mesa de rocha próxima |
| Cenário | −6 | saloon e cactos |
| Jogo | −3 a 1 | relevo, deque, personagens, ponto de coleta, nave |

Nada fica na frente da rota de pouso. A seção 16 do conceito manda cortar efeito visual que atrapalhe a leitura.

## O desenho de um corpo

`arvo_corpo.png` tem 640 pixels, a mesma largura de uma região, e é a partir dele que o raio do corpo é lido. A paleta saiu da arte de superfície do próprio planeta: oliva da copa nos continentes, teal da neblina nos mares, e o ciano da ficha no ar. Quatro bandas de luz com dither só na emenda entre elas, para ser rampa de pixel art e não gradiente liso.

Um corpo novo é um PNG quadrado com fundo transparente. Se ele for maior, o planeta fica maior e a fronteira acompanha sozinha, porque ela é medida em região, não em corpo.

## Arte de lugar novo

Arte nova sai da skill `pixel-art-sprite`, na paleta do projeto.

## Para acrescentar uma região a um planeta

1. `mundo/planetas/<planeta>/regioes/<nome>/` com `art/`, a cena do terreno e a ficha.
2. A ficha diz o nome, o assunto de uma linha, **onde a nave aparece** e de onde ela vem. Esses dois pontos são a chegada inteira: o piloto automático vai de um ao outro.
3. `ponto_no_corpo` põe o marcador dela sobre o disco do planeta, de -1 a 1 nos dois eixos. É só leitura, não existe geografia por trás.
4. A cena precisa de `CampoGravitacional`, do relevo com colisão e de um corpo no grupo `pontos_de_coleta`.
5. Uma linha na lista `regioes` da ficha do planeta, e pronto: a tela de regiões monta o marcador sozinha.

## Outpost é uma região

Um outpost não é um lugar no espaço: é uma região de um planeta, com ficha e cena de região como qualquer outra, e entra na lista `regioes` da ficha do planeta. O que o separa das regiões de coleta é quem está lá e o que se faz ali: é onde se pega e entrega contrato.

O primeiro é o de Arvo, em `regioes/outpost/`: um posto de fronteira de faroeste, com areia, mesas de rocha, cactos, céu de meio-dia e um deque de pouso sobre palafitas com sinal que pisca vermelho e amarelo e fica verde no pouso. A ficha é `outpost.tres` e a cena é `outpost_regiao.tscn`.

- **O chão é pintado direto no `TileMapLayer`**, com `outpost_tileset.tres`.
- **A luz é própria** (`luz_propria` na raiz da região): ambiente branco e céu azul da Resurrect 64. A luz azulada de Arvo tingiria o deserto inteiro.
- **O som é da região**, no nó `Som`: `Entrada` toca `sound/entrada.mp3` uma vez ao chegar, e o `finished` dela, ligado na própria cena, dá `play` em `Musica`, que toca `sound/musica.mp3` em laço. O laço está no importador do mp3, não em código. Sair da região descarta a cena (`_esvaziar_lugar` no sistema), então a música para junto, sem ninguém precisar desligar.

- A arte do lugar mora em `regioes/outpost/art/`, e a fonte dela em `art/fonte/`.
- O saloon é construção parada: `entities/estruturas/saloon/`.
- Xerife, dono do saloon, cowboy e o arbusto seco rolando são cenário: `entities/cenario/<nome>/`.
- O deque é a demarcação do lugar: a instância de `ponto_de_coleta` fica sobre ele, e os dois `sinal_de_pouso` escutam o estado dela.

## Para acrescentar um planeta

1. `mundo/planetas/<nome>/` com `art/`, a ficha, a cena do corpo e pelo menos uma região.
2. A cena do corpo carrega só o desenho e a ficha, e entra no grupo `planetas`. O tamanho do corpo sai da própria arte, e o alcance do convite de entrada acompanha.
3. O corpo entra em `Corpos`, na cena do sistema, na posição que ele ocupa no espaço.
4. Nada de lista de biomas. O planeta só precisa provar que pousar nele não é igual a pousar nos outros.

Um tileset por planeta, com a colisão declarada tile a tile. A grade nunca decide se um pouso valeu: isso é do corpo no grupo `pontos_de_coleta`, que tem colisão própria e é sempre uma entidade, nunca um tile.
