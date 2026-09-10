# tools/ — CLAUDE.md local

Ferramenta de desenvolvimento, não código de jogo. Nada daqui roda numa partida nem entra no build.

- `screenshot.gd` — sobe uma cena, espera N quadros e salva um PNG. `--acao <nome>` dispara uma ação de input no meio do caminho, para fotografar o que só existe depois de uma tecla (menu de pausa, tela aberta). Existe para o agente conferir visualmente o que programou, do mesmo jeito que confere um sprite antes de commitar.
- `voo_check.gd` — sobe uma fase, dirige a nave por código e confere os critérios de aceitação do fim da seção 4 do conceito. Sai com o número de falhas como código de saída. Rode antes e depois de mexer na física da nave. **Está parado:** a fase de teste que ele usava foi apagada, e ele só volta a rodar quando a constante `CENA` e as duas coordenadas ao lado dela apontarem para a primeira região do mapa de verdade.

**IMPORTANT:** se um arquivo daqui passar a ser chamado durante o jogo, ele não é mais ferramenta — mova para `utilities/` e siga a regra de autoload de lá.

**IMPORTANT:** as ferramentas daqui rodam como **cena** (`--scene res://tools/<nome>.tscn`), não como `--script`. Um script passado em `--script` vira o próprio `SceneTree` e é compilado **antes de os autoloads existirem** — e aí todo script de jogo que use um deles falha a compilação, inclusive os que a ferramenta só queria carregar. O sintoma é ruim de ler: a cena carrega com os nós no tipo base errado, e a ferramenta trava sem mensagem clara.

Por isso `voo_check.gd` tem cão de guarda: passou do teto de quadros, ele acusa e sai com erro. Sem isso, qualquer falha que mate a corrotina deixa o processo rodando para sempre, porque `quit()` só é chamado no fim da sequência.

`screenshot.gd` precisa de janela real: não funciona com `--headless`, porque o driver dummy não renderiza nada para capturar. `voo_check.gd` só usa física, então roda headless.
