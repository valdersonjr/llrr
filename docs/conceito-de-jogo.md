# Conceito e direção de jogo

**Versão 0.12** · atualizado em 11 de setembro de 2026

Documento vivo: ele muda quando as ideias mudarem. O registro do que mudou fica na seção 20.

Este documento guarda só a concepção do jogo:

- o que ele é;
- o que o jogador faz;
- o que o mundo promete;
- onde ficam os limites de escopo.

Decisões de implementação — ferramentas, formatos, testes e distribuição — ficam nos `CLAUDE.md` de cada pasta, anotadas conforme são tomadas.

As quantidades de conteúdo citadas aqui são hipóteses de escopo, não requisitos aprovados.

Os termos próprios do projeto estão explicados no glossário, na seção 19.

## 1. A ideia central

Um jogo singleplayer de pilotagem e trabalho espacial em 2D, inspirado em Lunar Lander. A herança do Lunar Lander é o voo: empuxo, inércia e descida controlada. Ela não diz nada sobre o que tem no chão.

**A ambientação industrial é da nave e do trabalho, não dos planetas.** Naves usadas, indústria pesada, trabalho sujo: isso descreve quem o jogador é e como ele ganha a vida. Não descreve os lugares onde ele pousa. Cada planeta é livre para ser o que quiser, e um planeta inteiro de doce é tão legítimo quanto um deserto de gelo. O contraste é a graça: um cargueiro encardido descendo num lugar que não tem nada a ver com ele.

O acabamento é pixel art moderna: a referência é o assunto, não a aparência de jogo antigo.

A nave é o personagem principal, e o jogo tem duas vistas da mesma nave:

- **Vista de espaço.** Câmera afastada, sem gravidade e sem chão. É onde o jogador navega entre planetas e outposts, e onde o espaço é grande o bastante para valer a pena olhar.
- **Vista de superfície.** Câmera perto, gravidade do corpo celeste, terreno e plataformas. É onde o pouso acontece.

A troca entre elas é entrar e sair de um planeta. Não é mudança de perspectiva nem de regras de voo: é a mesma nave, com a mesma inércia, vista de outra distância.

O laço central do jogo:

1. Pegar um contrato num outpost.
2. Voar até o planeta que tem o recurso pedido.
3. Entrar no planeta, e a vista trocar.
4. Pousar no ponto de coleta e carregar o porão.
5. Decolar, voltar ao espaço.
6. Entregar no mesmo outpost que emitiu o contrato.

O que o jogo se propõe a entregar:

- Mundo e pilotagem 2D em pixel art moderna.
- Nave controlada diretamente, com inércia, pouso, carga e melhorias.
- Um sistema aberto para explorar, com planetas e outposts que o jogador acha voando.
- Contratos de coleta emitidos por outposts; créditos e progressão.
- Planetas diferentes uns dos outros na física, no recurso e no que eles são.
- Um pouso difícil em cada planeta, pelo que aquele planeta é.

## 2. Princípios de experiência

1. **Pilotagem antes de quantidade de conteúdo.** Uma nave e três plataformas precisam ser divertidas antes de o jogo ganhar a quarta plataforma.
2. **Consequências legíveis.** O jogador entende por que colidiu e por que perdeu carga.
3. **Errar não trava o jogo.** Um pouso ruim devolve o jogador ao voo, não a uma tela de fim.
4. **Profissões compartilham sistemas.** Cada profissão usa os sistemas que já existem, em vez de ganhar mecânica isolada só dela.
5. **Complexidade progressiva.** Calor, tripulação e política entram depois que o jogador aprendeu os controles básicos.
6. **Respeito ao tempo do jogador.** O jogo pausa, salva e nunca exige ficar aberto para progredir.
7. **Explorar é uma recompensa em si.** O jogador acha um planeta voando até ele, não escolhendo um destino numa lista.

## 3. Escopo

Uma ideia boa pode esperar. A tabela separa o que entra na primeira versão do que fica para depois.

