# Receita de cenário

O padrão que fez o Outpost de Arvo (faroeste) dar certo, escrito para repetir em qualquer lugar novo, com qualquer assunto: doce, gelo, ruína, cogumelo, cidade. **O assunto muda; o processo e a técnica não.** O Outpost é o exemplo de referência: `mundo/planetas/arvo/regioes/outpost/`.

## 1. Antes do primeiro pixel

1. **História em três frases.** O que é o lugar, o que aconteceu ali e o que se faz ali. No faroeste: posto de fronteira no deserto, saloon onde se pega contrato, deque de pouso sobre palafitas.
2. **Referência visual escolhida pelo usuário.** Peça uma imagem que ele goste. Use só para estudar técnica, material e paleta; imagem de banco não se copia. No faroeste, o saloon de referência destravou o estilo e a paisagem de referência destravou a rocha.
3. **Conjunto** em `conjuntos/<lugar>.md`: luz, rampas permitidas, faixa de valor por camada, regra de contorno, granulação, material → tons. Sem ele as peças não conversam.
4. **Material difícil pede pesquisa antes.** Rocha falhou cinco vezes até pesquisar (Slynyrd Pixelblog 13, 28, 43 e 62; tutoriais de rocha no itch.io). Se um material não sai em duas tentativas, pesquise e baixe as imagens dos tutoriais para ver, não só ler.

## 2. Ordem das peças

A ordem importa: cada etapa calibra a seguinte.

| # | Peça | Por quê nesta ordem |
|---|---|---|
| 1 | **Peça-âncora**: a construção que define o lugar (o saloon) | fixa estilo, paleta e densidade de detalhe; o usuário aprova antes do resto |
| 2 | **Chão e demarcação de pouso** (areia, deque, sinal) | é o que o jogo precisa para funcionar |
| 3 | **Fundo**: céu, nuvens, montanhas longe e meio, rocha próxima | dá profundidade à tela fixa |
| 4 | **Vegetação e detalhe** (cactos) | quebra o chão e o horizonte |
| 5 | **Vida**: algo que se mexe sem função (arbusto rolando) | faz o lugar parecer vivo |
| 6 | **Personagens parados** | nesta versão ficam quase sempre parados; a animação de parado vem primeiro |
| 7 | **Som**: entrada uma vez, música em laço | fecha a ambientação |

Cada peça: prévia no tamanho real (2x), ao lado das peças já aprovadas e do retângulo da nave, e **mostrar ao usuário antes de seguir**. Peça boa sozinha pode ser ruim junto.

## 3. Técnica por material

O que funcionou, com os tamanhos usados. Troque as rampas pelo conjunto do lugar novo.

### Construção de madeira (qualquer construção)
- Tábuas **longas** (painel de 32x16) com emendas espaçadas e desencontradas. Emenda a cada 16 px lê como tijolo.
- Fresta num tom escuro da própria rampa, nunca preto, e fina.
- Moldura de porta e janela **um degrau mais escura** que a parede, senão some.
- Detalhe que conta história: lampião aceso dentro da janela, reflexo em diagonal no vidro, placa com letras 3x5.
- Construção grande = peças modulares até 64 (parede que repete, janela, porta, placa, beiral, poste, calçada) montadas numa cena.

### Rocha grande, penhasco, mesa
- **Por planos angulares definidos à mão** (polígonos), nunca sombreamento pixel a pixel pela distância da borda.
- Capa de rocha clara com fio de realce de 1 px na aresta de cima.
- Lajes de **larguras diferentes**, reentrâncias largas e escuras entre elas (não linhas finas).
- Placas de saliência quebradas em duas, mini-saliências.
- Base em encosta de cascalho (lado de luz, lado de sombra, canais de escorrimento, oclusão no pé do penhasco) com poucas pedras irregulares.
- Proibido: rachadura como símbolo repetido, textura em grade de blocos (vira muro), colunas separadas por céu (vira caixote).
- Maior que 64: metades que encaixam (a mesa tem 128x64 em duas peças).

### Montanhas e distância
- **Dois planos** atmosféricos: longe (claro, dessaturado, puxado para a cor do céu) e meio (mais escuro, mais contraste).
- Silhueta de mesa ou pico por polígono; luz num lado, sombra no outro; **sem textura** no plano longe.
- Base some na névoa em riscos horizontais.
- Peças únicas de formatos diferentes, espalhadas à mão: a tela é fixa, peça repetida lado a lado aparece na hora.

### Céu
- Cores chapadas da rampa do céu, em faixas.
- Transição entre faixas em **fusos horizontais que afinam** (tile 64x32), nunca xadrez nem linha tracejada.
- Nuvem = bolhas sobrepostas com luz em cima à esquerda, corpo, sombra embaixo e **base reta**; um fio de céu claro sob a base. Nuvem em faixa, baixa e fina, perto do horizonte.

### Chão
- Chão mais claro e menos saturado que a rocha, para separar.
- Topo com uma faixa clara de 4 a 5 px (o chão visto um pouco de cima) e marolas.
- Frente com poucos traços em S e C; detalhe marcante (pedrinha) **só numa variação**.
- Duas variações de topo e duas de preenchimento, alternadas sem padrão.

