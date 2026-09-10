# utilities/ — CLAUDE.md local

Lógica de bastidores: o que não aparece no mundo do jogo (não é `entities/`), não é um lugar (não é `stages/`), mas depende da lógica deste jogo (por isso não é `common/`).

Duas categorias moram aqui.

## 1. Managers autoload

Sufixo `_manager.gd`, registrados em Project Settings → Autoload. Sistemas que precisam existir antes da primeira cena e persistir entre elas: save/load, barramento global de sinais, transição e cache de cenas.

**Hoje não existe nenhum.** O projeto rodou um `Relogio` de campanha e ele foi removido: a seção 8 do conceito diz que o jogo não conta dias nem horas e que nada avança sozinho. Não recrie um relógio, um `tick` global nem um sistema que avance estado com o jogador em outro lugar.

O primeiro autoload provável é o que souber em que planeta o jogador está e o que ele já fez — estado salvo, não simulação.

Quando existir um, documente-o assim:

| Autoload | Arquivo | Responsabilidade | Sinais principais |
|---|---|---|---|

Esta tabela é a fonte de verdade rápida da API global de cada manager. Mantenha-a sincronizada com Project Settings → Autoload sempre que um autoload for criado, removido ou ganhar um sinal/método novo — documentar aqui evita ter que abrir o script só pra saber o que ele expõe.

## 2. Helpers sem estado global

Classes e funções auxiliares específicas deste jogo, chamadas sob demanda, que não precisam ser autoload. **Não** usam o sufixo `_manager.gd` — assim o sufixo continua significando exatamente "isto é um autoload".

| Helper | Arquivo | Responsabilidade |
|---|---|---|
| `Relevo` | `relevo.gd` | Constrói o relevo visível de uma superfície a partir do `perfil` dela: iluminação por inclinação, crosta e oclusão que obedecem à luz, estratos e fraturas recortados contra a massa, fio de luz em crista de fundo. Só funções estáticas; a fase é dona dos nós. A receita de montagem, com a ordem das camadas, está em `stages/CLAUDE.md`. |

Na dúvida, comece pela categoria 2: só promova a autoload o que de fato precisa rodar o tempo todo.

**Conceito:** seções 8 (o mundo que continua) e 12 (economia) de `docs/conceito-de-jogo.md` — é aqui que esses sistemas viram autoload. O que persiste é estado salvo: o jogo guarda o que já aconteceu e não faz nada acontecer sozinho.
