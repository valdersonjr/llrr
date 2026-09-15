# utilities/

Sistemas deste jogo. Duas espécies moram aqui e elas não se misturam.

| | Sufixo | Registro |
|---|---|---|
| Roda o tempo todo, tem estado global | `_manager.gd` | autoload em `project.godot`, e uma linha na tabela abaixo |
| Chamado sob demanda, sem estado | sem sufixo | nada a registrar, é só uma classe |

## Autoloads

| Autoload | Arquivo | O que faz |
|---|---|---|
| `ConfiguracoesManager` | `configuracoes_manager.gd` | carrega, aplica e guarda as opções do jogador (volumes nos barramentos `Master`, `Musica` e `Efeitos`, tela cheia e escala da janela); os valores têm o formato do recurso `data/configuracoes.gd`, e o arquivo é um `ConfigFile` em `user://configuracoes.cfg`, nunca um `.tres`, porque carregar recurso escrito fora do jogo executaria o script de dentro dele |

O próximo previsto é `campanha_manager.gd`, dono dos créditos, dos contratos aceitos e do que o mundo lembra, e responsável por salvar em `user://`.

## Helpers

| Classe | Para quê |
|---|---|
| `Escala` | converte metro em pixel, e guarda a gravidade da Terra |
| `Silhueta` | tira os contornos opacos de uma textura, para a colisão sair do alfa da arte |

`Silhueta` existe porque a nave e a pedra pediam a mesma conta: o casco tira a forma do alfa do desenho dele, e a pedra faz igual. Ela devolve geometria, nunca nó, porque só quem chama sabe de quem é a forma e se ela precisa aparecer no editor.

**IMPORTANT:** `Escala.PIXELS_POR_METRO` é a única definição de quanto vale um pixel. Toda ficha do jogo escreve grandeza física em unidade de verdade, e a conversão acontece só na fronteira com a física do Godot. Se você viu `px/s` dentro de um `.tres`, alguém errou.