| Área | Primeira versão | Expansão posterior |
| --- | --- | --- |
| Universo | Um sistema grande e finito, com planetas e outposts feitos à mão | Mais sistemas, e geração para além do que foi desenhado à mão |
| Vistas | Espaço e superfície, com a mesma nave e a mesma física | Vista de acoplagem e interiores de estação |
| Superfícies | Uma região de pouso por planeta, com o ponto de coleta do recurso dele, e cada planeta com identidade própria | Várias regiões por planeta |
| Planetas | Gravidade, relevo e recurso próprios em cada um | Clima, perigo ambiental e economia local |
| Outposts | Emitem contratos e recebem a entrega deles | Mercado próprio e outros serviços de porto |
| Naves | Três modelos, slots predefinidos, 18–24 módulos e equipamentos | Construção livre peça a peça, grandes frotas |
| Missões | Uma família: coletar um recurso num planeta e entregar no outpost que pediu | Transporte, resgate, interceptação e extração |
| Eventos de coleta | Carregar no ponto de pouso, e extrair esperando no lugar | Mais tipos de evento, e estruturas destrutíveis selecionadas |
| Facções e política | Fora da primeira versão | Facções ativas, reputação e conflito regional |
| Narrativa e tripulação | Fora da primeira versão | Arco autoral e especialistas a bordo |
| Economia | Pagamento por contrato | Mercados com estoque e preço variável |

Os corpos do sistema são ficcionais. Isso permite ajustar as condições deles à diversão, sem prometer fidelidade a planetas reais.

### 3.1 Fora da primeira versão

- Multiplayer.
- Física gravitacional de muitos corpos.
- Cidades caminháveis.
- Combate, de qualquer tipo. Não há armas, inimigos nem naves hostis.
- Frota administrável.
- Terreno integralmente destrutível.
- Geração procedural de planetas.

### 3.2 A primeira experiência completa

Um trecho curto de 30–45 minutos que reúne as partes essenciais do jogo, com um outpost e dois planetas:

1. Ler o quadro de contratos de um outpost e aceitar uma coleta.
2. Decolar e sair para a vista de espaço.
3. Achar, voando, o planeta que tem o recurso pedido.
4. Entrar no planeta e ver a vista trocar para a superfície.
5. Pousar no ponto de coleta e encher o porão.
6. Decolar carregado, e sentir a massa mudar como a nave voa.
7. Voltar ao mesmo outpost e entregar o contrato.
8. Fechar e reabrir o jogo, retomando de onde parou.

Essa sequência valida o laço central. Se ela não funcionar, o próximo passo é revisar controles, pouso e a leitura do espaço, não multiplicar planetas.

## 4. Pilotagem

**Inércia e massa**

- A nave tem inércia.
- A massa altera a aceleração sob o mesmo empuxo.
- Carga pesa e é sentida no controle, não apenas anunciada num número.

**Voar não custa recurso**

Não existe combustível, e não existe dano. O empuxo está sempre disponível, e bater a nave não tira nada dela.

Hoje um pouso ruim não tem consequência nenhuma. Isso é a maior decisão em aberto do projeto, e está registrada na seção 18. Nada neste documento deve assumir tanque, autonomia, integridade de casco ou nave destruída.

**Propulsão**

- O propulsor principal empurra no eixo da nave.
- Os propulsores de manobra produzem translação e giro.

**Estabilização angular**

Existe desde o início, como acessibilidade.

- Respeita os limites da nave e não custa nada ao jogador.
- Upgrades ampliam a autoridade angular.
- O jogo nunca cobra créditos para corrigir um controle frustrante.
- O piloto automático barato funciona. Ele não recebe falhas aleatórias como substituto de dificuldade bem desenhada.

**Pouso é um estado, não um único evento de colisão**

Entram na avaliação:

- velocidade relativa à plataforma;
- ângulo de impacto;
- inclinação e giro;
- contato das pernas;
- tempo estável.

Essas medidas são o que define um pouso bom, e o HUD acende em laranja o que está fora do limite. O que elas **não** fazem, hoje, é produzir consequência: a nave assenta de qualquer jeito, porque não existe dano. Pousar sobre plataforma móvel considera o movimento dela.

**Sinais de que a pilotagem está certa**

- Parada no chão, a nave não se move sozinha.
- Desligar os motores no vácuo não freia.
- Peso extra reduz a aceleração.
- A estabilização zera o giro sozinha.

