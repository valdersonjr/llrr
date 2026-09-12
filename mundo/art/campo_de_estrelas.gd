class_name CampoDeEstrelas
extends Node2D

## Uma camada de estrelas que acompanha a câmera mais devagar do que ela anda.
##
## Duas ou três destas, com `fator` diferente, dão profundidade ao espaço sem
## nenhuma estrela existir de verdade: a textura é lado a lado, e o que cria a
## sensação de distância é a camada mais longe deslizar menos.
##
## A emenda do mosaico é ancorada numa grade do tamanho da textura, e não no
## canto da tela. Sem isso o padrão andaria junto com a câmera e a profundidade
## se cancelaria: as estrelas ficariam grudadas na janela.

## Quanto a camada fica para trás. Zero anda junto com a câmera, então não tem
## paralaxe nenhuma; um fica parado no mundo, como se estivesse a distância
## infinita.
@export_range(0.0, 1.0, 0.01) var fator: float = 0.9
@export var textura: Texture2D

var _janela: Rect2 = Rect2()


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null or textura == null:
		return

	var centro: Vector2 = camera.get_screen_center_position()
	position = centro * (1.0 - fator)

	var lado: Vector2 = textura.get_size()
	var visivel: Vector2 = Vector2(get_viewport_rect().size) / camera.zoom
	var canto: Vector2 = centro - position - visivel * 0.5
	# Ancorar na grade da textura: o mosaico pertence ao mundo, não à tela.
	canto = (canto / lado).floor() * lado
	var janela := Rect2(canto, visivel + lado * 2.0)
	if janela == _janela:
		return
	_janela = janela
	queue_redraw()


func _draw() -> void:
	if textura == null:
		return
	draw_texture_rect(textura, _janela, true)
