# Regras de produção

Cada regra diz o que fazer e por quê. O script pega o que é mecânico; o resto só a sua inspeção pega.

## 1. Forma

**Silhueta primeiro.** Desenhe a mancha chapada antes de qualquer cor. Se a silhueta não diz o que é, luz nenhuma salva. A inspeção tem um bloco de silhueta para isso.

**Formas primárias grandes, detalhe pequeno e pouco.** Um arbusto é três ou quatro lóbulos, não cem folhas. O olho lê massa; detalhe sem massa por baixo vira ruído.

**Proporção de peça que se combina.** Uma pedra de 16 px ao lado de um tile de 16 px e de uma nave de 29 px precisa parecer do mesmo mundo. Confira contra a tabela de escala do `SKILL.md`.

**Base de apoio plana e explícita.** O que fica no chão tem a última linha reta ou quase, para assentar sobre qualquer topo de terreno.

## 2. Luz e volume

**Uma luz principal, declarada no cabeçalho.** Padrão `cima_esquerda`. Todas as peças de um conjunto usam a mesma, senão a composição fica incoerente.

**Três planos por massa:** iluminado, base, sombra. Um quarto tom (realce ou oclusão) só onde a forma pede. A fronteira entre luz e sombra (o terminador) segue o volume: curva num objeto redondo, reta e dura numa aresta.

**Oclusão onde as massas se tocam.** Onde um lóbulo passa por trás de outro, onde o objeto encosta no chão: o tom mais escuro da rampa, em cluster fino.

**Luz de retorno opcional e fraca.** Um tom acima da sombra na borda do lado escuro separa a forma do fundo escuro. Nunca mais clara que a base.

**Sem pillow shading.** Pillow shading é escurecer em anéis do contorno para dentro, ignorando a luz. Parece travesseiro e denuncia amador na hora. A sombra fica do lado oposto à luz.

**Valores antes de matiz.** No bloco de valores em cinza da inspeção, as três faixas precisam se separar. Se o cinza sai chapado, o contraste é insuficiente, não importa como as cores parecem.

## 3. Cor

**Rampas da Resurrect 64, com deslocamento de matiz.** Andar na rampa escurece e desloca a matiz. Na ponta escura, troque para uma rampa mais fria ou roxa (`roxos:0`, `neutros_quentes:0/1`, `azuis:0`); na ponta clara, para uma mais quente ou amarela (`olivas:4`, `verdes:4`). Isso é o que dá cor viva em vez de suja.

**Poucas cores, bem escolhidas.** 16x16: 5–8. 32x32: 8–14. 64x64: até ~20. Cada cor tem papel declarado na paleta do `.pix`. Cor sem papel sai.

**Contraste com propósito.** O ponto mais claro e o mais escuro vão onde o olho deve ir: a borda iluminada, o detalhe que identifica a peça.

**Cor sozinha nunca distingue função** (conceito do llrr, seção 14): perigo, ponto de pouso e cenário se separam por forma também.

## 4. Contorno

**Seletivo, não uniforme.** Lado da sombra e base: escuro (`#2e222f` ou o tom 0 da rampa do material). Lado da luz: sem contorno, ou um tom escuro da própria rampa. Contorno preto em volta de tudo achata o volume.

**Contorno interno só onde separa massas.** Uma linha escura entre dois lóbulos, não em cada folha.

**Peça fina (≤3 px) sem contorno.** A borda comeria a peça. A rampa separa a forma sozinha.

**Leia nos três fundos.** A inspeção mostra fundo escuro, médio e claro: se a peça some em algum, ajuste o contorno do lado que sumiu.

## 5. Pixels

**Clusters.** Cada cor forma manchas com forma legível. Pixel isolado (órfão) só como realce intencional: brilho de metal, ponta de folha. O script avisa acima de ~6%.

**Linhas limpas (sem jaggies).** Diagonais em degraus regulares: 1-1-1, 2-2-2, ou alternância estável 2-1-2-1. Nunca 1-3-1-2. Curvas: degraus que crescem ou diminuem monotonicamente (1-1-2-3), sem voltar.

**Sem banding.** Duas faixas de tom paralelas acompanhando exatamente o contorno ou uma à outra, com a mesma largura, achatam a forma. Varie a largura e quebre o paralelismo.

**Sem antialiasing automático.** AA manual é permitido só dentro da forma, entre dois tons, com um pixel de tom intermediário da própria rampa. Nunca no contorno externo, porque a transparência não aceita meio-tom.

**Dither com parcimônia.** Só para transição entre dois materiais em área grande (≥32 px) ou textura específica (areia, metal escovado), em padrão regular. Nunca para compensar falta de cor. O script avisa acima de ~8% de xadrez.

**Detalhe que sobrevive a 2x.** O jogo mostra a 2x. Se o detalhe só funciona a 10x, ele sai.

## 6. Peças que se combinam

**`encaixe` diz a verdade.** Borda declarada encosta em outra peça; borda não declarada tem ar em volta.

**Tile emenda sem costura.** A última coluna precisa continuar a primeira. Use `--repeticao` e olhe: grade visível é defeito. O script mede e avisa a partir de 2x o interior.

**Variação de tile mantém bordas.** Duas variações do mesmo tile mudam o miolo e mantêm as bordas de encaixe iguais, para trocar uma pela outra sem emenda.

