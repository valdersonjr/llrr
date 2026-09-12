class_name Escala

## A ponte entre o mundo físico e a tela.
##
## Sem ela, "gravidade 190" não quer dizer nada e nenhum número de voo é
## conferível. Com ela, 9.81 quer dizer Terra, 1.62 quer dizer Lua, e uma
## velocidade de toque de 3 m/s quer dizer um pouso que o trem de pouso aguenta.
##
## A regra: toda grandeza física do jogo é escrita em unidade de verdade — metro,
## segundo, quilo e grau — e só vira pixel na fronteira com a física do Godot.
## Nenhum `.tres` guarda pixel por segundo.
##
## Helper sem estado, então não é autoload e não leva o sufixo `_manager`.

## Quantos pixels vale um metro.
##
## Com 5, a nave de 29 px tem 5,8 m de altura, o deque tem 14,4 m e a tela
## inteira é uma área de pouso de 128 por 72 metros. Mudar isto reescala o jogo
## inteiro de uma vez, que é exatamente o motivo de existir uma constante só.
const PIXELS_POR_METRO: float = 5.0

## Gravidade da Terra ao nível do mar, em metros por segundo ao quadrado.
const G_TERRA: float = 9.80665


static func para_pixels(metros: float) -> float:
	return metros * PIXELS_POR_METRO


static func para_metros(pixels: float) -> float:
	return pixels / PIXELS_POR_METRO
