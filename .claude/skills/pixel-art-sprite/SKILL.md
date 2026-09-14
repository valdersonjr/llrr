---
name: pixel-art-sprite
description: Cria sprites de pixel art profissionais e isolados, no máximo 64x64, na paleta Resurrect 64, para compor depois no jogo llrr (vista lateral 2D). Use sempre que o pedido envolver sprite, pixel art, tile, bloco de terreno, personagem, objeto, item, planta, pedra, decoração, efeito, ícone ou peça de interface. Nunca produz cena, tela, mapa ou ilustração composta; pedidos assim são decompostos em peças.
---

# Pixel art em sprites isolados

Você é um artista de pixel art de produção. Cada entrega é **uma peça**, desenhada pixel a pixel, que alguém vai combinar depois com outras peças. Não é ilustração, não é cena, não é mapa.

Tentativas anteriores neste repositório falharam de dois jeitos, e as duas lições estão embutidas no fluxo:

1. **Gerado por fórmula** (terra chapada, grama em faixa): não gere pixels por algoritmo. Um rascunho de volume por script é permitido como guia, mas o `.pix` final é desenhado e retocado à mão.
2. **Bom sozinho, ruim junto** (peça ampliada parecia ok, ao lado das outras não): toda peça passa pela **prévia de contexto** e pela **revisão de 9 pontos** antes de ser entregue.

## Restrições absolutas

1. Máximo **64x64**. Dimensões inteiras. Não existe exceção, nem a pedido.
2. Um sprite por arquivo. Folha de sprites só se o usuário pedir explicitamente, e cada quadro continua até 64x64.
3. Nunca cena, tela, fase, mapa montado, paisagem ou composição final.
4. Nada que não foi pedido: sem chão embaixo do personagem, sem céu atrás da árvore, sem sombra projetada solta.
5. Toda cor sai da Resurrect 64 (`scripts/paleta.py` desta skill, a mesma lista de `docs/paleta.md`). Preto é `#2e222f`, nunca `#000000`.
6. Pixel definido: sem antialiasing automático, sem blur, alfa só 0 ou 255.

O script `scripts/sprite.py` bloqueia 1, 2, 3, 5 e 6 mecanicamente (ver "A trava"). A 4 e a qualidade são responsabilidade sua.

## Portão de entrada: o pedido é um sprite?

| Se o pedido é... | Faça |
|---|---|
| Uma peça que cabe em 64x64 | siga o fluxo |
| Uma peça maior que 64x64 (árvore grande, nave-mãe, prédio) | divida em partes que se encaixam (copa, tronco, raiz), cada uma ≤64, com `encaixe:` declarado |
| Uma cena, tela, fase, mapa, "o bosque", "a cidade" | **não desenhe a cena.** Diga que a skill só produz sprites modulares, mostre a tabela de peças e pergunte por qual começar, ou comece pelas 2–3 peças que definem o estilo |
| Algo ambíguo em tamanho ou função | escolha pela tabela de escala e diga o que escolheu |

Exemplos de decomposição em `reference/exemplos.md`.

## Contexto do jogo (llrr)

- **Vista lateral 2D**, jogo de pouso inspirado em Lunar Lander. Pixel art moderna, luz declarada, sem CRT (`docs/conceito-de-jogo.md`, seção 14).
- **Tela base 640x360**, escala inteira 2x, filtro nearest. **Tile 16x16.** 5 px = 1 metro: a nave tem ~29 px de altura.
- **Paleta**: Resurrect 64 em rampas (`scripts/paleta.py`, `docs/paleta.md`). Identidade de lugar é escolha de rampas: Outpost = terras + neutros quentes + azuis no céu. Lugar novo declara as rampas no conjunto dele.
- **Num jogo de pouso, a linha de colisão é sagrada.** O jogador precisa ver onde a nave encosta. Nada ambíguo acima da borda do terreno.
- **Não mexa na arte existente sem pedido.** Arte de pacote de terceiros fica como está; peça nova nasce com a fonte `.pix` em `art/fonte/`.

## Escala

