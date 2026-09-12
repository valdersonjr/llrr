class_name Silhueta

## Os contornos opacos de uma textura, em coordenada local.
##
## Existe porque dois corpos muito diferentes precisam da mesma coisa: a nave
## tira a colisão do alfa do casco, e a pedra tira a colisão do alfa do desenho
## dela. A conta é idêntica e a intenção também: forma e desenho nunca podem
## discordar, porque o que parece sólido tem que ser sólido.
##
## Devolve geometria, não nó. Quem chama é que monta o `CollisionPolygon2D`,
## porque só o chamador sabe quem é o dono da forma e se ela precisa aparecer
## no editor.
##
## Helper sem estado, então não é autoload e não leva o sufixo `_manager`.


## `tolerancia` é quanto o contorno pode se afastar do desenho, em pixels. Alto
## demais perde a perna da nave; baixo demais cria lasca fina, que corpo rígido
## não resolve bem.
##
## `centrado` alinha o contorno com um `Sprite2D` centrado, que desenha a partir
## do meio da textura. Sem isso a forma nasce deslocada meia textura.
static func contornos_do_alfa(
	arte: Texture2D, tolerancia: float, centrado: bool = false
) -> Array[PackedVector2Array]:
	var imagem: Image = arte.get_image()
	var mapa := BitMap.new()
	mapa.create_from_image_alpha(imagem)
	var contornos: Array[PackedVector2Array] = mapa.opaque_to_polygons(
		Rect2i(Vector2i.ZERO, imagem.get_size()), tolerancia
	)
	if not centrado:
		return contornos

	var meio := Vector2(imagem.get_size()) * 0.5
	var alinhados: Array[PackedVector2Array] = []
	for contorno: PackedVector2Array in contornos:
		var movido := PackedVector2Array()
		for ponto: Vector2 in contorno:
			movido.append(ponto - meio)
		alinhados.append(movido)
	return alinhados
