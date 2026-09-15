class_name GradeDaCarta
extends Control

## A grade de coordenadas por cima da carta de superfície: pontilhado a cada
## `PASSO` pixels, letras nas colunas e números nas linhas.
##
## É o que faz a carta ser lida como carta, e não como paisagem: "Outpost, H4"
## diz onde a região fica sem o jogador precisar comparar formas de costa.
##
## As letras ficam fora do retângulo do nó, em cima e à esquerda, e por isso este
## nó não pode cortar o que desenha.

const PASSO: int = 32
const COR: Color = Color(0.78039217, 0.8627451, 0.8156863, 1)  # neutros_frios:3


## O setor de um ponto da carta, como aparece na grade: coluna em letra, linha em número.
static func setor(ponto: Vector2i) -> String:
	return "%s%d" % [String.chr(65 + floori(ponto.x / float(PASSO))), floori(ponto.y / float(PASSO)) + 1]


func _draw() -> void:
	var largura: int = int(size.x)
	var altura: int = int(size.y)
	# Um ponto sim, um não, e a mesma paridade nos dois sentidos: o cruzamento das
	# linhas cai sempre num ponto aceso.
	for x: int in range(PASSO, largura, PASSO):
		for y: int in range(0, altura):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(x, y, 1, 1), COR)
	for y: int in range(PASSO, altura, PASSO):
		for x: int in range(0, largura):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(x, y, 1, 1), COR)

	var fonte: Font = get_theme_default_font()
	var tamanho: int = get_theme_default_font_size()
	for i: int in ceili(largura / float(PASSO)):
		draw_string(fonte, Vector2(i * PASSO, -12), String.chr(65 + i),
			HORIZONTAL_ALIGNMENT_CENTER, PASSO, tamanho, COR)
	for j: int in ceili(altura / float(PASSO)):
		draw_string(fonte, Vector2(-20, j * PASSO + 21), str(j + 1),
			HORIZONTAL_ALIGNMENT_CENTER, 10, tamanho, COR)
