class_name Menu
extends Control

## A tela de título: a primeira tela do jogo.
##
## Ela é a única parte do jogo que troca a cena inteira ao começar. Dentro do jogo
## isso é proibido, e o `CLAUDE.md` da raiz explica por quê: destruir a árvore
## mata a nave e a faz renascer sem velocidade nem carga. Aqui não há nave ainda,
## e sair do menu é justamente o momento de montar o mundo do zero. O caminho de
## volta é a pausa, que troca a cena de novo para cá.
##
## **Sem botão que não leva a lugar nenhum.** "Continuar" entra quando existir
## save, e não antes: menu com item morto ensina o jogador a desconfiar do que ele
## lê.
##
## O fundo não é de planeta nenhum: é o espaço do jogo, a cena animada da doca
## (`CenaDoTitulo`) e, na vitrine, um dos planetas que o jogo tem, sorteado a cada
## abertura. A tela de título vale para o jogo inteiro, e o jogo vai crescer.
##
## A música é só daqui. Ela morre junto com a cena quando o jogo começa.

const JOGO: String = "res://mundo/sistema/sistema.tscn"
const PLANETAS: String = "res://mundo/planetas/"

@onready var _painel: Control = $Painel
@onready var _novo_jogo: Button = $Painel/Opcoes/NovoJogo
@onready var _configuracoes_botao: Button = $Painel/Opcoes/Configuracoes
@onready var _creditos_botao: Button = $Painel/Opcoes/Creditos
@onready var _sair: Button = $Painel/Opcoes/Sair
@onready var _vitrine: Node2D = $Vitrine
@onready var _configuracoes: TelaDeConfiguracoes = $Configuracoes
@onready var _creditos: TelaDeCreditos = $Creditos
@onready var _musica: AudioStreamPlayer = $Musica


func _ready() -> void:
	_novo_jogo.pressed.connect(jogar)
	_configuracoes_botao.pressed.connect(abrir_configuracoes)
	_creditos_botao.pressed.connect(abrir_creditos)
	_sair.pressed.connect(sair)
	_configuracoes.fechada.connect(_voltar_ao_painel.bind(_configuracoes_botao))
	_creditos.fechada.connect(_voltar_ao_painel.bind(_creditos_botao))
	_montar_vitrine()
	# Teclado antes de mouse: quem abre o jogo no controle ou no teclado já tem
	# uma opção sob o cursor, sem precisar procurar.
	_novo_jogo.grab_focus()


func jogar() -> void:
	get_tree().change_scene_to_file(JOGO)


func abrir_configuracoes() -> void:
	_painel.hide()
	_configuracoes.abrir()


func abrir_creditos() -> void:
	_painel.hide()
	_creditos.abrir()


func sair() -> void:
	get_tree().quit()


## A música do menu, para quem precise conferir que ela está tocando.
func musica() -> AudioStreamPlayer:
	return _musica


## Os corpos de planeta que o jogo tem, achados nas pastas e não numa lista à
## mão: planeta novo aparece na vitrine sem ninguém lembrar de cadastrar. No jogo
## exportado as cenas viram `.tscn.remap`, e o nome é lido sem o sufixo.
static func corpos_de_planeta() -> PackedStringArray:
	var achados := PackedStringArray()
	for pasta: String in DirAccess.get_directories_at(PLANETAS):
		for arquivo: String in DirAccess.get_files_at(PLANETAS + pasta):
			var nome: String = arquivo.trim_suffix(".remap")
			if nome.ends_with("_corpo.tscn"):
				achados.append(PLANETAS + pasta + "/" + nome)
	return achados


func _voltar_ao_painel(botao: Button) -> void:
	_painel.show()
	botao.grab_focus()


func _montar_vitrine() -> void:
	var corpos: PackedStringArray = corpos_de_planeta()
	if corpos.is_empty():
		return
	var corpo: Node2D = (load(corpos[randi() % corpos.size()]) as PackedScene).instantiate()
	_vitrine.add_child(corpo)
	# No sistema a arte do corpo tem a escala que desfaz o zoom da câmera do
	# espaço; aqui não há zoom, e o desenho volta ao pixel de tela.
	(corpo.get_node("Arte") as Node2D).scale = Vector2.ONE
