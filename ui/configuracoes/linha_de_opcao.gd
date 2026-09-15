class_name LinhaDeOpcao
extends Button

## Uma linha da tela de opções: o nome à esquerda e o valor à direita, entre setas.
##
## Com foco, esquerda e direita trocam o valor e param nas pontas; clicar ou
## confirmar anda para o próximo e dá a volta, para um clique só percorrer tudo.
## É um botão para herdar foco de teclado, estado de mouse e o estilo do tema, em
## vez de reinventar nada disso.

signal valor_mudou(indice: int)

@export var rotulo: String = ""
@export var valores: PackedStringArray = PackedStringArray()

var indice: int = 0:
	set(novo):
		indice = clampi(novo, 0, maxi(valores.size() - 1, 0))
		_escrever()

@onready var _valor: Label = $Valor


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	pressed.connect(_mudar.bind(1, true))
	_escrever()


func _gui_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_left"):
		_mudar(-1, false)
		accept_event()
	elif evento.is_action_pressed("ui_right"):
		_mudar(1, false)
		accept_event()


func _mudar(passo: int, dar_a_volta: bool) -> void:
	if valores.is_empty():
		return
	var novo: int = indice + passo
	if dar_a_volta:
		novo = posmod(novo, valores.size())
	novo = clampi(novo, 0, valores.size() - 1)
	if novo == indice:
		return
	indice = novo
	valor_mudou.emit(indice)


func _escrever() -> void:
	text = rotulo
	if _valor != null and not valores.is_empty():
		_valor.text = "<  %s  >" % valores[indice]
