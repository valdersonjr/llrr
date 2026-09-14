# Exemplos de pedidos

## Pedidos que viram um sprite

| Pedido | O que sai |
|---|---|
| "Tile de topo de terreno com grama para Arvo, 16x16" | `art/fonte/arvo_grama_topo.pix`, tipo `tile`, encaixe esquerda/direita/baixo |
| "Duas variações do tile de terra cheia de Arvo" | `arvo_terra_a.pix` e `arvo_terra_b.pix`, 16x16, bordas iguais, miolo diferente |
| "Canto externo esquerdo do terreno de Arvo" | `arvo_grama_canto_esquerdo.pix`, 16x16, encaixe direita/baixo |
| "Um arbusto para decorar o chão de Arvo" | `art/fonte/arvo_arbusto.pix`, tipo `decoracao`, base plana |
| "Pedra média do Outpost, rampa de terras" | `art/fonte/pedra_media.pix`, ~16x12 |
| "Personagem: mecânico da nave, parado, de perfil" | `art/fonte/mecanico_parado.pix`, 16x24, luz cima_esquerda |
| "Caixa de carga que a nave embarca" | `art/fonte/caixa_de_carga.pix`, 16x16 |
| "Ícone de minério de cobre para o HUD" | `art/fonte/icone_cobre.pix`, 12x12, lê a 1x |
| "Faísca de contato do trem de pouso, 3 quadros" | `faisca_0.pix`…`faisca_2.pix`, 8x8 cada; folha só se pedir |
| "Baliza luminosa do ponto de coleta" | `art/fonte/baliza.pix`, 8x24, luz `emissivo` na lâmpada |

## Pedidos grandes demais: decompor em peças

**"Uma árvore enorme de 128 px de altura"**

> O limite é 64x64 por sprite, então a árvore vira partes que se empilham:
> | Peça | Tamanho | Encaixe |
> |---|---|---|
> | `arvo_arvore_copa` | 64x48 | baixo |
> | `arvo_arvore_tronco` | 16x48 | cima, baixo |
> | `arvo_arvore_raiz` | 32x16 | cima |

**"Uma casa"**

> Parede (16x16, repete em todas as bordas), porta (16x24), janela (12x12), telhado (borda 16x16 que repete na horizontal, mais os dois cantos), chaminé (8x16).

**"A nave-mãe do outpost"**

> Módulos de 32x32 ou 48x48 com `encaixe` nas bordas que se conectam: casco central, anel de doca, antena, painel solar, luzes de sinalização (8x8, emissivo).

## Pedidos de cena: recusar a cena, entregar as peças

**"Desenha uma floresta com a nave pousando"**

> A skill produz só sprites isolados, não a cena montada. O bosque vira:
> topo com grama, terra cheia (2 variações), cantos externo e interno, arbusto, tufo de grama, pedra, copa e tronco de árvore. A nave é sprite à parte e a cena se monta no Godot.
> Começo pelo topo com grama e pelo arbusto, para você aprovar o estilo?

**"Faz a tela de título"**

> Tela é composição. Posso fazer as peças dela: letras ou logotipo em partes de até 64x64, moldura de botão em 9 fatias (cantos 8x8, bordas 8x8 repetíveis), ícones.

**"Um background de céu estrelado 640x360"**

> Fundo inteiro não é sprite. Posso fazer tiles de céu de 32x32 ou 64x64 que se repetem sem emenda, e estrelas soltas (1x1 a 5x5) para espalhar numa camada.

## Pedidos bem escritos (modelo)

Quanto mais o pedido tiver disto, menos voltas:

```
Peça: tronco de árvore de Arvo
Tipo: cenario
Tamanho: 16x32
Encaixe: cima (a copa encaixa em cima), baixo apoia no chão
Luz: cima_esquerda
Rampas: neutros_quentes para a casca, verdes acinzentados para musgo
Função: fica atrás da nave, camada de cenário, sem colisão
```

```
Peça: personagem do mecânico, andando, quadro 1 de 4
Tipo: personagem
Tamanho: 16x24
Luz: cima_esquerda
Referência: mesma paleta e contorno de sprites/personagens/mecanico_parado.pix
```
