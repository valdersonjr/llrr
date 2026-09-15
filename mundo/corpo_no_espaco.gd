class_name CorpoNoEspaco
extends Node2D

## Como um lugar se vê na vista de espaço, e a porta de entrada dele.
##
## O corpo é o irmão de `Regiao`: um descreve o lugar visto de longe, o outro
## visto de dentro. A diferença é que o corpo **conhece** a ficha do planeta,
## porque ele é colocado à mão no sistema e precisa dizer que lugar é aquele. A
## região continua sem conhecer a ficha, para abrir sozinha por `--scene`.
##
## ## Entrar não é voar para dentro
##
## Chegar perto acende o destaque e o convite; a tecla abre a tela de regiões, e
## é lá que se escolhe onde descer. A nave não atravessa fronteira nenhuma: ela
## para onde está e depois aparece no ponto que a ficha da região definiu.
##
## Já foi diferente: a primeira versão entrava descendo sobre o corpo, sem nada
## ser recolocado. Aquilo entregava inércia contínua e tirava do projetista o
## controle de onde a nave aparece, que é o que um lugar desenhado à mão precisa.
## Trocamos uma promessa pela outra de propósito.

## Quanto a nave sobe acima do terreno antes de a região devolver a tela de
## regiões. Não é zero para a saída não disparar num pulinho, e não é muito para
## a nave não sumir da tela enquanto sai.
const MARGEM_DE_SAIDA: float = 40.0

## A que distância do corpo o convite de entrada acende, medido da borda dele.
const ALCANCE_DE_ENTRADA: float = 300.0

## O canto de cima à esquerda da mira de entrada; os outros três são ele espelhado.
const MIRA: Texture2D = preload("res://mundo/art/mira.png")
## Quanto a mira fica afastada da borda do corpo, em pixels de tela.
const FOLGA_DA_MIRA: float = 12.0

@export var planeta: Planeta

var _destacado: bool = false

## O desenho do corpo é um `TileMapLayer` de peças dentro de `Arte`. Ele é pixel
## art em pixel de tela: a câmera do espaço fica afastada, e um corpo desenhado em
## pixel de mundo encolheria e borraria. Por isso `Arte` tem escala
## `1 / zoom_no_espaco` da câmera, e as peças centradas nela.
@onready var _arte: Node2D = $Arte


func _ready() -> void:
	assert(planeta != null, "Um CorpoNoEspaco precisa da ficha do lugar em `planeta`.")
	assert(_desenho() != null, "Um CorpoNoEspaco precisa do desenho do corpo: um TileMapLayer dentro de Arte.")


## O raio do corpo sai do próprio desenho: quem troca a arte troca o tamanho do
## planeta, e o alcance do convite acompanha sem ninguém mexer em número nenhum.
## É o lado das peças pintadas, em pixel de tela, vezes a escala da arte.
func raio() -> float:
	return raio_na_tela() * _arte.scale.x


## O raio em pixels de tela, que é o que o desenho tem de verdade.
func raio_na_tela() -> float:
	var desenho: TileMapLayer = _desenho()
	return float(desenho.get_used_rect().size.x * desenho.tile_set.tile_size.x) * 0.5


## Quantos pixels de mundo cada pixel do desenho ocupa. Vezes o zoom da câmera no
## espaço, tem que dar 1: é isso que deixa o corpo nítido.
func escala_da_arte() -> float:
	return _arte.scale.x


func _desenho() -> TileMapLayer:
	for filho: Node in _arte.get_children():
		if filho is TileMapLayer:
			return filho
	return null


## A nave está perto o bastante para o convite de entrada acender.
func ao_alcance(ponto: Vector2) -> bool:
	return global_position.distance_to(ponto) <= raio() + ALCANCE_DE_ENTRADA


## O canto de onde uma região deste corpo nasce, centrada nele. Espaço e
## superfície continuam no mesmo sistema de coordenadas, o que mantém a câmera
## simples e as ferramentas de conferência apontando para lugares de verdade.
func canto_da_regiao() -> Vector2:
	return global_position - Regiao.TAMANHO * 0.5


func area_da_regiao() -> Rect2:
	return Rect2(canto_da_regiao(), Regiao.TAMANHO)


## Onde o centro do quadro pode ficar enquanto se está numa região deste corpo.
## Como uma região é uma tela, isto é quase uma linha: a câmera fica parada no
## terreno e sobe só a margem de saída, para a nave não sumir enquanto ganha
## altitude para voltar à tela de regiões.
func limites_da_camera() -> Rect2:
	var centro: Vector2 = global_position
	return Rect2(
		Vector2(centro.x, centro.y - MARGEM_DE_SAIDA), Vector2(0.0, MARGEM_DE_SAIDA)
	)


## Subiu o bastante para deixar a região. Para os lados não se sai, dá-se a volta;
## para baixo está o chão.
func subiu_demais(ponto: Vector2) -> bool:
	return ponto.y < area_da_regiao().position.y - MARGEM_DE_SAIDA


## O corpo some enquanto se está dentro dele: quem mostra o lugar de perto é a
## região, e as duas ocupam o mesmo ponto no mundo. Como a troca acontece atrás da
## tela de regiões, isto não precisa desvanecer: ninguém vê o instante.
func aparecer(visivel: bool) -> void:
	_arte.visible = visivel


## O destaque é o que diz "dá para entrar aqui". Ele é desenhado no mundo, e não
## na interface, para acender em volta do corpo certo sem ninguém converter
## coordenada de tela.
func destacar(aceso: bool) -> void:
	if _destacado == aceso:
		return
	_destacado = aceso
	queue_redraw()


func _draw() -> void:
	if not _destacado:
		return
	# Quatro cantos em vez de um anel fechado: lê como mira, não como órbita. Eles
	# ficam nas diagonais, logo fora da borda, e são desenhados na escala da arte
	# para caírem em pixel de tela como o corpo.
	var escala: float = _arte.scale.x
	var canto: float = floorf((raio_na_tela() + FOLGA_DA_MIRA) * sqrt(0.5))
	for virar_x: float in [1.0, -1.0]:
		for virar_y: float in [1.0, -1.0]:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(escala * virar_x, escala * virar_y))
			draw_texture(MIRA, Vector2(-canto - 1.0, -canto - 1.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
