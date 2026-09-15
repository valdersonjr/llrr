class_name LogoDoTitulo
extends Control

## O nome do jogo na tela de título, na fonte do jogo, com contorno e sombra de
## pixel inteiro.
##
## A fonte só fica nítida nos múltiplos de 18, então as duas linhas usam 54 e 36.
## O contorno é o próprio texto desenhado nas oito vizinhanças, e não o contorno
## da fonte, que o rasterizador faz com meio pixel.

@export var linha_de_cima: String = "LANDER"
@export var linha_de_baixo: String = "FOR HIRE"

const COR_DE_CIMA: Color = Color("ffffff")   # neutros_frios:4
const COR_DE_BAIXO: Color = Color("f9c22b")  # vermelho_laranja:4
const CONTORNO: Color = Color("2e222f")      # neutros_quentes:0
const SOMBRA: Color = Color("ae2334")        # vermelho_laranja:0
const TAMANHO_DE_CIMA: int = 54
const TAMANHO_DE_BAIXO: int = 36
## Quanto a linha de baixo sobe para colar na de cima: a fonte reserva espaço de
## descendente que as maiúsculas não usam.
const APROXIMACAO: float = 8.0


func _draw() -> void:
	var fonte: Font = get_theme_default_font()
	var base_de_cima: float = fonte.get_ascent(TAMANHO_DE_CIMA)
	_escrever(fonte, Vector2(0.0, base_de_cima), linha_de_cima, TAMANHO_DE_CIMA, COR_DE_CIMA)
	var base_de_baixo: float = (
		base_de_cima + fonte.get_descent(TAMANHO_DE_CIMA) + fonte.get_ascent(TAMANHO_DE_BAIXO) - APROXIMACAO
	)
	_escrever(fonte, Vector2(4.0, base_de_baixo), linha_de_baixo, TAMANHO_DE_BAIXO, COR_DE_BAIXO)


func _escrever(fonte: Font, onde: Vector2, texto: String, tamanho: int, cor: Color) -> void:
	var base: Vector2 = onde.round()
	var camadas: Array = [[Vector2(2.0, 2.0), SOMBRA], [Vector2.ZERO, CONTORNO]]
	for camada: Array in camadas:
		for ox: int in [-1, 0, 1]:
			for oy: int in [-1, 0, 1]:
				draw_string(fonte, base + camada[0] + Vector2(ox, oy), texto,
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, tamanho, camada[1])
	draw_string(fonte, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tamanho, cor)
