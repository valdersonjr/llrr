# ui/

Telas e elementos de interface. Não são entidades: não são irmãos da nave na árvore de cena.

## HUD

`hud/hud.tscn` é o painel de telemetria, no mesmo painel escuro da tela de regiões e do mapa, e cresce e encolhe com o que tem a dizer. Uma informação abaixo da outra, cada linha com ícone de 8x8, número e unidade: sempre velocidade vertical e horizontal (a seta diz o sentido), altitude sobre o chão logo abaixo e inclinação. O resto só aparece quando conta: o giro quando passa do limite, a estabilização (tecla T) quando está desligada e a situação quando a nave encosta (contato, pousada ou duro). Os números ficam alinhados à direita numa coluna própria, porque a fonte não tem algarismos de largura fixa e o número tremeria. Duas regras vêm direto do conceito:

- **Só moldura, nenhuma barra.** A versão 0.10 devolveu ao HUD a moldura atrás dos números e manteve a barra fora, porque não existe grandeza contínua para uma barra mostrar. Não há dano, não há integridade de casco, não há alerta de casco crítico.
- **Verde dentro, vermelho fora da especificação de pouso da região.** É assim que o painel cumpre a promessa de consequência legível da seção 2. Cada região diz o que exige na ficha (`pouso`), e vale o mais apertado entre isso e o trem de pouso da nave. Cor sozinha nunca basta: o ícone da linha que está fora pisca trocando por um triângulo de alerta, e o número fica sempre visível. No espaço não há lugar de pouso e os números ficam neutros.

A altitude é medida pela nave, no passo de física, por um raio do pé até o chão; no espaço não há chão e o painel mostra `--`. `tools/voo_check.tscn` confere o altímetro no espaço, no ar e com as pernas no chão.

O HUD não procura a nave sozinho. Quem monta a cena chama `acompanhar(nave)`. Telemetria é lida por quadro pelos métodos da nave; só a mudança de estado de pouso chega por sinal.

## Menu

`menu/` é a tela de título e a **primeira troca de cena inteira** do jogo. Dentro do jogo trocar a cena é proibido, e o `CLAUDE.md` da raiz explica por quê; aqui é o contrário: ainda não existe nave para preservar, e sair do menu é justamente o momento de montar o mundo do zero. A outra troca é voltar da pausa para cá, pelo mesmo motivo: é o jogador saindo do mundo.

**Sem botão que não leva a lugar nenhum.** Hoje são NOVO JOGO, OPÇÕES, CRÉDITOS e SAIR. "Continuar" entra quando existir save, e não antes: menu com item morto ensina o jogador a desconfiar do que ele lê.

**O fundo não é de lugar nenhum.** A tela de título vale para o jogo inteiro, e o jogo vai ter planetas, regiões e outposts que ainda não existem, então nada nela é de Arvo ou do Outpost:

- o espaço é o mesmo campo de estrelas do sistema, com uma câmera parada no centro da tela;
- a **vitrine** mostra um corpo de planeta sorteado a cada abertura, achado nas pastas de `mundo/planetas/` (`Menu.corpos_de_planeta()`); planeta novo aparece sem ninguém cadastrar;
- a **cena do título** (`cena_do_titulo.gd`) é um laço de 18 s numa doca de metal genérica: a nave desce com a chama acesa e as luzes piscando, apaga no toque com uma baforada de vapor, o piloto sai de trás dela, acena, respira e volta, e a nave sobe. O laço é função do tempo, sem estado acumulado, e por isso a conferência pergunta a altura da nave em qualquer instante.

O logo é o nome do jogo na fonte do jogo, em 54 e 36, com contorno e sombra desenhados pixel a pixel (`logo_do_titulo.gd`). Arte da doca, dos postes, das luzes e do vapor em `menu/art/`, com a fonte `.pix` em `art/fonte/`, no conjunto `nave` da skill `pixel-art-sprite`.

A música do menu é só do menu: o `AudioStreamPlayer` vive na cena, que morre quando o jogo começa, e passa pelo barramento `Musica`. O laço está ligado no importador do mp3. Uma região pode ter música própria pelo mesmo caminho: o Outpost de Arvo é a primeira (ver `mundo/CLAUDE.md`).

## Telas por cima: opções, créditos e pausa

As três usam `tema_das_telas.tres`: painel de rebites, botão sem caixa e anel só no botão com foco. Passar o mouse clareia o texto, mas não põe anel: com os dois usando o mesmo anel, o botão do teclado e o do mouse pareciam duas escolhas ao mesmo tempo. Cada uma abre por cima de quem a chamou e avisa ao fechar, para o foco voltar ao botão certo.