## 5. Nave, equipamentos e progressão

**Modelos e módulos**

- Cada modelo define slots, silhueta e limite de carga.
- Cada módulo tem massa e capacidades.
- A nave é a soma do que está instalado.

Slots previstos: motor principal, controle de manobra, compartimento de carga, utilidade e sensor. Nem todo modelo tem a mesma combinação. Encaixe espacial livre, fiação e tubulação individuais ficam fora.

**Progressão horizontal**

Três papéis de modelo: utilitário leve, cargueiro resistente e interceptador. Todo equipamento cobra o seu preço em massa, energia ou espaço. Não existe upgrade que só melhore.

**Ordem em que os recursos entram no jogo**

1. Carga.
2. Energia e calor, só quando um evento de coleta criar uma decisão real.

A primeira missão nunca mostra seis barras sem função perceptível.

**Não existe dano**

A nave não tem integridade, casco degradado nem estado destruído. Nenhum impacto tira nada dela, nenhum módulo quebra, e não há como perder a nave.

Isso vale para tudo que o jogo desenhar: nada de sprite de casco amassado, barra de estrutura, alerta de casco crítico ou efeito de destruição. Consequência de pouso ruim é a primeira pergunta em aberto da seção 18.

## 6. Controles, câmera e legibilidade

**Controles**

- Teclado e controle levam ao mesmo conjunto de ações: intensidade do propulsor, rotação, translação lateral e comandos.
- Os comandos de voo são os mesmos nas duas vistas. Trocar de vista não pede aprender outro controle.

**As duas câmeras**

| Vista | Distância | O que precisa caber na tela |
| --- | --- | --- |
| Superfície | Perto | A nave, o ponto de pouso e o terreno em volta dele |
| Espaço | Longe | A nave, os planetas próximos e para onde ela está indo |

- Cada vista antecipa o movimento com moderação, dentro do que a distância dela permite.
- A troca entre as vistas é um movimento contínuo de câmera, não um corte seco nem uma tela de carregamento anunciada.
- A nave nunca some da tela. Na vista de espaço ela é pequena, mas continua legível.
- Nenhuma ação essencial depende de passar o mouse por cima.

**Pausa e dispositivos**

- Menus de administração e pausa param o tempo. Inspecionar a situação com o jogo pausado não é punido.
- Trocar de dispositivo, desconectar o controle ou voltar de uma suspensão nunca deixa o propulsor travado ligado.

## 7. Mundo: sistema, planetas e permanência

**O sistema**

Um espaço contínuo e finito, grande o bastante para dar sensação de mundo aberto, com planetas e outposts colocados à mão. O jogador chega em qualquer um deles voando: não existe tela de seleção de destino.

Finito é uma decisão de produção, não de ambição. Planetas feitos à mão são a única forma barata de garantir que dois planetas não sejam o mesmo planeta repintado. Geração procedural fica na coluna de expansão da seção 3, e só entra quando houver receita provada de variedade.

**Composição de um planeta**

Um planeta é um conjunto de condições físicas, mais o recurso que ele oferece, mais uma identidade que não se repete:

- gravidade própria, que muda o pouso;
- relevo próprio, que muda a aproximação;
- um recurso, que é o motivo de ir até lá;
- uma região de pouso, com o ponto de coleta desse recurso;
- um assunto próprio, que é o que o jogador vai lembrar do lugar.

**Nenhum planeta se parece com o anterior.** A mecânica é sempre a mesma, descer inteiro num lugar demarcado, e é exatamente por ela ser constante que o lugar pode ser qualquer coisa. Um deserto de gelo, uma refinaria abandonada, uma floresta de cogumelo gigante, um planeta inteiro de doce. Não existe lista de biomas permitidos e este documento não vai criar uma. Surreal é permitido. O que o planeta precisa provar é que pousar nele não é igual a pousar nos outros.

Um planeta tem um objetivo só: pousar no ponto de coleta. A variedade nunca vem de acumular tarefas na superfície. Ela vem da gravidade, do relevo, do que o contrato pede e do que o lugar é.

