# entities/ui/ — CLAUDE.md local

HUD e telas do jogo. Fica dentro de `entities/` porque são nós na scene tree com que o jogador interage, não uma categoria de asset.

- Uma subpasta por tela/componente (`hud/`, `pause_menu/`, `inventory/`), com cena + script juntos, seguindo a mesma estrutura de folha das outras entidades.
- Componente de UI reaproveitável e sem lógica deste jogo (botão estilizado, escala de resolução) vai em `common/`, não aqui.
- Dado que a tela de opções lê e grava mora em `config/`; aqui fica só a apresentação.
