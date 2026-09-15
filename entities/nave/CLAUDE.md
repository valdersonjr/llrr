# entities/nave/

A nave do jogador, que é o personagem principal do jogo.

## Uma cena, três modelos

`nave.tscn` é a única cena. Os três modelos do conceito — utilitário leve, cargueiro resistente e interceptador — são `ModeloDeNave` diferentes em `data/modelos/`, e a cena lê da ficha massa, empuxo, autoridade de manobra, limites de pouso e a arte do casco, de onde sai a forma de colisão. **Não crie uma cena por modelo.** Só existe um hoje: `utilitario_leve.tres`.

Para acrescentar um modelo: um `.tres` novo em `data/modelos/`, e nada mais. A arte do casco vai na própria ficha, e a colisão sai do alfa dela, por `Silhueta`.

## Corpo rígido é escolha de protótipo

`Nave` estende `RigidBody2D` porque inércia, massa que muda com a carga e torque saem de graça daí, e o conceito pede exatamente essas três. Não é dogma: a seção 18 diz que a sensação de voo só se decide voando. Se o voo pedir outra coisa, o lugar de trocar é aqui e nada fora desta pasta depende da escolha.

## O que a nave expõe

| O quê | Como |
|---|---|
| estado de pouso | sinal `pouso_mudou(novo)`, com `VOANDO`, `TOCANDO` e `POUSADA` |
| velocidade, inclinação, giro | `velocidade()`, `inclinacao_em_graus()`, `giro_por_segundo()` |
| cada medida dentro do limite | `velocidade_no_limite()`, `inclinacao_no_limite()`, `giro_no_limite()` |
| com que força ela encostou | `velocidade_do_toque`, em m/s, e `toque_no_limite()` |
| recolocar sem brigar com a física | `reposicionar(ponto, velocidade)` |
| mover sem recomeçar o voo | `deslocar(por)`, que não toca em velocidade, ângulo nem giro |
| guardar e devolver a nave | `congelar()` e `soltar()`, com `congelada()` para perguntar |

Só o que é discreto vira sinal. Telemetria é contínua e quem mostra lê direto, sem um fio ligado por quadro.

Três coisas parecidas que não são a mesma, e que já se confundiram uma vez: `velocidade()` é a de agora, `velocidade_do_toque` é a guardada no instante do contato, e `modelo.velocidade_maxima_de_toque` é o limite do trem de pouso.

## A física em unidade de verdade

A ficha fala em quilo, em g e em metro por segundo. A conversão para pixel acontece só aqui dentro, com `Escala`. Três detalhes que não são óbvios:

- **O centro de massa fica embaixo**, perto das pernas, como em qualquer módulo de pouso real. É o que decide se a nave assenta torta ou tomba: com o centro no meio do casco ela vira aos 40 graus, a 40% do caminho entre o meio e a base do desenho aguenta 60. É uma fração da altura da arte (`CENTRO_DE_MASSA_ATE_A_BASE`), e não um ponto fixo, para trocar o casco levar o centro junto.
- **Rotação é aceleração angular direta, não torque.** Assim a autoridade de manobra é número desenhado na ficha, e não consequência da inércia calculada da forma de colisão. Trocar a silhueta de um modelo não mexe em como ele gira.
- **`velocidade_do_toque` é guardada no quadro anterior ao contato.** O contato zera a velocidade dentro do mesmo passo de física, então ler depois sempre dá zero. Esse é o número que uma consequência de pouso ruim vai usar quando a seção 18 do conceito for respondida.

## Guardada, ela não voa nem é comandada

`congelar()` para a simulação, apaga o motor e desliga os comandos; `soltar()` devolve tudo. É o estado da nave enquanto o jogador lê a tela de regiões e enquanto o piloto automático a leva ao ponto de aparecimento. Quem decide isso é a cena do sistema: a nave não sabe que existe órbita.

Congelada ela continua sendo movida, porque o corpo é cinemático nesse estado. Ao descongelar, o servidor devolveria a ela a velocidade do último empurrão, e por isso quem termina uma chegada chama `reposicionar()` logo depois: recolocar zera posição, velocidade e giro de uma vez.

## Pouso é estado, não colisão

A avaliação soma velocidade, inclinação, giro e tempo parado, e só vale sobre um corpo do grupo `pontos_de_coleta`. `TEMPO_ATE_ASSENTAR` é quanto tempo calmo o contato precisa durar. Hoje pousar mal não custa nada: essa é a pergunta central da seção 18 do conceito, e quando ela for respondida a consequência entra aqui.

## O piloto

`piloto/` é o astronauta que pilota a nave, e o rosto do jogo. Ele não simula nada: aparece do lado de fora da nave onde isso faz sentido, hoje na tela de título e nos créditos. `piloto.tscn` monta as animações (`parar()`, `acenar()`, `andar(para_a_esquerda)`) a partir de três tiras de quadros de 20x22 em `piloto/art/`, com a origem no meio dos pés. O boneco ocupa as 16 colunas da esquerda do quadro; as 4 da direita são o ar para o braço do aceno, e por isso o deslocamento do desenho muda quando ele vira.

## Aparência

`nave.gd` simula e avalia, e não desenha nada. Quem desenha é `apresentacao_da_nave.gd`, no nó filho `Apresentacao`, dono do casco, da chama e da luz do motor.

O fluxo é de mão única: a nave manda o empuxo, a apresentação decide como mostrar. Ela não conhece `Nave` e não lê o pai, então trocar a aparência não toca em força nenhuma. O motivo de estarem separados é que chama e luz não têm relação com inércia, massa ou avaliação de pouso, e enquanto moravam juntos o código de física carregava três referências de nó de desenho no meio das forças.

O casco é o foguete, `art/foguete.png` (32x48), e a chama é a tira `art/chama.png` com três quadros de 10x16 que piscam na ordem média, curta, média, longa enquanto o motor empurra; o empuxo estica a chama só para baixo, com a linha de cima presa na boca do bocal. As fontes `.pix` estão em `art/fonte/`, no conjunto `nave` da skill `pixel-art-sprite`. Quem troca o casco confere a posição do nó `Chama`, que é a boca do bocal do desenho.

**No espaço a nave ganha um anel.** O contorno do casco é `neutros_quentes:0`, a mesma cor do vazio, e contra ele a borda e o lado da sombra somem: a nave parecia apagada. `ApresentacaoDaNave` monta, a partir do alfa da arte, a silhueta engordada 1 px em `neutros_frios:1`, e o nó `AnelDeEspaco` a desenha atrás do casco. Quem acende e apaga é a cena do sistema, por `realcar_no_espaco()`: aceso no espaço, apagado nas regiões, onde o céu claro já separa o casco.

**No espaço a apresentação também troca de escala.** Com a câmera em `zoom_no_espaco`, cada pixel da arte cairia em 0,9 pixel de janela, e a amostragem comia e dobrava pixels: o anel saía quebrado. `Apresentacao` recebe escala `0,5 / zoom_no_espaco`, e cada pixel da arte cai em meio pixel da tela base, que é um pixel inteiro de janela. Só o desenho muda de escala, não a colisão, e a chegada numa região já devolve o tamanho de arte. `tools/orbita_check.tscn` reprova se escala e zoom se desencontrarem.