| Peça | Tamanho típico | Nota |
|---|---|---|
| Tile de terreno | 16x16 | a borda de cima é a colisão |
| Borda de terreno com vegetação alta | 16x32 com `acima: 16` | só grama fina acima da célula, mais escura que a borda |
| Peça de terreno maior (penhasco, plataforma) | 32x16, 32x32, 48x16 | múltiplos de 16 |
| Personagem humanoide | 16x24 a 24x32 | estilizado; declare a escolha |
| Nave / veículo | 32x32, até 64x48 | nariz para cima em repouso |
| Criatura pequena | 8x8 a 16x16 | |
| Árvore, estrutura | até 64x64, ou partes | acima disso, partes com `encaixe` |
| Arbusto | 24x16 a 32x24 | menor que isso lê como tufo |
| Pedra, flor, tufo | 6x4 a 16x12 | |
| Item, objeto de mão | 8x8, 12x12, 16x16 | |
| Ícone de interface | 8x8, 12x12, 16x16 | lê a 1x |
| Efeito (faísca, fumaça, chama) | 8x8 a 32x32 | um quadro por `.pix` |

## Conjuntos

Peças que vão aparecer juntas pertencem a um **conjunto**, declarado em `conjuntos/<nome>.md` desta skill (ex.: `faroeste.md`). O arquivo fixa o que torna as peças coesas:

- luz e rampas permitidas (`rampas:` é conferido pelo script);
- **faixa de valor por camada** (`valor.terreno: 22-42` etc.), sem sobreposição, conferida pelo script pela luminância média;
- regra de contorno, igual para todas as camadas;
- granulação do detalhe;
- material → tons.

Antes de desenhar a primeira peça de um lugar novo, crie o arquivo do conjunto e mostre ao usuário. Antes de desenhar qualquer peça de um conjunto existente, leia o arquivo e abra o `.pix` de uma peça já feita.

## Fluxo

1. **Classifique** no portão de entrada: tipo, camada, função na composição, tamanho.
2. **Conjunto e referências:** leia `conjuntos/<conjunto>.md` e um `.pix` do mesmo conjunto.
3. **Planeje por escrito, em 5 linhas, antes do primeiro pixel:** silhueta (formas primárias e variação de tamanho entre elas), materiais e tons, luz, faixa de valor da camada, bordas de encaixe e linha de colisão.
4. **Desenhe o `.pix`** em `<pasta>/art/fonte/<nome>.pix` (ver "Onde salvar"), em passes:
   silhueta → 3 valores por massa → oclusão nos contatos → contorno conforme o conjunto → realce e detalhe → limpeza.
   Para formas orgânicas grandes, um rascunho de volume por script no scratchpad pode guiar o passo 2; o resultado é retocado à mão (bordas recortadas, variação, clusters).
5. **Construa com inspeção:**
   ```
   python3 .claude/skills/pixel-art-sprite/scripts/sprite.py construir <pasta>/art/fonte/<nome>.pix \
       --inspecao <SCRATCHPAD>/<nome>_inspecao.png [--repeticao <SCRATCHPAD>/<nome>_repeticao.png]
   ```
6. **Prévia de contexto** com as outras peças do conjunto:
   ```
   python3 .claude/skills/pixel-art-sprite/scripts/sprite.py contexto \
       --terreno mundo/planetas/arvo/regioes/outpost/art/fonte/tiles/areia_topo_a.pix mundo/planetas/arvo/regioes/outpost/art/fonte/tiles/areia_topo_b.pix \
       --preenchimento mundo/planetas/arvo/regioes/outpost/art/fonte/tiles/areia_a.pix \
       --pecas mundo/planetas/arvo/regioes/outpost/art/fonte/cacto_saguaro_a.pix \
       --saida <SCRATCHPAD>/outpost_contexto.png
   ```
   Sai a 2x, com um retângulo do tamanho da nave, e embaixo a mesma faixa em cinza. É revisão, nunca entrega: o script recusa salvar dentro do projeto.
7. **Revisão de 9 pontos** (abaixo), olhando a inspeção **e** o contexto com Read. Escreva a tabela.
8. **Corrija e repita** até nenhum ponto estar em "refazer". Duas a quatro voltas é o normal. Todo `aviso:` do script é resolvido ou justificado.
9. **Entregue** (ver "Entrega"). Abra a inspeção e o contexto para o usuário com `open` quando for a primeira peça de um conjunto ou quando ele pedir para ver.

## Revisão de 9 pontos

Obrigatória. Nota por ponto: **ok**, **ajustar** ou **refazer**, com uma frase de motivo. Sempre nesta ordem, porque os primeiros invalidam os últimos.

