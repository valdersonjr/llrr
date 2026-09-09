# tools/ — CLAUDE.md local

Ferramenta de desenvolvimento, não código de jogo. Nada daqui roda numa partida nem entra no build.

- `screenshot.gd` — sobe uma cena, espera N quadros e salva um PNG. `--acao <nome>` dispara uma ação de input no meio do caminho, para fotografar o que só existe depois de uma tecla (menu de pausa, tela aberta). Existe para o agente conferir visualmente o que programou, do mesmo jeito que confere um sprite antes de commitar.
- `voo_check.gd` — sobe a fase de teste, dirige a nave por código e confere os critérios de aceitação do fim da seção 4 do conceito. Sai com o número de falhas como código de saída. Rode antes e depois de mexer na física da nave.

**IMPORTANT:** se um arquivo daqui passar a ser chamado durante o jogo, ele não é mais ferramenta — mova para `utilities/` e siga a regra de autoload de lá.

`screenshot.gd` precisa de janela real: não funciona com `--headless`, porque o driver dummy não renderiza nada para capturar. `voo_check.gd` só usa física, então roda headless.
