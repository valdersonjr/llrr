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
## O que se escolhe é um ponto na carta de superfície do planeta, vista de cima e
## com grade de coordenadas. A carta é uma cena da ficha do planeta; esta tela só
## a põe na moldura e acende um marcador em cada região.
##
## O jogador escolhe com o mouse ou com as setas, e as setas funcionam sem
## ninguém ligar fio nenhum: sem vizinho de foco declarado, o Godot acha o
## marcador mais próximo na direção apertada, que é a leitura certa quando os
## marcadores estão espalhados pela carta.

signal regiao_escolhida(ficha: FichaDeRegiao)
signal fechada()

## O marcador tem lado ímpar para o miolo vazado cair num pixel exato da carta.
const MARCADOR: Texture2D = preload("res://ui/orbita/art/marcador.png")
const MEIO_DO_MARCADOR: Vector2i = Vector2i(5, 5)
const MEIO_DO_FOCO: Vector2i = Vector2i(9, 9)
## O foco pisca devagar: parado, some entre os pontos da grade; rápido, cansa.
const PISCA_A_CADA: float = 0.45

@onready var _convite: Control = $Convite
@onready var _convite_texto: Label = $Convite/Texto
@onready var _selecao: Control = $Selecao
@onready var _titulo: Label = $Selecao/Cabecalho/Titulo
@onready var _terreno: Control = $Selecao/Carta/Terreno
@onready var _marcadores: Control = $Selecao/Carta/Marcadores
@onready var _foco: TextureRect = $Selecao/Carta/Foco
@onready var _nome: Label = $Selecao/Painel/Nome
@onready var _setor: Label = $Selecao/Painel/Setor
@onready var _assunto: Label = $Selecao/Painel/Assunto
@onready var _sair: Button = $Selecao/Sair

var _foco_aceso: bool = false
var _relogio: float = 0.0


func _ready() -> void:
	_convite.hide()
	_selecao.hide()
	# A tecla de sair continua valendo, mas ela sozinha não basta: quem entrou de
	# mouse não tem como descobrir que ela existe. O botão é a saída visível, e a
	# linha de comandos embaixo diz o resto.
	_sair.pressed.connect(fechar)
	_sair.mouse_entered.connect(_sair.grab_focus)
	_sair.focus_entered.connect(_apagar_foco)


func _process(delta: float) -> void:
	if not _foco_aceso or not _selecao.visible:
		return
	_relogio += delta
	if _relogio >= PISCA_A_CADA:
		_relogio -= PISCA_A_CADA
		_foco.visible = not _foco.visible


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
	_titulo.text = corpo.planeta.nome.to_upper()
	_montar_carta(corpo.planeta)
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
	_apagar_foco()


func _unhandled_input(evento: InputEvent) -> void:
	if _selecao.visible and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func _montar_carta(planeta: Planeta) -> void:
	for velha: Node in _terreno.get_children():
		velha.queue_free()
	if planeta.carta == null:
		push_warning("%s não tem carta de superfície: a tela de regiões abre sem chão" % planeta.nome)
		return
	_terreno.add_child(planeta.carta.instantiate())


func _montar_marcadores(planeta: Planeta) -> void:
	for velho: Node in _marcadores.get_children():
		velho.queue_free()
	_apagar_foco()
	_nome.text = ""
	_setor.text = ""
	_assunto.text = ""

	var primeiro: TextureButton = null
	for ficha: FichaDeRegiao in planeta.regioes:
		var marcador := TextureButton.new()
		marcador.name = ficha.nome.to_pascal_case()
		marcador.texture_normal = MARCADOR
		marcador.focus_mode = Control.FOCUS_ALL
		marcador.position = Vector2(ficha.ponto_na_carta - MEIO_DO_MARCADOR)
		_marcadores.add_child(marcador)
		marcador.pressed.connect(_ao_escolher.bind(ficha))
		marcador.focus_entered.connect(_ao_olhar.bind(ficha, marcador))
		# Passar o mouse já é olhar: o painel responde antes do clique.
		marcador.mouse_entered.connect(marcador.grab_focus)
		if primeiro == null:
			primeiro = marcador

	if primeiro != null:
		primeiro.call_deferred("grab_focus")


func _ao_olhar(ficha: FichaDeRegiao, marcador: TextureButton) -> void:
	_nome.text = ficha.nome.to_upper()
	_setor.text = "SETOR %s" % GradeDaCarta.setor(ficha.ponto_na_carta)
	_assunto.text = ficha.assunto
	_foco.position = marcador.position + Vector2(MEIO_DO_MARCADOR - MEIO_DO_FOCO)
	_foco.show()
	_foco_aceso = true
	_relogio = 0.0


func _apagar_foco() -> void:
	_foco_aceso = false
	_foco.hide()


func _ao_escolher(ficha: FichaDeRegiao) -> void:
	retirar()
	regiao_escolhida.emit(ficha)
