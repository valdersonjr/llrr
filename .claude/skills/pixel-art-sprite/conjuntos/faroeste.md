# Conjunto: faroeste (outpost)

Outpost de fronteira num deserto seco: areia avermelhada, madeira queimada de sol, lampiões. O pouso é um deque de madeira sobre palafitas; contra a areia clara ele se destaca pela silhueta escura, pelas faixas de aviso e pelos sinais.

```
luz: cima_esquerda
rampas: terras, neutros_quentes, olivas, vermelho_laranja, verdes_acinzentados, vermelhos, verdes, magentas, azuis, neutros_frios, roxos
valor.fundo: 40-90
valor.terreno: 45-80
valor.cenario: 35-60
valor.pouso: 30-60
```

## Materiais

| Material | Tons |
|---|---|
| Areia | `terras:0` a `terras:4`; `terras:4` só em crista de duna |
| Madeira | `terras:0` a `terras:4`, veio e sombra em `terras:0` |
| Galho seco | `neutros_quentes:1` a `:4`, folha morta em `olivas:1` |
| Ferro, corda | `neutros_quentes:1` a `:2` |
| Oclusão | `neutros_quentes:1` |
| Luz de lampião | `vermelho_laranja:3` e `:4`, sempre com `luz: emissivo` na peça ou no comentário |

## Contorno e granulação

Sem contorno preto. Clusters de 2 a 4 px; galho seco pode ter linha de 1 px, é o material.

## Pouso

O deque é modular: ponta esquerda, meio repetível, ponta direita. A tábua de cima é a linha de colisão e o tom mais claro do conjunto. Lampiões marcam as pontas, e por isso o tamanho do pouso se lê de longe.

## Sinal de pouso

`pouso_sinal/` (tira `pouso_sinal.png`, quadros 0 apagado, 1 vermelho, 2 amarelo, 3 verde): quatro quadros do mesmo tamanho. Pisca alternando vermelho e amarelo enquanto a nave desce; fica verde quando o pouso é bom; apagado quando não há pouso em curso. No Godot, cada quadro é um frame de `AnimatedSprite2D`, com uma `PointLight2D` da mesma cor.

## Tela

O mapa é 1280x720 (base 640x360 a 2x) e aparece inteiro, sem rolagem. O fundo é feito de peças únicas posicionadas à mão: nada de mesa repetida lado a lado. Só as nuvens se movem, devagar.

## Personagens

Exceção à regra de contorno: personagem leva contorno de 1 px em `neutros_quentes:1` (marrom-arroxeado, nunca preto), porque precisa ser lido na frente do cenário. Altura de 26 a 28 px para caber na porta do saloon (32 px). Virado para a direita em repouso; o espelho para a esquerda é feito no Godot com flip_h. Animações em quadros do mesmo tamanho, com os pés na mesma linha.
