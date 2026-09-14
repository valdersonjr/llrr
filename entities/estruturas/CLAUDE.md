# entities/estruturas/

Construído e parado. Se tem tamanho de sólido na descida e não foi construído, é `obstaculos/`.

| Entidade | O que é |
|---|---|
| `ponto_de_coleta/` | o lugar de pouso que vale; sem arte própria, cada lugar aponta a dele |
| `saloon/` | o saloon do Outpost de Arvo, montado com peças de 64 px no máximo; sem colisão |
| `sinal_de_pouso/` | a luz que pisca enquanto a nave desce e muda de cor no pouso |

## O sinal escuta o ponto de coleta

`ponto_de_coleta` emite `estado_mudou` e guarda `estado_atual`. O `sinal_de_pouso` aponta para ele por `NodePath` e troca de quadro e de luz conforme o estado. Nenhum dos dois conhece a nave: quem avisa é a cena do sistema, como antes.

A arte do sinal é do lugar. A instância diz a tira (`folha`), qual quadro pisca, qual é o contato e qual é o pouso, e a cor da luz de cada quadro. O Outpost usa `regioes/outpost/art/pouso_sinal.png`: apagado, vermelho, amarelo e verde.

O sinal fica fora da colisão do ponto de coleta, em cima dos postes do deque. Coloque a instância do sinal **depois** do ponto de coleta na árvore, para ele ler o estado já pronto.

## O saloon é uma cena só de desenho

A origem é o chão, na ponta esquerda da calçada. As peças que não tocam o chão entram no grupo `solto`, e só a calçada é conferida pelo `cenario_check`. As fontes `.pix` estão em `art/fonte/`, geradas com a skill `pixel-art-sprite`.
