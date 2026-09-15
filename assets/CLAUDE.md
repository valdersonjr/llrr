# assets/

Só o que permeia o jogo inteiro. Se serve a uma entidade, a um lugar ou a uma categoria, o lugar é a pasta dela, não aqui.

| Arquivo | Para quê |
|---|---|
| `luz_redonda.png` | o gradiente radial que toda `PointLight2D` usa como máscara |
| `tema.tres` | o tema do projeto (`gui/theme/custom`): a fonte do jogo e o tamanho dela |
| `fonts/m6x11plus.ttf` | a fonte do jogo inteiro, de Daniel Linssen, com crédito obrigatório (`docs/creditos.md`) |

## A fonte

É uma fonte pixel, e **só fica nítida no tamanho 18 e nos múltiplos dele** (36, 54). Por isso o tamanho mora no tema e nenhuma tela o sobrescreve com outro número: texto de tamanho solto sai borrado ou com traço torto. Título que precisa crescer usa 36. Quem desenha texto por código lê o tamanho com `get_theme_default_font_size()`.

O importador está sem antialias, sem hinting e sem posição subpixel, e sem fonte de sistema de reserva: caractere que ela não tem aparece como caixa em vez de sair numa letra lisa que destoa. Ela não tem o ponto do meio `·`.

A luz é genérica de propósito: quem dá caráter é a cor e a energia no nó, não a textura. Baliza de pouso, chama de motor e painel aceso usam a mesma máscara.
