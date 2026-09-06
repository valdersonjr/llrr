# entities/items/ — CLAUDE.md local

Padrão de herança usado em toda categoria de item, upgrade ou habilidade:

- Classe base no topo desta pasta (`item.gd`), com tudo que é comum a qualquer item do jogo.
- Uma subpasta irmã por subtipo/categoria (ex.: armas, upgrades de motor, skills).
- Cada subtipo tem um script com sufixo indicando a classe estendida (ex.: `weapon_item.gd extends Item`).

Ao adicionar um subtipo novo: crie a subpasta correspondente e o script com o sufixo `_item.gd` — não adicione lógica específica de subtipo dentro de `item.gd`, ela deve ficar isolada em cada subtipo.

**Conceito:** seção 5 de `docs/conceito-de-jogo.md`. Regra que não se negocia: todo equipamento cobra preço em massa, energia, espaço, combustível ou manutenção. Não existe upgrade que só melhore.