- **`configuracoes/`** é a tela de opções: volume geral, música e efeitos, tela cheia, escala da janela (2x, 3x, 4x) e a lista de controles, lida do mapa de entrada do projeto. Cada linha (`LinhaDeOpcao`) troca o valor com esquerda e direita, e cada mudança vale na hora e é guardada pelo `ConfiguracoesManager`, sem botão de aplicar.
- **`creditos/`** por enquanto só diz "EM BREVE". **IMPORTANT:** a licença da fonte m6x11plus exige o nome de Daniel Linssen dentro do jogo, e ele precisa voltar a esta tela antes de qualquer versão chegar a jogadores.
- **`pausa/`** abre no Esc, e só quando nenhuma outra tela está na frente: com o mapa ou a tela de regiões abertos, o Esc é deles. Ela para a árvore (`get_tree().paused`) e roda mesmo parada. Voltar ao menu e sair perguntam antes, com o foco no NÃO, porque ainda não há save e o voo de agora se perde.

`tools/pausa_check.tscn` confere a pausa: para o jogo, pergunta antes de sair, abre as opções por cima, retoma de onde parou e não abre com o mapa aberto.

## Órbita

`orbita/` tem duas coisas que são a mesma conversa em dois momentos: o convite que acende quando a nave chega perto de um corpo, e a tela de regiões que a tecla abre. A cena do sistema acende uma e abre a outra; a `Orbita` não decide nada, só mostra e avisa o que o jogador escolheu.

A tela é interface e não mundo, de propósito. Nome de lugar, foco de teclado e clique de mouse são exatamente o que um `Control` já faz bem. As setas funcionam sem ninguém ligar fio nenhum: sem vizinho de foco declarado, o Godot acha o marcador mais próximo na direção apertada, que é a leitura certa quando os marcadores estão espalhados pela carta.

**A tela mostra a carta de superfície, e não o disco do planeta.** O disco visto do espaço, reduzido para caber, virava borrão fora da escala de pixel do jogo; a carta é pixel art na escala certa, vista de cima, com grade de coordenadas a cada 32 px (letras nas colunas, números nas linhas) e um marcador por região. A carta é uma cena da ficha do planeta (`Planeta.carta`), o marcador fica no `ponto_na_carta` da ficha da região, e a tela só põe a carta na moldura e diz o setor da região em foco, como "SETOR H4". Passar o mouse sobre um marcador já é olhar: o painel ao lado responde antes do clique. O marcador e o anel de foco do botão estão em `orbita/art/`; o painel, a moldura de rebites e os cantos de foco servem a mais de uma tela e estão em `art/`. Todos têm a fonte `.pix` em `art/fonte/`, no conjunto `carta` da skill `pixel-art-sprite`.

A tela diz como se sai dela de duas formas, porque uma só não alcança todo mundo: um botão de sair no canto, para quem está no mouse, e uma linha de comandos embaixo, que nomeia as setas, o Enter e o Esc. A tecla de sair continua valendo sozinha, mas quem entrou de mouse não teria como descobrir que ela existe.

O painel de telemetria some enquanto a órbita está aberta e durante a chegada. Ele é telemetria de voo, e ali não há voo do jogador: mostrar a velocidade do piloto automático seria mentir sobre o que ele está fazendo.

## Mapa

`mapa/` abre no `M`, e só no espaço: dentro de uma região não há para onde navegar. Ele mostra onde a nave está e onde os corpos estão, **e nada além disso**. Não traça rota, não estima tempo e não leva ninguém a lugar nenhum: a seção 9 do conceito é explícita em que viagem não se resolve por interface, e um mapa que vira painel de destino tira do voo a única razão de ele existir.

Ele não para o jogo: é para se localizar no meio do voo, então a nave continua andando com o mapa aberto e o marcador dela acompanha, quadro a quadro. Entrar num planeta fecha o mapa, porque ali ele não tem o que dizer. O desenho mora num filho, `QuadroDoMapa`, para o retângulo do mapa ser o quadro das contas de posição em vez da tela inteira.

O tamanho dos corpos no mapa é proporcional ao tamanho deles no sistema: hoje Arvo ocupa um bom pedaço do espaço porque o espaço é pequeno de propósito. **Pixel art não se encolhe**, então cada corpo aparece pela `miniatura` da ficha do planeta, desenhada já na escala do mapa (a de Arvo tem 60 px, os continentes projetados da carta de superfície). Se o espaço ou o quadro do mapa mudarem de tamanho, a miniatura é redesenhada, não reduzida.

O mapa segue a tela de regiões: moldura de rebites, fundo e grade pontilhada da paleta, a nave como um losango com os cantos de foco piscando. Tudo é desenhado em pixel inteiro, e a miniatura perto da borda aparece cortada dos dois lados, como o corpo dá a volta no voo.

## Arte

`art/` aqui serve à categoria inteira, não a uma tela. `painel.png`, `moldura_de_rebites.png` e `foco.png` são pixel art própria, com a fonte em `art/fonte/`, e servem à tela de regiões, ao mapa e ao HUD. Os ícones do HUD estão em `hud/art/icones.png`, uma tira de 8x8 na ordem do enum `Hud.Icone`.

## Texto

Todo texto exibido ao jogador vai virar chave de tradução em `localization/`. Os rótulos de hoje são provisórios e estão escritos direto no script.
