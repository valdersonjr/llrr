class_name Menu
extends Control

## O menu inicial: a primeira tela do jogo.
##
## Ele é a única parte do jogo que troca a cena inteira. Dentro do jogo isso é
## proibido, e o `CLAUDE.md` da raiz explica por quê: destruir a árvore mata a
## nave e a faz renascer sem velocidade nem carga. Aqui não há nave ainda, e
## sair do menu é justamente o momento de montar o mundo do zero.
##
## **Sem botão que não leva a lugar nenhum.** Configurações e continuar partida
## entram quando existirem tela de opções e save, e não antes: menu com item
## morto ensina o jogador a desconfiar do que ele lê.
##
## O fundo é arte de espaço puxada para o azul, e por cima dele um véu escuro.
## O véu não é enfeite: sem ele o texto disputa leitura com as estrelas, que é o
## erro mais comum de menu com arte bonita atrás.

const JOGO: String = "res://mundo/sistema/sistema.tscn"

@onready var _jogar: Button = $Opcoes/Jogar
@onready var _sair: Button = $Opcoes/Sair


func _ready() -> void:
	_jogar.pressed.connect(jogar)
	_sair.pressed.connect(sair)
	# Teclado antes de mouse: quem abre o jogo no controle ou no teclado já tem
	# uma opção sob o cursor, sem precisar procurar.
	_jogar.grab_focus()


func jogar() -> void:
	get_tree().change_scene_to_file(JOGO)


func sair() -> void:
	get_tree().quit()