### Planta
- Cilindro com gomos (luz, realce, corpo, sulco, corpo, sombra), braços como cilindros menores.
- Aréolas claras em fileira sobre os gomos; espinhos de fora numa cor que contraste **com o fundo real** atrás da planta, conferida nos fundos do jogo.

### Coisa viva sem função
- Arbusto seco: arcos e cordas que **giram** enquanto a luz fica parada; galhos finos com **vazios** (disco cheio não lê como galho); 8 quadros de 45°, quique de 2 px, sombra como peça separada.

### Personagem
- 20x28 para caber numa porta de 32. Contorno de 1 px em marrom-arroxeado (`neutros_quentes:1`), exceção declarada no conjunto.
- Silhueta com um acessório icônico (chapéu, avental, chapéu caído sobre os olhos).
- Rosto: olho de 1 px, nariz **dentro** do contorno, bigode com pontas caídas.
- Parado: 4 quadros (cabeça desce 1 px, volta, pisca). Andando: 6 quadros (contato, descida, passagem, e o outro lado). Pés sempre na mesma linha.
- Sentado: pose própria, com o móvel como peça separada.

### Demarcação de pouso
- Estrutura escura e pesada contra o chão claro, faixas de aviso, lampiões nas pontas.
- Sinal 8x8 com quadros por estado: apagado, vermelho, amarelo, verde.

## 4. Montagem no Godot

Padrão do `outpost_regiao.tscn`. Os scripts que montaram o Outpost estão em `reference/modelos/` para copiar e adaptar.

**Pastas**
```
mundo/planetas/<planeta>/regioes/<região>/
├── art/            PNG do lugar  (fonte/ com os .pix, fora do import)
├── sound/          entrada.mp3 (uma vez) e musica.mp3 (laço no importador)
├── <região>.tres   a ficha
├── <região>_tileset.tres
└── <região>_regiao.tscn
entities/estruturas/<construção>/   cena só de desenho, origem no chão
entities/cenario/<personagem>/      Node2D + AnimatedSprite2D, origem nos pés
```

**Planos (z)**

| Nó | z | Conteúdo |
|---|---|---|
| `Fundo` | −10 | céu −10, céu claro −9, névoa −8, transições −7, nuvens −6, montanhas longe −5, meio −4, rocha próxima −3 |
| `Cenario` | −6 | construção, plantas |
| `Relevo` | −3 | `TileMapLayer` pintado com o tileset, colisão na camada `terreno` |
| `Deque` | −2 | a arte da demarcação |
| `Personagens` | −1 | cenas de personagem |
| `PontoDeColeta` | 1 | colisão do pouso, largura calculada entre os postes |
| sinais, coisa viva | 0 | depois do `PontoDeColeta` na árvore |
| `CampoGravitacional` | — | copiado do Outpost; a ficha do planeta aplica os números |
| `Som` | — | `Entrada` com autoplay; `finished` ligado ao `play` de `Musica` |

**Números da tela**: base 640x360 a 2x. Chão na linha 18 da grade de 16 (`y = 288`), 4 linhas de preenchimento abaixo. Nave com cerca de 26 px de largura e 29 de altura.

**Luz**: se o lugar destoa da luz do planeta, `luz_propria` na raiz da região, com ambiente branco e céu da paleta.

**Integração**: ficha `<região>.tres` (nome, assunto, cena, especificação de pouso do lugar, onde a nave aparece acima do pouso, de onde vem, ponto na carta) e uma linha na lista `regioes` da ficha do planeta.

**Conferir sempre**
```
python3 .claude/skills/pixel-art-sprite/scripts/montar_arte.py
godot --headless --path . --import
godot --headless --path . --scene res://tools/paleta_check.tscn
godot --headless --path . --scene res://tools/cenario_check.tscn -- --regiao res://<região>_regiao.tscn
godot --headless --path . --scene res://tools/orbita_check.tscn
godot --headless --path . --scene res://tools/voo_check.tscn
godot --path . --scene res://tools/foto.tscn -- --cena res://<região>_regiao.tscn --saida foto.png --olhar 320,180
```
Peça solta de propósito (fundo, peça sobre construção, sinal no poste) entra no grupo `solto`; o que pisa no chão tem que passar no `cenario_check`.

## 5. Lista para um mapa novo

- [ ] história em três frases e referência visual do usuário
- [ ] `conjuntos/<lugar>.md` com rampas, luz e faixas de valor
- [ ] peça-âncora aprovada
- [ ] chão (2+2 variações) e demarcação de pouso com sinal
- [ ] céu, nuvens, montanhas em dois planos, rocha ou equivalente próximo
- [ ] vegetação ou detalhe do assunto
- [ ] uma coisa viva sem função
- [ ] personagens parados
- [ ] entrada e música
- [ ] cena montada, ficha, linha no planeta, conferências e foto mostrada ao usuário
- [ ] marcador na carta do planeta (`ponto_na_carta`) sobre um chão coerente com o lugar; se o lugar pede um chão que a carta não tem, uma camada nova no conjunto `carta`