**Um planeta pode ter vida, e ela é cenário.** Bicho, planta e clima não são objetivo nem inimigo, e não entram no save. Eles existem para o planeta ser um lugar, e saem na frente de qualquer coisa que atrapalhe achar o ponto de coleta.

**Outposts**

Um outpost fica no espaço e é um destino como qualquer outro: o jogador voa até ele, entra, e a vista troca do mesmo jeito que troca ao entrar num planeta. Lá dentro existe um lugar de pouso demarcado, e pousar nele é o que dá acesso ao outpost. Não existe manobra de acoplagem: acoplar seria um controle novo, e o pouso já resolve.

O que um outpost faz:

- emite contratos;
- recebe a entrega dos contratos que ele próprio emitiu.

Um contrato pertence ao outpost que o emitiu. Levar a carga para outro outpost não entrega nada. É isso que transforma cada contrato numa viagem de ida e volta e dá função ao mapa.

**Perspectiva**

A pilotagem acontece sempre com a mesma nave vista de perfil, em 2D, nas duas vistas. As superfícies são regiões locais: o jogador não precisa dar a volta física num planeta.

**O que se faz num planeta** está na seção 10: pousar no lugar demarcado, que é a parte difícil, e executar ali o evento que o contrato pede.

## 8. O mundo que continua

**Não existe relógio de campanha.** O jogo não conta dias nem horas, nada é medido em tempo de mundo, e nada avança sozinho. O único tempo que o jogo conhece é o da cena que está rodando, e ele para quando o jogo pausa.

Nenhum sistema deve consultar, exibir ou cobrar tempo de campanha. Contrato e evento de coleta se descrevem pelo que fazem, não por quanto demoram no calendário.

**O mundo lembra**

O que continua depois que o jogador sai de um lugar e volta:

- ponto de coleta esgotado;
- carga deixada para trás;
- contrato aceito, entregue ou fracassado;
- créditos.

Destroços decorativos somem sozinhos. Carga recuperável e o que um contrato produziu ficam, mesmo com o cenário cheio.

Isso é estado salvo, não simulação. O jogo guarda o que já aconteceu; ele não faz o mundo acontecer sozinho enquanto o jogador está em outro lugar, e muito menos com o jogo fechado.

## 9. O espaço

**Como se viaja**

O espaço é voado, não planejado. A nave sai da superfície, a vista troca e o jogador segue pilotando com os mesmos comandos, agora sem gravidade e com a câmera afastada.

- Não existe tela de planejamento de rota, nem escolha entre rota econômica, rápida e clandestina.
- Não existe cálculo de autonomia, reserva de chegada ou custo de partida.
- Não existe viagem resolvida por interface: se o jogador foi de um lugar a outro, ele voou até lá.

**Escala**

A distância entre corpos precisa ser grande o bastante para o espaço parecer espaço, e curta o bastante para a viagem não virar espera. Esse é um número de calibração, e ele se decide voando, não no papel.

**Partida e chegada**

- A decolagem começa manualmente na região e continua sem corte até a vista de espaço.
- A aproximação de um planeta traz a vista de volta para a superfície, na região de pouso dele.
- Cruzar a borda da tela não é nada: sair de um planeta é ganhar altitude de verdade.

## 10. O pouso é o desafio

Todo planeta pede a mesma coisa: descer inteiro num lugar demarcado. O que muda de planeta para planeta é o lugar em si, e o que nele torna essa descida difícil.

**De onde vem a dificuldade**

- A gravidade do corpo, que muda quanto empuxo o pouso exige e quanto tempo o jogador tem para corrigir.
- O relevo entre a entrada e o ponto de coleta: cristas, desfiladeiros e paredes.
- Objetos soltos na descida, como asteroides e destroços.
- O tamanho, a forma e a inclinação do lugar de pouso.

A dificuldade vem daí. Ela nunca vem de acumular tarefas na superfície: cada planeta continua tendo um objetivo só.

**O evento no ponto de coleta**

Pousado, o jogador executa o evento que aquele contrato pede. Dois para começar:

| Evento | O que o jogador faz | O que ele custa |
| --- | --- | --- |
| Carregar | A carga já está no lugar. Pousar e embarcar. | Nada além do pouso |
| Extrair | A nave fica parada enquanto o recurso sai do solo. | A espera, informada antes de começar |