| # | Ponto | Pergunta | Onde olhar |
|---|---|---|---|
| 1 | Tamanho real | A 2x, ao lado da nave, a peça lê e tem a escala certa? | contexto |
| 2 | Silhueta e forma | A forma tem caráter? Há variação de tamanho entre as massas? Algo regular demais (serrilhado, pente, bolha)? | inspeção: silhueta |
| 3 | Valores | Em cinza, a luz e o volume aparecem? A peça fica na faixa da camada dela e se separa das outras camadas? | inspeção: valores; contexto: cinza |
| 4 | Hierarquia de contraste | O ponto de maior contraste está onde o olho deve ir? Nenhuma linha clara contínua puxando atenção à toa? | contexto |
| 5 | Material | Dá para dizer do que é feito (folha, terra, pedra, metal) sem a cor? | inspeção ampliada |
| 6 | Coesão | Mesma regra de contorno, mesma granulação, mesmas rampas das outras peças do conjunto? A peça assenta (oclusão de contato) ou flutua? | contexto |
| 7 | Repetição | Repetida, a peça vira padrão visível? Precisa de variação? | repetição; contexto |
| 8 | Função no jogo | A linha de colisão está inequívoca? Nada disputa leitura com o lugar de pouso? | contexto |
| 9 | Limpeza | Órfãos, jaggies, banding, pillow shading, dither sem motivo? | inspeção ampliada; avisos |

## O formato `.pix`

```
nome: arvo_arbusto
tipo: decoracao
camada: cenario
conjunto: arvo
tamanho: 24x16
luz: cima_esquerda
encaixe: nenhum
afunda: 1
uso: arbusto solto sobre qualquer topo de grama de Arvo; a base afunda 1 px na grama

paleta:
  . transparente
  T teais:0           folha, sombra funda
  g verdes:2          folha, base
  L verdes:4          folha, realce

pixels:
(uma linha de caracteres por linha de pixels)
```

| Campo | Obrigatório | Significado |
|---|---|---|
| `nome` | sim | igual ao nome do arquivo, `snake_case`; sem prefixo de lugar, a pasta já diz o lugar |
| `tipo` | sim | `personagem`, `parte_de_personagem`, `objeto`, `item`, `tile`, `terreno`, `cenario`, `decoracao`, `efeito`, `icone`, `interface` |
| `tamanho` | sim | `LxA`, conferido contra o desenho |
| `uso` | sim | uma frase de como a peça se combina |
| `camada` | em conjunto | `terreno`, `cenario`, `pouso`, `personagem`, `objeto`, `efeito`, `interface` |
| `conjunto` | recomendado | nome do arquivo em `conjuntos/` desta skill |
| `luz` | não | padrão `cima_esquerda` |
| `encaixe` | não | bordas que encostam em outra peça; tile sem ele assume `esquerda,direita` |
| `superficie` | não | borda onde algo pousa ou pisa (ex.: `cima` num deque); pode ser opaca sem encaixe. Não use para escapar da trava |
| `acima` | não | linhas no topo que ficam acima da célula da grade (borda com vegetação alta) |
| `afunda` | não | pixels que a base entra no chão na prévia de contexto |

Cor: `rampa:indice` (0 = mais escuro, nomes em `paleta.py`), `#rrggbb` da paleta, ou `transparente`. `.` é transparente por convenção. Exemplos completos em `mundo/planetas/arvo/regioes/outpost/art/fonte/` e `entities/cenario/xerife/art/fonte/`.

## Cenário inteiro

Para desenhar um lugar novo inteiro (um mapa, uma região), siga `reference/receita-de-cenario.md`: o processo, a ordem das peças, a técnica de cada material e a montagem no Godot que fizeram o Outpost de Arvo. Os scripts que montaram aquela região estão em `reference/modelos/`.

## Regras de ofício

As regras completas, com o porquê, estão em `reference/regras.md`. Leia antes do primeiro sprite de uma sessão. O essencial:

- **Silhueta primeiro**, com variação de tamanho entre as massas (grande, média, pequena).
- **Luz de um lado só**, a mesma no conjunto. Três planos por massa, terminador desenhado com intenção.
- **Oclusão em todo contato**: onde uma massa encosta em outra ou no chão.
- **Rampa com deslocamento de matiz**: sombra troca para rampa fria ou roxa na ponta.
- **Contorno conforme o conjunto**, igual em todas as camadas.
- **Clusters de 2–4 px**; pixel isolado só como realce deliberado.
- **Realce raro.** O tom mais claro é pontual; linha clara contínua vira listra.
- **Linhas limpas**, sem banding, sem pillow shading, dither só com motivo.
- **Poucas cores**: 16x16 até 10; 32x32 até 16; 64x64 até ~24.

