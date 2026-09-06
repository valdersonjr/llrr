# entities/ — CLAUDE.md local

Tudo aqui é "irmão" do player na scene tree: qualquer coisa que existe DENTRO de uma fase, com que o jogador pode interagir ou que aparece no mundo.

- `player/` — nave/personagem controlado pelo jogador.
- `<categoria_npc_ou_inimigo>/` — agrupe por tipo/categoria, não numa pasta genérica "inimigos".
- `items/` — ver `items/CLAUDE.md` nesta mesma pasta para o padrão de herança.
- `ui/` — HUD e telas que vivem como nó na scene tree. Fica aqui dentro, não como pasta de topo separada, porque é conteúdo com que o player interage. Ver `ui/CLAUDE.md`.

Cada entidade concreta é uma pasta-folha com `art/`, `data/`, `sound/` + cena e script de mesmo nome — o formato exato está em "Estrutura da pasta-folha" no `CLAUDE.md` da raiz.

Regra prática pra decidir entities vs. stages: se a dúvida for "isso é algo que existe dentro de um lugar, ou é o próprio lugar?" — a primeira opção vai aqui, a segunda vai em `stages/`.

**Conceito:** seções 4 (pilotagem), 5 (nave, módulos e dano) e 10 (combate) de `docs/conceito-de-jogo.md`. Leia antes de definir regra de comportamento — os critérios de aceitação do voo estão no fim da seção 4.
