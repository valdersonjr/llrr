class_name QuadroDoMapa
extends Control

## O retângulo onde o mapa é desenhado. Existe só para o desenho ter um quadro
## próprio: as contas de posição ficam relativas ao mapa, e não à tela inteira.
##
## Ele não sabe nada do sistema. Quem desenha é `Mapa`, o pai.


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var mapa := get_parent() as Mapa
	if mapa != null:
		mapa.desenhar_em(self)