Outros eventos entram como variações desse par, e cada um novo precisa justificar por que não é um dos dois. O formato não muda: pousar é a parte difícil, e o evento é o que dá sentido a ter pousado ali.

**O lugar de pouso é sempre demarcado, e nem sempre é uma plataforma**

O jogador precisa saber onde descer antes de começar a descer. Um pouso que só revela o alvo no último segundo não é difícil, é injusto.

A demarcação é conteúdo visual autoral, feito para cada situação, não um marcador de interface genérico colado por cima da cena. Uma plataforma iluminada serve num outpost; uma boca de mina, um anel de balizas, uma clareira queimada ou um pátio de carga servem em outros lugares. É trabalho de arte, e vale gastar nele: é a primeira coisa que o jogador procura na tela ao entrar num planeta.

Duas regras para qualquer demarcação:

- **Legível de longe.** Ela tem que se separar do terreno pela silhueta e pela luz, na altura em que o jogador ainda pode corrigir a descida.
- **Diz mais que "aqui".** Tamanho e orientação fazem parte da informação. Cor sozinha nunca basta.

## 11. Contratos

**A família inicial é uma só: coleta.**

Um contrato diz qual recurso, quanto, e de qual planeta. Ele é emitido por um outpost e só é pago por esse mesmo outpost.

Cada contrato tem contratante, recurso, quantidade, evento de coleta, progresso e desfecho. Concluir a coleta é diferente de receber o pagamento: o pagamento acontece na entrega.

**Contratos gerados obedecem a restrições, não a sorteio livre:**

- o planeta pedido existe e é alcançável;
- o recurso pedido existe naquele planeta;
- a quantidade cabe no porão do jogador, ou o contrato diz claramente que exige mais de uma viagem;
- a oferta combina com o nível do jogador, ou está claramente marcada como difícil;
- a recompensa cobre a distância e a dificuldade do pouso.

Ofertas expiram. O quadro de contratos não reserva o mundo inteiro para propostas que ninguém aceitou.

**Contratos não têm prazo por enquanto.** Nada expira na mão do jogador depois de aceito. Prazo é uma pressão de tempo, e a seção 18 ainda não decidiu se o jogo quer uma.

**Contratos reagem ao mundo.** O ponto de coleta pode se esgotar e a carga pode ser perdida. Cada caso tem política definida: falha, compensação, novo destino ou cancelamento. Nenhum contrato fica eternamente ativo com objetivo impossível e sem explicação.

**Autoral primeiro, procedural depois.** A família de coleta ganha exemplos escritos à mão antes de virar variação gerada.

## 12. Economia

**De onde vem o dinheiro**

Contrato entregue é a fonte de renda do jogo. Lucro por viagem é o jogo funcionando; crédito criado por inconsistência é bug. Toda entrada e saída de crédito é declarada: contratos e módulos.

**Recursos**

Cada planeta oferece recursos próprios, com massa e valor. É a massa que conecta economia e pilotagem: aceitar um contrato grande é aceitar decolar pesado.

**Mercado com estoque e preço variável fica para depois.** Enquanto ele não existir, o pagamento de um contrato é o valor acordado no momento em que ele foi aceito.

Contratos de recuperação podem ter subsídio deliberado, para impedir que o jogador trave sem dinheiro. Esse subsídio é regra de design registrada, não torneira acidental.

## 13. Facções e tripulação

**Fora da primeira versão.** Reputação, conflito regional, troca de governo e especialistas a bordo ficam na coluna de expansão da seção 3.

O que existe agora é a relação com o outpost: ele emite trabalho e recebe entrega. Nada mais depende de facção.

Quando facções entrarem, elas entram pelos sistemas que já existem — quais contratos aparecem em qual outpost, e quem está presente onde. Nenhuma facção ganha economia paralela só dela.

**Toda mudança observável precisa ser explicada:** um contrato que sumiu, um depósito exaurido, uma bandeira trocada. Mexer só em números ocultos não produz sensação de mundo vivo.

## 14. Direção visual e sonora

**Pixel art moderna**

