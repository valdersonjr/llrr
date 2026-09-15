class_name CampoDeEstrelas
extends Node2D

## Uma camada do fundo do espaço que acompanha a câmera mais devagar do que ela.
##
## Várias destas, com `fator` diferente, dão profundidade ao espaço sem nenhuma
## estrela existir de verdade. Cada camada tem duas coisas, as duas opcionais:
##
## - **ladrilhos**: uma tira de variações de 64x48, sorteadas pela posição dentro
##   do mosaico, para o campo não repetir o mesmo quadrado lado a lado;
## - **enfeites**: nebulosa, estrela que cintila, estrela cadente. Cada um é uma
##   tira de quadros colocada num ponto do mosaico e repetida com ele.
##
## O mosaico (`periodo` ladrilhos) é o que se repete. A camada é desenhada em
## pixel de tela e anda só pela paralaxe: a posição da câmera vezes o `fator`.

## Quanto a camada fica para trás. Zero anda junto com a câmera; um fica parado
## no mundo, como se estivesse infinitamente longe.
@export_range(0.0, 1.0, 0.0001) var fator: float = 0.9

@export_group("Ladrilhos")
## Tira horizontal com as variações de ladrilho, lida como `variacoes` quadros.
@export var textura: Texture2D
@export var variacoes: int = 1
## Tamanho do ladrilho quando a camada não tem textura, só enfeites.
@export var tamanho_do_ladrilho: Vector2i = Vector2i(64, 48)
## Quantos ladrilhos formam o mosaico que se repete.
@export var periodo: Vector2i = Vector2i(8, 6)

@export_group("Enfeites")
## As tiras de enfeite. Uma nebulosa tem um quadro; uma estrela, vários.
@export var enfeites: Array[Texture2D] = []
@export var quadros_por_enfeite: PackedInt32Array = PackedInt32Array()
## Passos de espera entre um ciclo e outro. Positivo: fica no quadro 0 (a estrela
## vira ponto). Negativo: some na espera (a estrela cadente só passa de vez em quando).
@export var pausa_por_enfeite: PackedInt32Array = PackedInt32Array()
## Cada enfeite colocado: qual tira e onde fica, dentro do mosaico.
@export var enfeite_de_cada: PackedInt32Array = PackedInt32Array()
@export var posicao_de_cada: PackedVector2Array = PackedVector2Array()
@export var segundos_por_quadro: float = 0.12

var _deslocamento: Vector2 = Vector2.ZERO
var _tela: Vector2 = Vector2.ZERO
var _passo: int = -1
var _tempo: float = 0.0


## O tamanho do que se repete. Uma volta inteira do espaço vezes o `fator` tem que
## ser múltiplo disto, senão a borda do sistema aparece.
func mosaico() -> Vector2:
	return _ladrilho() * Vector2(periodo)


func _ladrilho() -> Vector2:
	if textura != null:
		return Vector2(float(textura.get_width()) / float(maxi(variacoes, 1)), float(textura.get_height()))
	return Vector2(tamanho_do_ladrilho)


## A camada é desenhada em pixel de tela, e não de mundo. Na vista de espaço a
## câmera fica afastada, e um fundo preso ao mundo encolheria junto: a pixel art
## perderia pixels e o mosaico caberia várias vezes na tela. Por isso o nó anula
## a transformação da câmera a cada quadro e anda só pela paralaxe.
func _process(delta: float) -> void:
	_tempo += delta
	var viewport: Viewport = get_viewport()
	var camera: Camera2D = viewport.get_camera_2d()
	if camera == null:
		return
	global_transform = viewport.get_canvas_transform().affine_inverse()

	var deslocamento: Vector2 = -(camera.get_screen_center_position() * fator).round()
	var tela: Vector2 = viewport.get_visible_rect().size
	var passo: int = int(_tempo / segundos_por_quadro)
	if deslocamento == _deslocamento and tela == _tela and (passo == _passo or enfeites.is_empty()):
		return
	_deslocamento = deslocamento
	_tela = tela
	_passo = passo
	queue_redraw()


func _draw() -> void:
	if textura != null:
		_desenhar_ladrilhos()
	if not enfeites.is_empty():
		_desenhar_enfeites()


func _desenhar_ladrilhos() -> void:
	var lado: Vector2 = _ladrilho()
	var primeira := Vector2i((-_deslocamento / lado).floor()) - Vector2i.ONE
	var colunas: int = ceili(_tela.x / lado.x) + 2
	var linhas: int = ceili(_tela.y / lado.y) + 2
	for j: int in linhas:
		for i: int in colunas:
			var celula: Vector2i = primeira + Vector2i(i, j)
			var origem := Rect2(Vector2(float(_variacao(celula)) * lado.x, 0.0), lado)
			draw_texture_rect_region(textura, Rect2(Vector2(celula) * lado + _deslocamento, lado), origem)


## A variação de cada ladrilho sai da posição dele dentro do mosaico, então o
## desenho é o mesmo a cada volta e nunca pisca quando a câmera anda.
func _variacao(celula: Vector2i) -> int:
	var x: int = posmod(celula.x, maxi(periodo.x, 1))
	var y: int = posmod(celula.y, maxi(periodo.y, 1))
	var mistura: int = ((x * 73856093) ^ (y * 19349663)) & 0x7fffffff
	return mistura % maxi(variacoes, 1)


func _desenhar_enfeites() -> void:
	var m: Vector2 = mosaico()
	for n: int in posicao_de_cada.size():
		var qual: int = enfeite_de_cada[n] if n < enfeite_de_cada.size() else 0
		if qual < 0 or qual >= enfeites.size() or enfeites[qual] == null:
			continue
		var tira: Texture2D = enfeites[qual]
		var quadros: int = maxi(quadros_por_enfeite[qual] if qual < quadros_por_enfeite.size() else 1, 1)
		var pausa: int = pausa_por_enfeite[qual] if qual < pausa_por_enfeite.size() else 0
		var quadro: int = _quadro(quadros, pausa, n)
		if quadro < 0:
			continue
		var tamanho := Vector2(float(tira.get_width()) / float(quadros), float(tira.get_height()))
		var origem := Rect2(Vector2(float(quadro) * tamanho.x, 0.0), tamanho)
		var base: Vector2 = posicao_de_cada[n] + _deslocamento
		var kx0: int = floori((-base.x - tamanho.x) / m.x)
		var kx1: int = ceili((_tela.x - base.x) / m.x)
		var ky0: int = floori((-base.y - tamanho.y) / m.y)
		var ky1: int = ceili((_tela.y - base.y) / m.y)
		for ky: int in range(ky0, ky1 + 1):
			for kx: int in range(kx0, kx1 + 1):
				draw_texture_rect_region(tira, Rect2(base + Vector2(kx * m.x, ky * m.y), tamanho), origem)


## Estrela: ida e volta pelos quadros e espera no quadro 0. Estrela cadente
## (pausa negativa): passa uma vez e some. A fase desencontra os enfeites.
func _quadro(quadros: int, pausa: int, n: int) -> int:
	if quadros <= 1:
		return 0
	var ciclo: int = quadros if pausa < 0 else quadros * 2 - 2
	var total: int = ciclo + absi(pausa)
	var t: int = posmod(_passo + n * 7919, total)
	if t >= ciclo:
		return -1 if pausa < 0 else 0
	if pausa < 0 or t < quadros:
		return t
	return ciclo - t
