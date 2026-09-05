# config/ — CLAUDE.md local

Configuração exposta ao jogador — o que aparece no menu de opções: volume por bus de áudio, resolução/tela, tweaks de gameplay. Inclui a persistência dessas escolhas.

- Pasta pequena por natureza; não vire depósito de constante de jogo. Valor que o jogador não muda (dano de arma, velocidade) é dado da entidade e vai na `data/` dela.
- A tela de opções em si (nós, layout) é UI e vive em `entities/ui/`; aqui fica só o dado por trás dela.
