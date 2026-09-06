# tools/ — CLAUDE.md local

Ferramenta de desenvolvimento, não código de jogo. Nada daqui roda numa partida nem entra no build.

- `screenshot.gd` — sobe uma cena, espera N quadros e salva um PNG. Existe para o agente conferir visualmente o que programou, do mesmo jeito que confere um sprite antes de commitar.

**IMPORTANT:** se um arquivo daqui passar a ser chamado durante o jogo, ele não é mais ferramenta — mova para `utilities/` e siga a regra de autoload de lá.

Precisa de janela real: não funciona com `--headless`, porque o driver dummy não renderiza nada para capturar.
