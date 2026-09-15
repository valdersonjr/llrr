class_name TelaDeCreditos
extends Control

## Os créditos. Por enquanto a tela só diz que eles vêm em breve.
##
## **IMPORTANT:** a licença da fonte m6x11plus pede o nome de Daniel Linssen dentro
## do jogo, e não só num arquivo do repositório. Hoje ele está fora desta tela por
## decisão de quem toca o jogo, e precisa voltar antes de qualquer versão chegar a
## jogadores (ver `docs/creditos.md`).

signal fechada()

@onready var _conteudo: Control = $Painel/Conteudo
@onready var _voltar: Button = $Painel/Conteudo/Voltar


func _ready() -> void:
	hide()
	_voltar.pressed.connect(fechar)


func abrir() -> void:
	show()
	_voltar.grab_focus()


func fechar() -> void:
	if not visible:
		return
	hide()
	fechada.emit()


## Todo o texto da tela numa string, para quem precisa conferir o que ela diz.
func texto() -> String:
	var linhas := PackedStringArray()
	for filho: Node in _conteudo.get_children():
		if filho is Label:
			linhas.append((filho as Label).text)
	return "\n".join(linhas)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):
		get_viewport().set_input_as_handled()
		fechar()
