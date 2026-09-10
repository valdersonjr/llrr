# Paleta base do Lunar RPG

Hipótese de trabalho, como as quantidades do documento de conceito. Ajuste com um protótipo na tela, não no papel.

Pixel art moderna: a rampa não é a base escurecida. **A sombra recebe a cor do ambiente** — azulada porque o céu é azulado — e a luz desloca para o quente. Escurecer a mesma matiz produz rampa morta.

## Contorno e borda

O fundo do jogo é escuro quase sempre, e o céu tem gradiente: perto do horizonte ele clareia. O contorno precisa ser mais escuro que a parte mais clara do céu, senão a silhueta some no meio da subida.

| Char | Uso | Cor | Quando |
|---|---|---|---|
| `K` | Contorno | `#141a2e` | a aresta voltada para a luz, e a que não recebe borda |
| `R` | Luz de borda | `#7d93cc` | 1px na aresta voltada para baixo-direita **que esteja em sombra funda**. Sobre sombra rasa ela contorna a peça inteira e a nave sai com filete branco em volta. |
| `q` | Derrame quente fraco | `#6b4a3c` | casco em volta de motor e cabine |
| `Q` | Derrame quente forte | `#a06a45` | o mesmo, colado na fonte |

## Casco do jogador — azul frio

| Char | Cor | Papel |
|---|---|---|
| `A` | `#222b4b` | sombra de ambiente |
| `d` | `#3c4d7d` | sombra |
| `c` | `#55689f` | meio-tom |
| `C` | `#7189bd` | base |
| `L` | `#9db3dc` | luz |
| `W` | `#d5e3f7` | brilho |

## Metal — pernas, motor, estrutura, plataforma

| Char | Cor | Papel |
|---|---|---|
| `n` | `#2c3040` | sombra profunda |
| `m` | `#464d60` | sombra |
| `M` | `#6f7789` | meio |
| `N` | `#9aa2b4` | luz |
| `E` | `#cdd4e2` | brilho |

## Rocha — terreno

Contraste baixo de propósito: o chão é massa, não ponto de interesse, e tem que pesar **mais** que o céu. Rocha mais clara que o fundo faz o terreno flutuar.

| Char | Cor | Papel |
|---|---|---|
| `A` | `#0f1322` | sombra profunda |
| `B` | `#161b2e` | sombra |
| `C` | `#1f2740` | base |
| `D` | `#2a3352` | luz |
| `E` | `#39456a` | crosta, a face que o sol pega |

## Cabine e balizas — âmbar

Quente de propósito, para contrastar com o casco frio e puxar o olho para onde o piloto está. É emissiva: derrama pixels quentes no que está em volta.

| Char | Cor | Papel |
|---|---|---|
| `h` | `#7a4a17` | sombra do vidro |
| `g` | `#e0a83c` | vidro, baliza |
| `G` | `#ffe9a8` | reflexo, núcleo da baliza |

## Chama

Calor de verdade tem gradiente: a garganta é a parte mais quente e puxa para o azul-branco; a ponta esfria para o vermelho. Amarelo chapado é o que denuncia chama de jogo antigo.

| Char | Cor | Papel |
|---|---|---|
| `b` | `#bfe2ff` | garganta, mais quente |
| `W` | `#fffdf2` | núcleo |
| `w` | `#ffe6a4` | interna |
| `F` | `#ffb347` | média |
| `f` | `#ef7a3a` | externa |
| `p` | `#b8452f` | ponta fria |

## Estado e alerta

Nunca use só cor para comunicar estado — a seção 14 do conceito proíbe. Cor acompanha mudança de **forma**.

| Char | Cor | Papel |
|---|---|---|
| `r` | `#b13e53` | alerta, fora do limite |
| `v` | `#5ab552` | ok, dentro do limite |

## Convenção de caracteres

Maiúscula = versão mais clara da mesma família; minúscula = mais escura. `.` é sempre transparente, `K` é sempre contorno, `R` é sempre luz de borda, `W` é sempre o tom mais claro da família, `q` e `Q` são o derrame quente.

A mesma letra pode servir a famílias diferentes — `A`, `C` e `E` valem para casco, metal e rocha — porque cada `.pix` declara a própria paleta e nenhum sprite mistura duas famílias na mesma letra. O que se mantém entre sprites é o **papel** da letra, não a cor: `C` é sempre a base do material, `E` sempre o tom mais alto dele. É isso que deixa os `.pix` legíveis sem consultar a paleta toda hora.
