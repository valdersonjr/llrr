class_name EspecificacaoDePouso
extends Resource

## O que um lugar de pouso exige da nave para o pouso valer.
##
## Cada região tem a sua, na ficha: um deque sobre palafitas aperta, um pátio de
## terra batida perdoa. É o botão de dificuldade que a seção 10 do conceito põe na
## demarcação, dito em números que o piloto lê no painel: dentro da especificação
## o número fica verde, fora fica vermelho.
##
## A especificação nunca afrouxa a nave. O trem de pouso tem os limites dele no
## modelo, e vale sempre o mais apertado dos dois: um lugar pode exigir mais do
## que o trem aguenta, nunca menos.

## Velocidade de descida máxima no toque, em metros por segundo.
@export var vertical_maxima: float = 3.0
## Deriva lateral máxima no toque, em metros por segundo. Um deque estreito cobra
## isto mais que a descida: escorregar de lado é cair da borda.
@export var horizontal_maxima: float = 1.5
## Quanto a nave pode estar fora do prumo, em graus.
@export var inclinacao_maxima: float = 12.0
## Giro máximo, em graus por segundo.
@export var giro_maximo: float = 16.0