Pixel art aqui é meio de expressão, não emulação de hardware antigo. Nada de CRT, scanline ou ruído de tubo: o jogo não finge ser de outra época.

- Paleta rica, com rampas longas e deslocamento de matiz. A sombra recebe a cor do ambiente; escurecer a mesma matiz produz rampa morta.
- Luz declarada: uma luz principal, preenchimento de ambiente e luz de borda onde a forma precisa se separar do fundo.
- O que emite luz — motor, cabine, painéis, alertas — derrama luz no que está por perto.
- Atmosfera é trabalho do motor, não do sprite: brilho nos emissivos, luzes 2D, camadas de profundidade e partículas. O desenho continua nítido; o clima vem da cena.
- A interface fica em camada própria e escalável, para não sacrificar texto econômico em tela pequena.
- O filtro de pixelização é separado do que o jogo considera colisão. Nenhuma escolha estética deixa o casco tremido ou o contato impreciso.

**As duas vistas precisam do mesmo cuidado.** A vista de espaço não é a de superfície com zoom para fora: ela tem o seu próprio inventário de arte, e um planeta visto de longe precisa ser reconhecível pela silhueta e pela paleta.

**Identificação**

- Assunto e paleta próprios por planeta, e uma silhueta distinta por modelo de nave. Dois corpos nunca se leem igual de longe.
- Cada lugar de pouso é desenhado à mão para o lugar em que está, e se lê de longe pela silhueta e pela luz (seção 10).
- Cor sozinha nunca distingue o lugar de pouso, o perigo e o cenário.
- Arte final não é pré-requisito para provar que a pilotagem e o pouso funcionam.

**Som**

O que importa é o sinal útil: aproximação do limite de pouso, contato das pernas, motor ligado e desligado, assentamento do trem de pouso. A música nunca esconde um alerta. Nada de alerta de casco crítico: não existe dano (seção 5).

**Idiomas**

Os textos são preparados para inglês e português brasileiro.

## 15. Promessas ao jogador

- Pausar e salvar sem perder progresso, com o jogo informando com clareza onde é possível salvar em cada fase do desenvolvimento.
- Todo desfecho ruim tem causa compreensível.
- Nenhum contrato fica pendurado para sempre sem objetivo possível.
- Um pouso pode ser difícil, mas o jogador sempre enxerga onde descer a tempo de corrigir.
- Assistência de controle é acessibilidade, não item de loja.
- Voar até um lugar é sempre possível. O jogo não tranca um destino atrás de um recurso que o jogador não tem.

## 16. Quando parar e revisar o design

- Se o pouso continuar imprevisível, suspender conteúdo e revisar a pilotagem e a assistência.
- Se a vista de espaço virar espera, encurtar as distâncias antes de acrescentar planetas.
- Se dois planetas jogarem igual, revisar gravidade, relevo e recurso antes de desenhar o terceiro.
- Se voar sem custo nenhum deixar o voo sem decisão, resolver a seção 18 antes de acrescentar conteúdo.
- Se o jogador não achar o lugar de pouso ao entrar num planeta, é a demarcação que está errada, não a habilidade dele.
- Se atmosfera ou efeito visual prejudicarem a leitura, cortar o efeito antes de mexer no resto.

## 17. Riscos do produto

| Risco | Sinal antecipado | Resposta prevista |
| --- | --- | --- |
| Escopo maior que a capacidade | Ciclos terminam sem nada jogável | Cortar quantidade de conteúdo e adiar sistemas da coluna de expansão |
| Voo sem decisão | O jogador segura o acelerador do começo ao fim sem pensar | Resolver a seção 18: dar um preço a voar |
| Espaço vazio | A viagem entre planetas é tempo morto | Encurtar distâncias, ou dar ao trecho coisas para achar |
| Planetas intercambiáveis | Trocar de planeta não muda como se pousa | Diferenciar por gravidade e relevo, e não só por arte: dois planetas com a mesma física são o mesmo planeta repintado |
| Sobrecarga de controles | O jogador luta com a interface durante o pouso | Assistência básica, pausa e redistribuição de ações |
| Lugar de pouso ilegível | O jogador desce, não acha onde pousar e sobe de novo | Tratar a demarcação como arte autoral por lugar, e testar de longe |
| Arte final atrasada | Placeholder chega ao acabamento | Definir o inventário e o orçamento de arte depois da primeira experiência completa |

