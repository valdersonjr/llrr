# entities/items/ — CLAUDE.md local

Padrão de herança usado em toda categoria de item, upgrade ou habilidade:

- Classe base no topo desta pasta (`item.gd`), com tudo que é comum a qualquer item do jogo.
- Uma subpasta irmã por subtipo/categoria (ex.: upgrades de motor, sensores, equipamento de coleta).
- Cada subtipo tem um script com sufixo indicando a classe estendida (ex.: `motor_item.gd extends Item`).

Ao adicionar um subtipo novo: crie a subpasta correspondente e o script com o sufixo `_item.gd` — não adicione lógica específica de subtipo dentro de `item.gd`, ela deve ficar isolada em cada subtipo.

**Conceito:** seção 5 de `docs/conceito-de-jogo.md`. Regra que não se negocia: todo equipamento cobra preço em massa, energia ou espaço. Não existe upgrade que só melhore.

**Combustível não existe neste jogo.** Nenhum item consome, armazena ou repõe combustível, e nenhum slot é tanque. Se um upgrade precisar de um preço, use massa, energia ou espaço.