## A trava contra imagem completa

1. **Portão de entrada**: pedido de cena vira tabela de peças, não desenho.
2. **Cabeçalho**: `tipo` precisa estar na lista; `nome` e `tipo` com `cena`, `tela`, `mapa`, `fase`, `paisagem`, `ilustracao`, `composicao`, `background`, `scene`, `level` e afins são recusados.
3. **Pixels**: acima de 64 é erro; não-tile com borda inteira opaca sem `encaixe` é erro; retângulo cheio ≥32x32 que não é tile é erro; `folha` exige `--explicita`.
4. **Prévia de contexto**: recusa salvar dentro do projeto e exige o sufixo `_contexto`. Ela nunca é entregue como arte.

Nunca contorne a trava: não renomeie para passar, não declare `encaixe` em borda que não encaixa, não gere PNG por outro caminho, não entregue a prévia de contexto como arte.

## Outros comandos

```
# validar PNGs já existentes
python3 .claude/skills/pixel-art-sprite/scripts/sprite.py validar mundo/planetas/arvo/regioes/outpost/art/tiles.png --tipo tile

# folha de sprites, só com pedido explícito
python3 .claude/skills/pixel-art-sprite/scripts/sprite.py folha \
    entities/cenario/faisca/art/fonte/faisca_0.pix entities/cenario/faisca/art/fonte/faisca_1.pix \
    --saida entities/cenario/faisca/art/fonte/faisca_folha.png --explicita
```

## Onde salvar

A fonte mora ao lado da arte que ela gera, dentro do llrr, seguindo a arquitetura dele (`CLAUDE.md` da raiz, `mundo/CLAUDE.md`, `entities/CLAUDE.md`):

| O que é | Pasta |
|---|---|
| arte que só uma região usa: fundo, chão, cacto, demarcação de pouso | `mundo/planetas/<planeta>/regioes/<região>/art/` |
| construção parada: saloon, casa, torre | `entities/estruturas/<nome>/art/` |
| parece vivo e não faz nada: personagem sem função, bicho, arbusto rolando | `entities/cenario/<nome>/art/` |
| sólido na descida | `entities/obstaculos/<nome>/art/` |

Dentro de cada `art/`:

```
art/
├── fonte/                     # tem .gdignore: o Godot não importa nada daqui
│   ├── <peça>.pix             # vira art/<peça>.png
│   ├── tiles/*.pix            # viram juntos art/tiles.png, uma linha, em ordem alfabética
│   ├── quadros/<anim>_N.pix   # viram a tira art/<entidade>_<anim>.png (hframes = quantidade)
│   └── <anim>/N_<nome>.pix    # vira a tira art/<anim>.png, na ordem do número
└── <peça>.png                 # gerado; é o que a cena usa
```

Nome sem prefixo de lugar: a pasta já diz o lugar. **Animação no llrr é uma tira horizontal lida com `hframes`** (como o arbusto seco), por isso cada quadro é um `.pix` e a tira é montada pelo script. É convenção do projeto, não folha de sprites por conta própria.

```
python3 .claude/skills/pixel-art-sprite/scripts/montar_arte.py           # gera todos os PNG a partir das fontes
python3 .claude/skills/pixel-art-sprite/scripts/montar_arte.py <pasta>   # só o que está abaixo de uma pasta
```

Depois de gerar: `godot --headless --path . --import` e `godot --headless --path . --scene res://tools/paleta_check.tscn`. O PNG que o `construir` deixa ao lado do `.pix` é só conferência e é ignorado pelo git. Inspeção, repetição, contexto e rascunhos ficam no scratchpad, nunca no llrr.

## Entrega

Para cada sprite:

- caminho do `.png` e do `.pix`;
- tamanho, tipo, camada, número de cores e rampas;
- luz, bordas de encaixe, `acima`/`afunda` se houver;
- como combinar: onde apoia, com quais peças encaixa;
- a tabela da revisão de 9 pontos da versão final;
- avisos do script que sobraram, com o motivo.

## Dependências

Só Python 3 com Pillow (o `python3` do sistema já tem) e `scripts/paleta.py` desta skill.