## 18. Perguntas em aberto

- **O que acontece quando o jogador pousa mal.** Esta é a pergunta central do projeto agora. Combustível, combate, prazo, reparo e dano foram todos removidos, e não sobrou nenhuma consequência: a nave desce rápido demais, torta, e simplesmente assenta. Pilotar bem não é recompensado e pilotar mal não é punido. Nada de conteúdo novo compensa isso, e nenhum planeta a mais vai tornar o pouso interessante enquanto ele não custar nada.
- Quantos planetas e outposts o sistema tem, e que distância há entre eles.
- Se o jogo quer prazo em contrato. Hoje não tem, e prazo dependeria de reintroduzir alguma medida de tempo, que a seção 8 descarta.
- Que outros eventos de coleta existem além de carregar e extrair.
- Se um outpost pode existir também na superfície de um planeta. Hoje todos ficam no espaço.
- Como o jogador acha um planeta que nunca visitou: instrumento a bordo, informação comprada no outpost, ou só olhar.
- Nome e ambientação final.
- O que costura planetas radicalmente diferentes num jogo só: o acabamento, a luz, a nave, ou alguma regra de paleta que todos respeitem.
- Duração comercial pretendida.
- Existência de um modo com perda permanente.
- Qual sensação de voo o jogo quer exatamente. Essa decisão só faz sentido diante de um protótipo, não de uma descrição.

**Em resumo:** preservar a ambição na interação entre os sistemas, controlar o escopo pela quantidade de planetas e de eventos, e tratar cada fracasso do jogador como o começo de uma situação nova.

## 19. Glossário

| Termo | Significado |
| --- | --- |
| **Vista de espaço** | Câmera afastada, sem gravidade e sem terreno. Onde se navega entre planetas e outposts. |
| **Vista de superfície** | Câmera perto, com gravidade e terreno. Onde se pousa. |
| **Outpost** | Lugar de trabalho que emite contratos e recebe a entrega dos contratos que emitiu. |
| **Contrato** | Pedido de coleta emitido por um outpost. Só é pago pelo outpost que o emitiu. |
| **Região** | Área local visitável de um planeta, com terreno, plataformas e o ponto de coleta. O jogo não representa o planeta inteiro. |
| **Ponto de coleta** | O lugar demarcado da região onde a nave pousa para executar o evento do contrato. Nem sempre é uma plataforma. |
| **Evento de coleta** | O que o jogador faz depois de pousar: carregar o que já está lá, ou esperar enquanto o recurso é extraído. |
| **Modelo** | O chassi da nave. Define slots, silhueta e limite de carga. Os três são utilitário leve, cargueiro resistente e interceptador. |
| **Slot** | Encaixe fixo do modelo que aceita um tipo de módulo. |
| **Módulo** | Peça instalável num slot, com massa e capacidades. |
| **Progressão horizontal** | Evolução por troca de papel e de compromisso, não por números sempre maiores. Todo equipamento cobra preço em massa, energia ou espaço. |
| **Primeira experiência completa** | O trecho de 30–45 minutos da seção 3.2, que exercita todos os sistemas essenciais de ponta a ponta. |

## 20. Histórico de versões

