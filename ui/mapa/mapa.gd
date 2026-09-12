class_name Mapa
extends Control

## O mapa do sistema: onde está a nave e onde estão os corpos. Abre no `M`.
##
## Ele existe porque o espaço dá a volta. Num espaço que fecha, não há borda nem
## estrela fixa para se orientar, e sem mapa o jogador perde a nave de vista sem
## ter como reencontrá-la.
##
## Ele mostra onde as coisas estão, e nada além disso. Não traça rota, não estima
## tempo e não leva ninguém a lugar nenhum: a seção 9 do conceito é explícita em
## que viagem não se resolve por interface, e um mapa que vira painel de destino
## tira do voo a única razão de ele existir.
##
## **Ele não para o jogo.** É para se localizar no meio do voo: a nave continua
## andando com o mapa aberto, e o marcador dela acompanha, quadro a quadro. Quem
## quiser parar para pensar tem a pausa, que é outra tela.

const FUNDO: Color = Color(0.05, 0.07, 0.1, 0.92)
const MOLDURA: Color = Color(0.55, 0.6, 0.6, 0.6)
const NAVE: Color = Color(0.95, 0.96, 0.9, 1.0)
const LETRA: Color = Color(0.78, 0.82, 0.78, 1.0)
const DICA: Color = Color(0.5, 0.55, 0.55, 1.0)

var _nave: Node2D = null
var _corpos: Array[CorpoNoEspaco] = []
var _area: Rect2 = Rect2()

@onready var _quadro: Control = $Quadro


func _ready() -> void:
	hide()


## Quem monta a cena diz o que o mapa mostra: ele não procura ninguém sozinho.
func acompanhar(nave: Node2D, corpos: Array[CorpoNoEspaco], area: Rect2) -> void:
	_nave = nave
	_corpos = corpos
	_area = area


func abrir() -> void:
	show()
	_quadro.queue_redraw()


func fechar() -> void:
	hide()


func aberto() -> bool:
	return visible


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("mapa") or evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


## Onde o marcador da nave está dentro do quadro. Serve à conferência: é assim
## que se prova que o mapa acompanha o voo em vez de mostrar uma foto parada.
func ponto_da_nave() -> Vector2:
	if _nave == null:
		return Vector2.ZERO
	return _no_mapa(_nave.global_position, _quadro.size)


## O desenho vive num nó filho para o retângulo do mapa ser o quadro dele, e não
## a tela inteira: assim as contas de posição são todas relativas ao mapa.
func desenhar_em(quadro: Control) -> void:
	var lado: Vector2 = quadro.size
	quadro.draw_rect(Rect2(Vector2.ZERO, lado), FUNDO)
	quadro.draw_rect(Rect2(Vector2.ZERO, lado), MOLDURA, false, 1.0)
	if _nave == null or _area.size.x <= 0.0:
		return

	var fonte: Font = quadro.get_theme_default_font()
	for corpo: CorpoNoEspaco in _corpos:
		var onde: Vector2 = _no_mapa(corpo.global_position, lado)
		var raio: float = maxf(3.0, corpo.raio() / _area.size.x * lado.x)
		quadro.draw_circle(onde, raio, corpo.planeta.cor_de_identidade.lightened(0.25))
		quadro.draw_string(
			fonte, onde + Vector2(raio + 4.0, 3.0), corpo.planeta.nome.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, LETRA
		)

	# A nave é um quadrado de três pixels com uma mira em volta: num mapa deste
	# tamanho, desenho com forma vira borrão, e o que importa é achá-la rápido.
	var ponto: Vector2 = _no_mapa(_nave.global_position, lado)
	quadro.draw_rect(Rect2(ponto - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), NAVE)
	quadro.draw_arc(ponto, 7.0, 0.0, TAU, 16, NAVE * Color(1, 1, 1, 0.5), 1.0)
	quadro.draw_string(
		fonte, Vector2(8.0, lado.y - 8.0), "M   FECHAR",
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, DICA
	)


## Leva um ponto do mundo para o mapa, dando a volta junto com o espaço: quem
## cruzou a borda aparece do outro lado aqui também.
func _no_mapa(ponto: Vector2, lado: Vector2) -> Vector2:
	var dentro := Vector2(
		fposmod(ponto.x - _area.position.x, _area.size.x),
		fposmod(ponto.y - _area.position.y, _area.size.y)
	)
	return dentro / _area.size * lado
