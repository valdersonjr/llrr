# entities/items/ — CLAUDE.md local

Padrão de herança usado em toda categoria de item, upgrade ou habilidade:

- Classe base no topo desta pasta (`item.gd`), com tudo que é comum a qualquer item do jogo.
- Uma subpasta irmã por subtipo/categoria (ex.: armas, upgrades de motor, skills).
- Cada subtipo tem um script com sufixo indicando a classe estendida (ex.: `weapon_item.gd extends Item`).

Ao adicionar um subtipo novo: crie a subpasta correspondente e o script com o sufixo `_item.gd` — não adicione lógica específica de subtipo dentro de `item.gd`, ela deve ficar isolada em cada subtipo.
