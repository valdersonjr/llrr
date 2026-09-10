# entities/ — CLAUDE.md local

Tudo aqui é "irmão" do player na scene tree: qualquer coisa que existe DENTRO de uma fase, com que o jogador pode interagir ou que aparece no mundo.

- `player/` — a nave do jogador. Ver `player/CLAUDE.md` para o padrão dos modelos.
- `estruturas/` — o que é construído e fica parado no mundo: plataforma de pouso, mina, base.
- `<categoria_de_npc>/` — agrupe por tipo/categoria, não numa pasta genérica.
- `items/` — ver `items/CLAUDE.md` nesta mesma pasta para o padrão de herança.
- `ui/` — HUD e telas que vivem como nó na scene tree. Fica aqui dentro, não como pasta de topo separada, porque é conteúdo com que o player interage. Ver `ui/CLAUDE.md`.

Cada entidade concreta é uma pasta-folha com `art/`, `data/`, `sound/` + cena e script de mesmo nome — o formato exato está em "Estrutura da pasta-folha" no `CLAUDE.md` da raiz. A exceção é a variação que só muda número e arte: as três pastas de modelo não têm script próprio, todas apontam para `nave.gd`, e o porquê está em `player/CLAUDE.md`.

Regra prática pra decidir entities vs. stages: se a dúvida for "isso é algo que existe dentro de um lugar, ou é o próprio lugar?" — a primeira opção vai aqui, a segunda vai em `stages/`.

**Conceito:** seções 4 (pilotagem), 5 (nave e módulos) e 10 (o pouso e o ponto de coleta) de `docs/conceito-de-jogo.md`. Leia antes de definir regra de comportamento — os critérios de aceitação do voo estão no fim da seção 4.

**Não existe combate nem dano neste jogo.** Nada de armas, inimigos, naves hostis, mira, projétil, integridade, casco quebrado ou destruição. Se uma entidade precisa criar dificuldade, ela cria pelo caminho até o pouso: relevo, obstáculo na descida, gravidade.
