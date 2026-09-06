# Paleta base do Lunar RPG

Hipótese de trabalho, como as quantidades do documento de conceito. Ajuste com um protótipo na tela, não no papel.

Toda rampa usa **hue shifting**: a sombra desloca para o azul/roxo, a luz para o amarelo/laranja. Escurecer a mesma matiz produz rampa morta.

## Contorno

O fundo do jogo é o espaço, escuro quase sempre. Contorno quase preto **desaparece** ali.

| Uso | Cor | Quando |
|---|---|---|
| Contorno padrão | `#2b3145` | regra geral — lê contra o espaço |
| Contorno profundo | `#16161f` | só onde houver fundo claro atrás (superfície iluminada, UI) |
| Fundo do espaço | `#0d0f1a` | referência para testar contraste |

Preferível a um contorno único: usar uma versão escurecida da cor adjacente. Dá volume em vez de recortar o sprite com adesivo.

## Casco do jogador — azul frio

| Char | Cor | Papel |
|---|---|---|
| `D` | `#232a52` | sombra profunda |
| `d` | `#2e3b6b` | sombra |
| `c` | `#4a6fc4` | base |
| `C` | `#7fa8e8` | luz |
| `L` | `#b8d4f5` | brilho especular |

## Metal — pernas, motor, estrutura

| Char | Cor | Papel |
|---|---|---|
| `n` | `#3a3f52` | sombra profunda |
| `m` | `#6b7185` | sombra |
| `M` | `#a8aec4` | base/luz |
| `N` | `#dfe3ee` | brilho |

## Cabine — âmbar CRT

Quente de propósito, para contrastar com o casco frio e puxar o olho para onde o piloto está.

| Char | Cor | Papel |
|---|---|---|
| `h` | `#a06a1c` | sombra do vidro |
| `g` | `#f2c14e` | vidro |
| `G` | `#fff2c4` | reflexo |

## Calor e propulsão

| Char | Cor | Papel |
|---|---|---|
| `f` | `#ef7d57` | chama externa |
| `F` | `#ffcd75` | chama interna |
| `W` | `#fff8e8` | núcleo |

## Estado e alerta

Nunca use só cor para comunicar estado — a seção 14 do conceito proíbe. Cor acompanha mudança de **forma**.

| Char | Cor | Papel |
|---|---|---|
| `r` | `#b13e53` | dano, hostil |
| `v` | `#5ab552` | ok, aliado |

## Convenção de caracteres

Maiúscula = versão mais clara da mesma família; minúscula = mais escura. `.` é sempre transparente, `K` é sempre contorno. Manter isso entre sprites deixa os `.pix` legíveis sem consultar a paleta toda hora.