| Versão | Data | O que mudou |
| --- | --- | --- |
| 0.12 | 2026-09-11 | **Cada planeta passou a ser um assunto próprio, e surreal é permitido.** A ambientação industrial foi devolvida a quem ela descreve, a nave e o trabalho, e deixou de valer para os lugares onde se pousa: um planeta de doce é tão legítimo quanto um deserto de gelo. Identidade entrou na composição de um planeta na seção 7, junto com a permissão explícita de ter vida, que é cenário e não objetivo. A seção 17 parou de tratar arte como diferenciação de segunda, e a seção 18 trocou a pergunta sobre clima visual dominante pela pergunta de o que costura planetas muito diferentes num jogo só. |
| 0.11 | 2026-09-11 | **"Lunar" saiu do título.** A herança do Lunar Lander passou a ser declarada como o voo, e não como o cenário: nenhum corpo celeste precisa ser cinza e sem vida, e relevo, paleta e vegetação continuam abertos por planeta. Nenhuma decisão de design mudou. O documento só parou de sugerir uma ambientação que a seção 18 diz não estar escolhida. |
| 0.10 | 2026-09-09 | **O painel de telemetria voltou ao HUD**, agora só como moldura atrás dos números — a versão 0.9 tinha tirado o painel inteiro junto com a barra de estrutura. A barra continua fora, e continua não existindo grandeza contínua para uma barra mostrar. |
| 0.9 | 2026-09-09 | **Dano foi removido do jogo.** A nave não tem mais integridade, estado de casco, sinal de impacto nem estado destruído; o casco tem uma textura só, a barra de estrutura saiu do HUD junto com o painel inteiro, e os módulos deixaram de ter integridade. Com isso o jogo ficou sem nenhuma consequência para pousar mal: combustível, combate, prazo, reparo e dano saíram todos, e a seção 18 passou a ter uma pergunta central em vez de várias. |
| 0.8 | 2026-09-09 | **Reparo foi removido do jogo.** Nenhum outpost conserta a nave, nenhum módulo é substituído, e a subseção "Saída da espiral de pobreza" saiu junto porque dependia dele. O dano passa a ser permanente na campanha, e a promessa da seção 15 de que fracassar não é o fim foi retirada até que a seção 18 decida entre devolver alguma forma de recuperação ou tratar a perda da nave como um desfecho com continuação própria. |
| 0.7 | 2026-09-09 | **O relógio de campanha foi removido do jogo.** Não há mais dias, horas nem tempo de mundo, e nada avança sozinho. A antiga seção 8, "Tempo e o mundo que continua", virou "O mundo que continua" e passa a tratar só de permanência e estado salvo, herdando o bloco "O mundo lembra" da seção 7. Serviço de outpost e evento de extração deixaram de ser cobrados em tempo de campanha. Com isso o dano do pouso ficou sem preço nenhum, e essa passou a ser a primeira pergunta em aberto da seção 18. |
| 0.6 | 2026-09-09 | **Combate saiu do jogo inteiro**, e com ele armas, inimigos, mira, rendição, abordagem e as menções em arte, som, riscos e glossário. A antiga seção 10 foi substituída por "O pouso é o desafio", que é o que ficou no lugar: cada planeta é difícil pela gravidade, pelo relevo e pelos obstáculos da descida, e o ponto de coleta é sempre um lugar de pouso demarcado, nem sempre uma plataforma. Coletar passou a depender do contrato, entre carregar e extrair esperando no lugar; o laser de mineração saiu. Outposts ficam no espaço e se entra neles pousando, sem manobra de acoplagem. Contrato não tem mais prazo. |
| 0.5 | 2026-09-09 | Mundo aberto. O jogo passa a ter duas vistas da mesma nave, espaço e superfície, e o espaço é voado em vez de planejado numa tela de rota. Contratos passam a ser emitidos por outposts e pagos só pelo outpost que os emitiu, e a família inicial de missão é uma só: coleta de recurso. Cada planeta tem um objetivo único, pousar no ponto de coleta. **Combustível foi removido do jogo**, e nada ocupou o lugar dele ainda — a pergunta está registrada na seção 18. Saíram deste documento: planejamento de rota, reserva de chegada, mercados com estoque, facções, tripulação e o arco narrativo do prisioneiro, todos movidos para a coluna de expansão ou apagados. |
| 0.4 | 2026-09-09 | Removida a referência a uma década específica. A ambientação passa a ser descrita pelo que ela é — ficção científica industrial, naves usadas, indústria pesada, trabalho sujo — sem ancorar o mundo num período do cinema. |
| 0.3 | 2026-09-09 | Direção de arte trocada de estética retrô para pixel art moderna, com luz, emissivos e atmosfera declarados. CRT e scanline saíram. |
| 0.2 | 2026-09-06 | Reescrita para linguagem direta: parágrafos longos viraram listas, voz padronizada em "o jogador", glossário e histórico adicionados. Nenhuma decisão de design mudou. |
| 0.1 | 2026-09-06 | Primeira versão do conceito. |
