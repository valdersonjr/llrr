# tools/

Ferramenta de dev. Não entra no build e não é jogo.

| Ferramenta | Para quê |
|---|---|
| `foto.tscn` | sobe uma cena, espera assentar e grava um PNG |
| `voo_check.tscn` | mede a gravidade em queda livre, solta a nave sobre o deque e pilota uma descida freada, sem abrir janela |
| `cenario_check.tscn` | desce um raio sob cada peça de cenário e acusa quem está flutuando ou enterrado |
| `orbita_check.tscn` | entra e sai de um planeta pelo caminho inteiro: chegada, volta ao mundo, tela de regiões e espaço |
| `menu_check.tscn` | confere a primeira tela: foco, opções ligadas e o destino de "jogar" |

```
godot --path . --scene res://tools/foto.tscn -- \
    --cena res://mundo/sistema/sistema.tscn --saida foto.png --quadros 140

godot --headless --path . --scene res://tools/voo_check.tscn
```

`foto` aceita `--olhar x,y` para plantar uma câmera própria, útil para fotografar uma região sem nave, e `--soltar x,y` para recolocar a nave e fotografar um pouso sem pilotar até ele. `--zoom` acompanha o `--olhar`. `--soltar` serve também para fotografar a vista de espaço: solta a nave alto e a troca de vista acontece sozinha.

**IMPORTANT:** a janela da foto roda em segundo plano, então o desenho é estrangulado e a física não. Esperar um quadro desenhado custa dezenas de quadros de voo, e por isso `foto` não serve para fotografar um instante exato de uma queda. Para isso, solte a nave parada na altura que interessa: sem gravidade ela fica lá.

`cenario_check` nasceu de um bug real: uma pedra plantada dentro de um platô, com a base no nível do vale, que a olho nu parecia só encostada na parede. Sprite que é solto de propósito — fundo, copa cortada pelo quadro, primeiro plano — entra no grupo `solto` e é pulado.

```
godot --headless --path . --scene res://tools/cenario_check.tscn -- \
    --regiao res://mundo/planetas/arvo/regioes/bosque/bosque_regiao.tscn
```

`orbita_check` guarda a promessa central da entrada: **onde a nave aparece é escolha de quem desenhou o lugar**. Se a chegada parar em outro ponto, ou parar andando, o pouso começa diferente do que o projetista desenhou e nenhum lugar fica calibrável. Ele também confere a volta ao mundo da região, que é a única saída pelos lados, e o convite de entrada no espaço.

```
godot --headless --path . --scene res://tools/orbita_check.tscn
```

`menu_check` cobra o defeito mais caro e mais silencioso de um menu: botão que não leva a lugar nenhum, ou destino que deixou de existir depois de alguém mover uma cena. Nada disso aparece em compilação, só em quem abriu o jogo e clicou.

```
godot --headless --path . --scene res://tools/menu_check.tscn
```

`voo_check` pilota de verdade: ele usa `Input.action_press` na ação `empuxo`, o mesmo caminho do jogador, para provar que o empuxo da ficha dá conta da gravidade do planeta. Se esse critério falha, o pouso é impossível e não difícil.

Ele existe porque `--check-only` não carrega autoload nem roda física. A única verificação real de pilotagem é subir o jogo, e ela sai com código diferente de zero quando um critério falha, então serve em script.

Ao acrescentar uma ferramenta, dê a ela uma linha na tabela acima e outra na tabela de comandos do `CLAUDE.md` da raiz.
