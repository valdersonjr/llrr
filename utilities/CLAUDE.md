# utilities/ — CLAUDE.md local

Lógica de bastidores: o que não aparece no mundo do jogo (não é `entities/`), não é um lugar (não é `stages/`), mas depende da lógica deste jogo (por isso não é `common/`).

Duas categorias moram aqui.

## 1. Managers autoload

Sufixo `_manager.gd`, registrados em Project Settings → Autoload. Sistemas que precisam existir antes da primeira cena e persistir entre elas: save/load, barramento global de sinais, transição e cache de cenas.

| Autoload | Arquivo | Responsabilidade | Sinais principais |
|---|---|---|---|
| *(preencher conforme forem criados)* | | | |

Esta tabela é a fonte de verdade rápida da API global de cada manager. Mantenha-a sincronizada com Project Settings → Autoload sempre que um autoload for criado, removido ou ganhar um sinal/método novo — documentar aqui evita ter que abrir o script só pra saber o que ele expõe.

## 2. Helpers sem estado global

Classes e funções auxiliares específicas deste jogo, chamadas sob demanda, que não precisam ser autoload. **Não** usam o sufixo `_manager.gd` — assim o sufixo continua significando exatamente "isto é um autoload".

Na dúvida, comece pela categoria 2: só promova a autoload o que de fato precisa rodar o tempo todo.

**Conceito:** seções 8 (tempo), 12 (economia) e 13 (facções) de `docs/conceito-de-jogo.md` — é aqui que esses sistemas viram autoload. O relógio de campanha nunca avança com o jogo fechado.
