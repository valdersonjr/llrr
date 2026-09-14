# ui/

Telas e elementos de interface. Não são entidades: não são irmãos da nave na árvore de cena.

## HUD

`hud/hud.tscn` é o painel de telemetria. Duas regras vêm direto do conceito:

- **Só moldura, nenhuma barra.** A versão 0.10 devolveu ao HUD a moldura atrás dos números e manteve a barra fora, porque não existe grandeza contínua para uma barra mostrar. Não há dano, não há integridade de casco, não há alerta de casco crítico.
- **Laranja é o que está fora do limite de pouso.** É assim que o painel cumpre a promessa de consequência legível da seção 2. Cor sozinha nunca basta, então o número fica sempre visível ao lado.

O HUD não procura a nave sozinho. Quem monta a cena chama `acompanhar(nave)`. Telemetria é lida por quadro pelos métodos da nave; só a mudança de estado de pouso chega por sinal.

## Menu

`menu/` é a primeira tela e a **única parte do jogo que troca a cena inteira**. Dentro do jogo isso é proibido, e o `CLAUDE.md` da raiz explica por quê; aqui é o contrário: ainda não existe nave para preservar, e sair do menu é justamente o momento de montar o mundo do zero.

**Sem botão que não leva a lugar nenhum.** Configurações e continuar partida entram quando existirem tela de opções e save, e não antes: menu com item morto ensina o jogador a desconfiar do que ele lê. Hoje são duas opções, jogar e sair.

O fundo é a tela desenhada para o jogo. **O título e os botões foram apagados da imagem**, e no lugar deles vai interface de verdade, na mesma posição e na mesma paleta. O que está na arte é paisagem; o que se lê e se clica tem foco de teclado, estado de mouse e texto que um dia vira chave de tradução. Um botão pintado no fundo não tem nada disso.

A geometria não foi inventada: as posições do título e das duas caixas saíram medidas do desenho, em pixels, e a paleta também. A fonte é a Luckiest Guy, escolhida por comparação lado a lado com a letra do desenho.

O foco começa na primeira opção. Sob o foco, a caixa ganha preenchimento claro e uma borda esquerda mais grossa, porque no fundo claro um contorno sozinho quase não aparece.

A música do menu é só do menu, e é por construção: o `AudioStreamPlayer` vive na cena do menu, que morre quando o jogo começa. O laço está ligado no importador do mp3, não em código. Uma região pode ter música própria pelo mesmo caminho, dentro da cena dela: o Outpost de Arvo é a primeira (ver `mundo/CLAUDE.md`).

O título continua sendo placeholder, e agora ele é honesto sobre isso: "Ainda sem nome".

## Órbita

`orbita/` tem duas coisas que são a mesma conversa em dois momentos: o convite que acende quando a nave chega perto de um corpo, e a tela de regiões que a tecla abre. A cena do sistema acende uma e abre a outra; a `Orbita` não decide nada, só mostra e avisa o que o jogador escolheu.

A tela é interface e não mundo, de propósito. Nome de lugar, foco de teclado e clique de mouse são exatamente o que um `Control` já faz bem. As setas funcionam sem ninguém ligar fio nenhum: sem vizinho de foco declarado, o Godot acha o marcador mais próximo na direção apertada, que é a leitura certa quando os marcadores estão espalhados sobre um disco.

A tela diz como se sai dela de duas formas, porque uma só não alcança todo mundo: um botão de sair no canto, para quem está no mouse, e uma linha de comandos embaixo, que nomeia as setas, o Enter e o Esc. A tecla de sair continua valendo sozinha, mas quem entrou de mouse não teria como descobrir que ela existe.

O painel de telemetria some enquanto a órbita está aberta e durante a chegada. Ele é telemetria de voo, e ali não há voo do jogador: mostrar a velocidade do piloto automático seria mentir sobre o que ele está fazendo.

## Mapa

`mapa/` abre no `M`, e só no espaço: dentro de uma região não há para onde navegar. Ele mostra onde a nave está e onde os corpos estão, **e nada além disso**. Não traça rota, não estima tempo e não leva ninguém a lugar nenhum: a seção 9 do conceito é explícita em que viagem não se resolve por interface, e um mapa que vira painel de destino tira do voo a única razão de ele existir.

Ele não para o jogo: é para se localizar no meio do voo, então a nave continua andando com o mapa aberto e o marcador dela acompanha, quadro a quadro. Entrar num planeta fecha o mapa, porque ali ele não tem o que dizer. O desenho mora num filho, `QuadroDoMapa`, para o retângulo do mapa ser o quadro das contas de posição em vez da tela inteira.

O tamanho dos corpos no mapa é proporcional ao tamanho deles no sistema: hoje Arvo ocupa um bom pedaço do espaço porque o espaço é pequeno de propósito, e isso encolhe sozinho quando ele crescer.

## Arte

`art/` aqui serve à categoria inteira, não a uma tela. A moldura saiu do pacote de arte e é placeholder declarado.

## Texto

Todo texto exibido ao jogador vai virar chave de tradução em `localization/`. Os rótulos de hoje são provisórios e estão escritos direto no script.
