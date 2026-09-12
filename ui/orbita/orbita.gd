class_name Orbita
extends Control

## O convite de entrada e a tela de regiões de um planeta.
##
## As duas coisas moram juntas porque são a mesma conversa em dois momentos:
## "dá para entrar aqui" e "entre por onde?". A cena do sistema acende uma e
## abre a outra; esta classe não decide nada, só mostra e avisa o que o jogador
## escolheu.
##
## A tela é interface e não mundo, de propósito. Nome de lugar, foco de teclado e
## clique de mouse são exatamente o que um `Control` já faz bem, e desenhar isso
## no mundo custaria converter coordenada de tela para nada em troca.
##
## O jogador escolhe com o mouse ou com as setas, e as setas funcionam sem
## ninguém ligar fio nenhum: sem vizinho de foco declarado, o Godot acha o
## marcador mais próximo na direção apertada, que é a leitura certa quando os
## marcadores estão espalhados sobre um disco.

signal regiao_escolhida(ficha: FichaDeRegiao)
signal fechada()

## O quanto o disco do planeta ocupa na tela de regiões, em pixels da tela base.
const LADO_DO_CORPO: float = 232.0

@onready var _convite: Control = $Convite
@onready var _convite_texto: Label = $Convite/Texto
@onready var _selecao: Control = $Selecao
@onready var _corpo: TextureRect = $Selecao/Corpo
@onready var _marcadores: Control = $Selecao/Corpo/Marcadores
@onready var _titulo: Label = $Selecao/Titulo
@onready var _assunto: Label = $Selecao/Assunto
@onready var _sair: Button = $Selecao/Sair


func _ready() -> void:
	_convite.hide()
	_selecao.hide()
	# A tecla de sair continua valendo, mas ela sozinha não basta: quem entrou de
	# mouse não tem como descobrir que ela existe. O botão é a saída visível, e a
	# linha de comandos embaixo diz o resto.
	_sair.pressed.connect(fechar)


func aberta() -> bool:
	return _selecao.visible


## O convite acende quando a nave chega perto de um corpo, e apaga quando ela se
## afasta. Quem sabe disso é a cena do sistema.
func convidar(nome: String) -> void:
	_convite_texto.text = "E   ENTRAR EM %s" % nome.to_upper()
	_convite.show()


func retirar_convite() -> void:
	_convite.hide()


func abrir(corpo: CorpoNoEspaco) -> void:
	_convite.hide()
	_corpo.texture = corpo.textura()
	_titulo.text = corpo.planeta.nome.to_upper()
	_montar_marcadores(corpo.planeta)
	_selecao.show()


## O jogador saiu: some e avisa, para o sistema devolver a nave ao espaço.
func fechar() -> void:
	if not _selecao.visible:
		return
	retirar()
	fechada.emit()


## O sistema assumiu: some e não avisa nada. É o que acontece quando uma região
## é escolhida, e também quando alguém manda a nave para um lugar por fora da
## tela, como faz a tecla de reiniciar.
func retirar() -> void:
	_convite.hide()
	_selecao.hide()
	_assunto.text = ""


func _unhandled_input(evento: InputEvent) -> void:
	if _selecao.visible and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func _montar_marcadores(planeta: Planeta) -> void:
	for velho: Node in _marcadores.get_children():
		velho.queue_free()

	var primeiro: Button = null
	for ficha: FichaDeRegiao in planeta.regioes:
		var marcador := Button.new()
		marcador.text = ficha.nome.to_upper()
		marcador.focus_mode = Control.FOCUS_ALL
		marcador.add_theme_font_size_override("font_size", 10)
		_marcadores.add_child(marcador)
		# O ponto da ficha vai de -1 a 1, e o marcador nasce centrado nele. O
		# tamanho vem do mínimo combinado: dentro de um `Control` comum ninguém
		# mede o botão por ele, e ler `size` aqui daria zero.
		var tamanho: Vector2 = marcador.get_combined_minimum_size()
		marcador.size = tamanho
		marcador.position = (
			Vector2(LADO_DO_CORPO, LADO_DO_CORPO) * 0.5
			+ ficha.ponto_no_corpo * LADO_DO_CORPO * 0.5
			- tamanho * 0.5
		)
		marcador.pressed.connect(_ao_escolher.bind(ficha))
		marcador.focus_entered.connect(_ao_olhar.bind(ficha))
		if primeiro == null:
			primeiro = marcador

	if primeiro != null:
		primeiro.call_deferred("grab_focus")


func _ao_olhar(ficha: FichaDeRegiao) -> void:
	_assunto.text = ficha.assunto


func _ao_escolher(ficha: FichaDeRegiao) -> void:
	retirar()
	regiao_escolhida.emit(ficha)