**Mesma luz, mesmas rampas, mesmo contorno** entre peças de um conjunto. Antes de desenhar a segunda peça, abra o `.pix` da primeira e copie o bloco de paleta.

**Sem elementos de composição.** Nada de chão desenhado sob o objeto, nada de sombra projetada solta, nada de fundo. A composição acontece no motor, com luz 2D e camadas.

## 6b. Coesão de conjunto

Estas regras vieram de uma revisão real: tile e arbusto que pareciam bons ampliados ficaram ruins lado a lado.

**Uma regra de contorno para todas as camadas.** Se o cenário tem contorno escuro e o terreno não, parecem de jogos diferentes. A regra mora no arquivo do conjunto.

**Mesma granulação.** Terreno com detalhe de 1 px e planta com manchas de 4 px não convivem. Fixe o tamanho de cluster no conjunto.

**Camadas separadas por valor, não só por cor.** Terreno, cenário e lugar de pouso têm faixas de luminância que não se sobrepõem. Em cinza, cada camada precisa se separar da vizinha.

**Realce raro.** O tom mais claro de uma rampa aparece em pontos, nunca em linha contínua. Uma borda inteira em `verdes:4` vira listra e rouba o olho.

**Oclusão em todo contato.** Onde a peça encosta no chão ou em outra massa, o tom de oclusão do conjunto. Sem ele, a peça flutua.

**Variação de tamanho.** Três lóbulos iguais são uma bolha; grande, médio e pequeno são uma planta. Tufos da mesma altura e espaçamento são um pente.

**Linha de colisão sagrada.** A borda de cima do tile é a coisa mais clara do terreno. O que passa acima dela (peça de borda com `acima:`) é mais escuro e fino.

**Repetição quebrada por variação.** Todo tile que repete em linha tem pelo menos duas variações com as mesmas colunas de borda, e só uma leva detalhe marcante.

## 6c. Rocha, penhasco, montanha e céu

Aprendido em tutoriais (Slynyrd Pixelblog 13, 28, 43 e 62; tutoriais de rocha do deserto e de pedras grandes no fórum do itch.io) depois de cinco tentativas ruins. As tentativas falharam por sombrear pixel a pixel pela distância da borda, desenhar rachadura como símbolo repetido e texturizar com grade de blocos.

**Rocha se constrói por planos, não por pixel.** Contorno geral → quebrar em muitos planos angulares → um tom chapado por plano → sombra e realce por plano → poucas rachaduras e marcas → tirar ou suavizar o contorno para integrar ao ambiente.

**Mesa e morro de deserto.** Silhueta de cone chanfrado: topo plano, mais larga embaixo. Luz de cima deixa o topo como o plano mais claro. A face é feita de lajes verticais e placas de saliência em forma de lente sobrepostas; a base se abre como saia de blocos caídos. Reentrâncias grandes e escuras separam as lajes. Fio de realce de 1 px na borda de cima de cada placa (sol a 45° arredonda a aresta). Rachaduras curtas, na direção das lajes. Rocha um pouco mais vermelha que a areia.

**Tons.** Cinco bastam: fio de realce, plano de luz, plano médio, plano de sombra, reentrância funda. Textura sutil, senão vira bagunça. Sombra desloca para frio ou roxo.

**Pedra.** Oclusão na base, na pedra e no chão. Arestas chanfradas, nunca faces totalmente retas.

**Montanha.** Silhueta em tom médio → linhas de crista ramificadas → um lado de cada crista na luz e o outro na sombra.

**Profundidade (perspectiva atmosférica).** O plano mais próximo é o mais saturado e o de maior contraste. A cada plano para trás, cai a saturação, sobe a claridade e a matiz vai para a cor do céu. Na base das montanhas distantes, uma faixa de névoa. Detalhe diminui com a distância: nada de textura individual no plano do fundo.

**Céu.** Faixas horizontais de cor. As nuvens próximas têm mais contraste e detalhe; as distantes se fundem ao céu.

**Areia.** Clusters longos e inclinados em forma de S e C, com irregularidade para não virar macarrão. Tile repete nos quatro lados sem costura.

**Clareza.** Cada pixel precisa dizer o que é. Clusters simples e consistentes valem mais que detalhe forçado.

## 7. O que o script valida

| Verificação | Resultado |
|---|---|
| largura ou altura fora de 1..64 | erro |
| `tamanho:` diferente do desenho, linhas desiguais | erro |
| tipo fora da lista, nome/tipo de cena | erro |
| cor fora da Resurrect 64, alfa parcial | erro |
| não-tile com borda inteira opaca sem `encaixe` | erro |
| não-tile retângulo cheio ≥32x32 | erro |
| `folha` sem `--explicita` ou quadros desiguais | erro |
| cores acima do teto do tamanho | aviso |
| pixels órfãos > ~6% | aviso |
| xadrez de dither > ~8% | aviso |
| margem transparente ≥4 px sobrando | aviso |
| emenda de encaixe ≥2x o interior | aviso |
| cor declarada e não usada, pasta diferente do tipo | aviso |

Silhueta, luz, pillow shading, banding, jaggies e leitura a 2x **não** são mecânicos: são a sua revisão da inspeção.
