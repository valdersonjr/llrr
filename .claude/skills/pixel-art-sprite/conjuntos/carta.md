# Conjunto: carta

A carta de superfície de um planeta, vista de cima, na tela de regiões. É interface: o jogador lê onde fica cada região e escolhe uma. A carta de Arvo é a primeira: mata alta sobre platôs partidos, mar escuro e o deserto do Outpost.

```
luz: cima_esquerda
rampas: teais, azuis, verdes, verdes_acinzentados, terras, olivas, neutros_quentes, neutros_frios, vermelho_laranja, roxos
valor.terreno: 20-65
valor.interface: 5-95
```

## Materiais

| Material | Tons |
|---|---|
| Mar | fundo `teais:0`; marolas em til de 1 px em `teais:1`; brilho raro em `teais:2` |
| Mar raso, junto da costa | `teais:1`, espuma quebrada em `teais:3` |
| Mata baixa | copas redondas de 5 a 7 px: luz `verdes:2`, corpo `verdes:1`, vão e sombra `verdes:0`, realce de 1 px em `verdes:3` |
| Mata sobre platô | as mesmas copas um degrau acima: `verdes:3`, `verdes:2`, vão `verdes:1`, realce `verdes:4` |
| Penhasco do platô | face em `verdes_acinzentados:1` e `:0` no lado de sombra (baixo e direita); aresta de luz em `verdes_acinzentados:3` |
| Deserto | `terras:2` e `terras:3`, traços em S e C em `terras:1`, crista em `terras:4` só em pontos |
| Moldura e painel | corpo `neutros_quentes:1`, chanfro `neutros_quentes:2` e `:0`, rebite `neutros_frios:2` |
| Marcador de região | losango vazado em `vermelho_laranja:1` (luz) e `vermelho_laranja:0` (sombra), brilho `neutros_frios:4`, contorno `neutros_quentes:0`; vermelho porque amarelo some na areia |
| Grade e letras | pontilhado e letras em `neutros_frios:3` |

## Contorno e granulação

Sem contorno no terreno: a costa e o penhasco se separam por valor. Clusters de 2 a 4 px; a marola do mar é linha de 1 px, é o material. O marcador e a moldura levam contorno `neutros_quentes:0`, porque são interface por cima da carta.

## Tiles

16x16, sem costura nos quatro lados. A costa segue o esquema de dois cantos: cada canto do tile é terra ou mar, e a linha da costa cruza a borda sempre no mesmo ponto, então qualquer vizinho encaixa. Sombra do penhasco e da costa cai para baixo e para a direita, no máximo 2 px.

## Camadas e atlas

A carta empilha três `TileMapLayer`, e por isso platô e deserto não precisam de tile para cada combinação com o mar:

| Pasta em `art/fonte/` | PNG | O que é |
|---|---|---|
| `carta/` | `carta.png` | base: 0 mar, 15 mata, 1 a 14 costa |
| `deserto/` | `deserto.png` | camada sobre a mata, transparente fora da areia; 15 é a textura desenhada à mão |
| `plato/` | `plato.png` | camada sobre a mata; o topo é a copa da mata um degrau acima e o penhasco cai para baixo e para a direita |

O número do arquivo é a combinação de cantos: TL 1, TR 2, BL 4, BR 8. Na base ele é a posição no atlas; nas camadas, a posição é o número menos 1. Deserto e platô não encostam no mar nem um no outro dentro do mesmo tile.

As texturas (mar, mata, areia) são desenhadas à mão; as bordas saem de um rascunho por script que recorta a textura por uma máscara de cantos e depois é revisado. Os scripts estão em `reference/modelos/` (`carta_costa.py`, `carta_camadas.py`), junto com o que monta a cena (`montar_carta_arvo.gd`).

## Carta

A carta de Arvo tem 22x12 tiles (352x192 px na tela base), na cena `mundo/planetas/arvo/arvo_carta.tscn` com as três camadas; a ficha do planeta aponta para ela e a tela de regiões a põe na moldura. Depois de montada, ela se edita no editor de TileMap do Godot, pintando com os terrenos do tileset. A grade de coordenadas divide a carta a cada 32 px: letras nas colunas, números nas linhas, e uma região se lê como "H4".
