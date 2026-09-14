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
## O fundo é a tela desenhada para o jogo, com o título e os botões apagados
## dela: o que está na arte é paisagem, e o que se lê e se clica é interface de
## verdade, com foco de teclado e nome que um dia vira chave de tradução.
##
## A música é só daqui. Ela morre junto com a cena quando o jogo começa, e é isso
## que se quer: o silêncio do espaço não é ausência de trilha, é o assunto.

const JOGO: String = "res://mundo/sistema/sistema.tscn"

@onready var _jogar: Button = $Opcoes/Jogar
@onready var _sair: Button = $Opcoes/Sair
@onready var _musica: AudioStreamPlayer = $Musica


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


## A música do menu, para quem precise conferir que ela está tocando.
func musica() -> AudioStreamPlayer:
	return _musica
