# entities/obstaculos/

O que tem tamanho para o jogador ler como sólido. A regra que segura a categoria está em `entities/CLAUDE.md`: **o que parece sólido tem que ser sólido**, porque pedra grande que a nave atravessa é armadilha, não enfeite.

| Entidade | O que é |
|---|---|
| `pedra/` | rocha parada no terreno, encostada no chão |
| `asteroide/` | rocha solta no céu, atravessando a região |

## A colisão sai da arte

As duas tiram a forma do alfa do próprio desenho, por `Silhueta`. Trocar a textura nunca deixa a forma e o desenho em desacordo, e a mesma cena serve a qualquer pedra de qualquer planeta.

## Asteroide é cinemático, não solto

`Asteroide` é um `RigidBody2D` congelado em modo cinemático, e isso é decisão de design, não economia:

- ele **empurra** a nave e não é empurrado, então a rota que o projetista desenhou continua valendo depois de qualquer batida;
- ele ignora a gravidade do lugar, então a mesma cena serve a um planeta de gravidade alta e a um de gravidade baixa;
- asteroide que reage a batida vira bola de sinuca, e aí a região deixa de ser desenhável.

Cada um tem a sua `velocidade` e o seu `giro`. É isso que faz um punhado deles parecer campo em vez de fileira.

## Eles dão a volta, como a região

Sair por um lado é entrar pelo outro, com a margem de `Asteroide.MARGEM` para a volta acontecer fora da tela. Sem isso o céu se esvazia em vinte segundos e o desafio some junto.

O sprite de um asteroide entra no grupo `solto`: ele flutua de propósito, e sem isso o `cenario_check` o acusaria de não estar apoiado.
