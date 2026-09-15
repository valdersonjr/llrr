class_name TelaDePausa
extends Control

## A pausa: para o jogo e oferece continuar, as opções, o menu e sair.
##
## O conceito é explícito (seção 6): pausar para o tempo, e inspecionar parado não
## é punido. A tela roda com o jogo parado (`process_mode` sempre), e quem a abre é
## a cena do sistema, que sabe quando há outra tela na frente.
##
## Voltar ao menu e sair perguntam antes: ainda não existe save, e o voo de agora
## se perde. Voltar ao menu é a segunda troca de cena inteira do jogo, pelo mesmo
## motivo da primeira: é o jogador saindo do mundo, e não andando dentro dele.

const MENU: String = "res://ui/menu/menu.tscn"

var _acao_confirmada: Callable = Callable()
var _quem_perguntou: Button = null

@onready var _painel: Control = $Painel
@onready var _opcoes: Control = $Painel/Conteudo/Opcoes
@onready var _confirmacao: Control = $Painel/Conteudo/Confirmacao
@onready var _pergunta: Label = $Painel/Conteudo/Confirmacao/Pergunta
@onready var _continuar: Button = $Painel/Conteudo/Opcoes/Continuar
@onready var _configuracoes_botao: Button = $Painel/Conteudo/Opcoes/Configuracoes
@onready var _menu_botao: Button = $Painel/Conteudo/Opcoes/Menu
@onready var _sair_botao: Button = $Painel/Conteudo/Opcoes/Sair
@onready var _sim: Button = $Painel/Conteudo/Confirmacao/Sim
@onready var _nao: Button = $Painel/Conteudo/Confirmacao/Nao
@onready var _configuracoes: TelaDeConfiguracoes = $Configuracoes


func _ready() -> void:
	hide()
	_continuar.pressed.connect(fechar)
	_configuracoes_botao.pressed.connect(_abrir_configuracoes)
	_menu_botao.pressed.connect(_perguntar.bind("VOLTAR AO MENU? O VOO DE AGORA SE PERDE.", _voltar_ao_menu, _menu_botao))
	_sair_botao.pressed.connect(_perguntar.bind("SAIR DO JOGO? O VOO DE AGORA SE PERDE.", _sair_do_jogo, _sair_botao))
	_sim.pressed.connect(func() -> void: _acao_confirmada.call())
	_nao.pressed.connect(_cancelar_pergunta)
	_configuracoes.fechada.connect(_ao_fechar_configuracoes)


func aberta() -> bool:
	return visible


func abrir() -> void:
	get_tree().paused = true
	show()
	_painel.show()
	_mostrar_opcoes(_continuar)


func fechar() -> void:
	if not visible:
		return
	_configuracoes.hide()
	hide()
	get_tree().paused = false


func _unhandled_input(evento: InputEvent) -> void:
	# Com as opções abertas, o Esc é delas.
	if not visible or _configuracoes.visible:
		return
	if evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirmacao.visible:
			_cancelar_pergunta()
		else:
			fechar()


func _perguntar(pergunta: String, acao: Callable, origem: Button) -> void:
	_acao_confirmada = acao
	_quem_perguntou = origem
	_pergunta.text = pergunta
	_opcoes.hide()
	_confirmacao.show()
	# O foco começa no "não": confirmar sem querer não pode custar o voo.
	_nao.grab_focus()


func _cancelar_pergunta() -> void:
	_mostrar_opcoes(_quem_perguntou if _quem_perguntou != null else _continuar)


func _mostrar_opcoes(foco: Button) -> void:
	_confirmacao.hide()
	_opcoes.show()
	foco.grab_focus()


func _abrir_configuracoes() -> void:
	_painel.hide()
	_configuracoes.abrir()


func _ao_fechar_configuracoes() -> void:
	_painel.show()
	_configuracoes_botao.grab_focus()


func _voltar_ao_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)


func _sair_do_jogo() -> void:
	get_tree().quit()
