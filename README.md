# llrr

Jogo singleplayer de pilotagem e trabalho espacial em 2D, inspirado em Lunar Lander. A nave é o personagem principal, e o jogo tem duas vistas dela: o espaço, onde se navega entre planetas, e a superfície, onde se pousa. Outposts são regiões dos planetas.

## Estado

O laço de entrar e sair de um planeta está fechado, com um planeta, Arvo, e uma região, o Outpost. A nave nasce no espaço, que é finito e dá a volta nos quatro lados. Chegar perto de um corpo acende o convite de entrada; a tecla abre a tela de regiões dele; escolher uma região leva a nave, por piloto automático, ao ponto de aparecimento que o projetista definiu.

| Lugar | Região | O que muda na pilotagem |
|---|---|---|
| Arvo | Outpost | posto de fronteira de faroeste, com saloon e deque sobre palafitas |

Ainda não existem contratos, economia nem save.

## Documentação

| Arquivo | O que tem |
|---|---|
| [docs/conceito-de-jogo.md](docs/conceito-de-jogo.md) | o design: o que o jogo é, o que o jogador faz, onde ficam os limites de escopo |
| [CLAUDE.md](CLAUDE.md) | a arquitetura de pastas e as convenções de código |
| [docs/stack.md](docs/stack.md) | engine, linguagem e ferramentas |
| [docs/brainstorm.md](docs/brainstorm.md) | ideias soltas |
| [docs/creditos.md](docs/creditos.md) | a arte de terceiros e o que a licença de cada pacote permite |

## Rodando

Godot 4.7.2, com o binário `godot` no PATH.

```
godot --path .                             # sobe o jogo, a partir do menu
godot -e --path .                          # abre o editor
godot --path . --scene res://<cena>.tscn   # sobe uma cena isolada
```

A cena principal é `ui/menu/menu.tscn`, e o jogo em si é `mundo/sistema/sistema.tscn`. Uma região também abre sozinha por `--scene`, sem nave, que é como se trabalha terreno.

## Conferências

Não há framework de teste. No lugar dele, há ferramentas que sobem o jogo e medem, e que saem com código diferente de zero quando um critério falha.

```
godot --headless --path . --scene res://tools/menu_check.tscn
godot --headless --path . --scene res://tools/voo_check.tscn
godot --headless --path . --scene res://tools/orbita_check.tscn
godot --headless --path . --scene res://tools/cenario_check.tscn -- \
    --regiao res://mundo/planetas/arvo/regioes/outpost/outpost_regiao.tscn
```

A tabela completa de comandos está no `CLAUDE.md`.
