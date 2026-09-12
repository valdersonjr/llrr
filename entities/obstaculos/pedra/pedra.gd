@tool
class_name Pedra
extends StaticBody2D

## Pedra solta do terreno.
##
## Ela é obstáculo e não cenário, e o motivo é a regra do `entities/CLAUDE.md`: o
## que tem tamanho para o jogador ler como sólido tem que ser sólido. Pedra grande
## que a nave atravessa é armadilha, não enfeite, e quebra a promessa de
## consequência legível da seção 2 do conceito.
##
## A colisão sai do alfa da própria arte, pela mesma conta que a nave usa para o
## casco, em `Silhueta`. Assim trocar a textura nunca deixa a forma e o desenho em
## desacordo, e a mesma cena serve a qualquer pedra de qualquer planeta.

@export var arte: Texture2D:
	set(valor):
		arte = valor
		if is_node_ready():
			montar()

## Quanto a colisão pode se afastar do contorno, em pixels. Maior deixa a forma
## mais simples e mais barata.
@export var tolerancia: float = 2.0

@onready var _sprite: Sprite2D = $Arte


func _ready() -> void:
	montar()


func montar() -> void:
	for velho: Node in get_children():
		if velho is CollisionPolygon2D:
			velho.queue_free()
	_sprite.texture = arte
	if arte == null:
		return

	for contorno: PackedVector2Array in Silhueta.contornos_do_alfa(arte, tolerancia):
		var forma := CollisionPolygon2D.new()
		forma.polygon = contorno
		add_child(forma)
		if Engine.is_editor_hint():
			forma.owner = get_tree().edited_scene_root
