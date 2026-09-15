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

const FUNDO: Color = Color(0.18039216, 0.13333334, 0.18431373, 1)  # neutros_quentes:0
const GRADE: Color = Color(0.38431373, 0.33333334, 0.39607844, 1)  # neutros_quentes:2
const LETRA: Color = Color(0.78039217, 0.8627451, 0.8156863, 1)  # neutros_frios:3
const DICA: Color = Color(0.49803922, 0.4392157, 0.5411765, 1)  # neutros_frios:1
## A mesma grade da carta de superfície, mais apagada: aqui ela só dá chão ao
## olho, não há setor para ler.
const PASSO_DA_GRADE: int = 32
const NAVE: Texture2D = preload("res://ui/mapa/art/nave.png")
const FOCO: Texture2D = preload("res://ui/art/foco.png")
const PISCA_A_CADA_MS: int = 450

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
	_desenhar_grade(quadro, lado)
	if _nave == null or _area.size.x <= 0.0:
		return

	# A fonte do jogo só fica nítida no tamanho do tema e nos múltiplos dele.
	var fonte: Font = quadro.get_theme_default_font()
	var tamanho: int = quadro.get_theme_default_font_size()
	for corpo: CorpoNoEspaco in _corpos:
		var miniatura: Texture2D = corpo.planeta.miniatura
		if miniatura == null:
			continue
		# Tudo em pixel inteiro: miniatura em meio pixel sai borrada.
		var onde: Vector2 = _no_mapa(corpo.global_position, lado).floor()
		var meio: Vector2 = (miniatura.get_size() * 0.5).floor()
		# O espaço dá a volta, e a miniatura também: perto da borda do quadro ela
		# aparece cortada dos dois lados, como o corpo aparece no voo.
		for dx: int in [-1, 0, 1]:
			for dy: int in [-1, 0, 1]:
				quadro.draw_texture(miniatura, onde - meio + Vector2(dx, dy) * lado)
		quadro.draw_string(
			fonte, onde + Vector2(meio.x + 6.0, 6.0), corpo.planeta.nome.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, tamanho, LETRA
		)

	# A nave é um losango pequeno com os cantos de foco piscando em volta: num mapa
	# deste tamanho, desenho com forma de nave vira borrão, e o que importa é
	# achá-la rápido.
	var ponto: Vector2 = _no_mapa(_nave.global_position, lado).floor()
	quadro.draw_texture(NAVE, ponto - (NAVE.get_size() * 0.5).floor())
	if floori(Time.get_ticks_msec() / float(PISCA_A_CADA_MS)) % 2 == 0:
		quadro.draw_texture(FOCO, ponto - (FOCO.get_size() * 0.5).floor())
	quadro.draw_string(
		fonte, Vector2(10.0, lado.y - 9.0), "M   FECHAR",
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, tamanho, DICA
	)


## Pontilhado, um ponto sim e um não, como na carta de superfície.
func _desenhar_grade(quadro: Control, lado: Vector2) -> void:
	for x: int in range(PASSO_DA_GRADE, int(lado.x), PASSO_DA_GRADE):
		for y: int in range(0, int(lado.y)):
			if (x + y) % 2 == 0:
				quadro.draw_rect(Rect2(x, y, 1, 1), GRADE)
	for y: int in range(PASSO_DA_GRADE, int(lado.y), PASSO_DA_GRADE):
		for x: int in range(0, int(lado.x)):
			if (x + y) % 2 == 0:
				quadro.draw_rect(Rect2(x, y, 1, 1), GRADE)


## Leva um ponto do mundo para o mapa, dando a volta junto com o espaço: quem
## cruzou a borda aparece do outro lado aqui também.
func _no_mapa(ponto: Vector2, lado: Vector2) -> Vector2:
	var dentro := Vector2(
		fposmod(ponto.x - _area.position.x, _area.size.x),
		fposmod(ponto.y - _area.position.y, _area.size.y)
	)
	return dentro / _area.size * lado
