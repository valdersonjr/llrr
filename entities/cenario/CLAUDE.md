# entities/cenario/

Parece vivo e não faz nada. A regra dura está no `CLAUDE.md` de `entities/`: cenário nunca vira tarefa, nunca disputa leitura com o lugar de pouso e nunca entra no save.

| Entidade | Onde vive hoje | Como anda |
|---|---|---|
| `arbusto_seco/` | Outpost | rola com o vento e dá a volta na tela; sombra parada no chão |
| `xerife/` | Outpost | parado, respirando; tem também a animação `anda` |
| `dono_do_saloon/` | Outpost, na porta do saloon | parado, respirando e piscando |
| `cowboy/` | Outpost, no banco da varanda | cochilando, respiração lenta |

## Personagem é uma cena sem script

Raiz `Node2D` com um `AnimatedSprite2D` chamado `Sprite`. As animações saem das tiras em `art/` (uma tira por animação, lida por recortes de `AtlasTexture`), e o `offset` põe **a origem nos pés**: posicionar o personagem é pôr a origem na linha em que ele pisa. Personagem em cima de outra peça (varanda, banco) não pisa no relevo; o `cenario_check` só confere `Sprite2D`, então isso não gera falso alarme.

O dono do saloon está aqui porque hoje não faz nada. No dia em que ele emitir contrato, deixa de ser cenário e muda de pasta.

As fontes `.pix` de cada um estão em `art/fonte/quadros/`, e o PNG em tira sai de `python3 .claude/skills/pixel-art-sprite/scripts/montar_arte.py`.
