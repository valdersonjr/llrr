class_name Pausa
extends CanvasLayer
## Menu de pausa: para o tempo e serve de referência dos controles.
##
## Seção 6 do conceito: menus de administração e pausa param o tempo, e
## inspecionar a situação com o jogo pausado não é punido. Por isso o painel
## não some sozinho, não tem contagem regressiva, e ocupa só o miolo da tela
## — o HUD continua legível nos cantos, congelado, que é o ponto de pausar.
##
## Ao pausar, os comandos de voo são soltos: despausar não pode religar o
## propulsor porque a tecla ficou presa.

signal pausou()
signal continuou()
## Reiniciar é oferecido aqui porque este nó processa mesmo pausado — é o
## único jeito de a tecla responder com o tempo parado.
signal pediu_reinicio()

@onready var _painel: Control = $Painel

var _nave: Nave


func _ready() -> void:
	_painel.visible = false


func acompanhar(nave: Nave) -> void:
	_nave = nave


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pausa"):
		alternar()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("reiniciar"):
		pediu_reinicio.emit()
		get_viewport().set_input_as_handled()


func alternar() -> void:
	definir(not get_tree().paused)


func definir(pausado: bool) -> void:
	get_tree().paused = pausado
	_painel.visible = pausado
	if pausado:
		if _nave != null:
			_nave.soltar_comandos()
		pausou.emit()
	else:
		continuou.emit()
