class_name TelaDeConfiguracoes
extends Control

## A tela de opções: volumes, tela cheia, escala da janela e a lista de controles.
##
## Abre por cima do menu e da pausa, e fecha avisando quem abriu. Cada mudança vale
## na hora e é guardada, sem botão de aplicar: o jogador ouve o volume enquanto
## mexe nele.

signal fechada()

const VOLUMES: PackedStringArray = ["0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%"]
## As ações que o jogador usa, na ordem em que aparecem na lista de controles.
const CONTROLES: Array = [
	["empuxo", "EMPUXO"], ["girar_esquerda", "GIRAR PARA A ESQUERDA"], ["girar_direita", "GIRAR PARA A DIREITA"],
	["lateral_esquerda", "LATERAL ESQUERDA"], ["lateral_direita", "LATERAL DIREITA"],
	["alternar_estabilizacao", "ESTABILIZAÇÃO"], ["entrar", "ENTRAR NO PLANETA"], ["mapa", "MAPA"], ["pausa", "PAUSA"],
]
## Nome de tecla em português para as que não são letra.
const NOMES_DE_TECLA: Dictionary = {
	"Up": "CIMA", "Down": "BAIXO", "Left": "ESQUERDA", "Right": "DIREITA", "Escape": "ESC", "Space": "ESPAÇO",
}

@onready var _opcoes: Control = $Painel/Conteudo/Opcoes
@onready var _geral: LinhaDeOpcao = $Painel/Conteudo/Opcoes/Geral
@onready var _musica: LinhaDeOpcao = $Painel/Conteudo/Opcoes/Musica
@onready var _efeitos: LinhaDeOpcao = $Painel/Conteudo/Opcoes/Efeitos
@onready var _tela_cheia: LinhaDeOpcao = $Painel/Conteudo/Opcoes/TelaCheia
@onready var _escala: LinhaDeOpcao = $Painel/Conteudo/Opcoes/Escala
@onready var _controles_botao: Button = $Painel/Conteudo/Opcoes/Controles
@onready var _voltar: Button = $Painel/Conteudo/Opcoes/Voltar
@onready var _lista: Control = $Painel/Conteudo/Lista
@onready var _linhas_da_lista: Label = $Painel/Conteudo/Lista/Linhas
@onready var _fechar_lista: Button = $Painel/Conteudo/Lista/Voltar


func _ready() -> void:
	hide()
	for linha: LinhaDeOpcao in [_geral, _musica, _efeitos]:
		linha.valores = VOLUMES
	_tela_cheia.valores = PackedStringArray(["NÃO", "SIM"])
	_escala.valores = PackedStringArray(["2x", "3x", "4x"])
	_geral.valor_mudou.connect(func(i: int) -> void: _mudar("volume_geral", i / 10.0))
	_musica.valor_mudou.connect(func(i: int) -> void: _mudar("volume_da_musica", i / 10.0))
	_efeitos.valor_mudou.connect(func(i: int) -> void: _mudar("volume_dos_efeitos", i / 10.0))
	_tela_cheia.valor_mudou.connect(func(i: int) -> void: _mudar("tela_cheia", i == 1))
	_escala.valor_mudou.connect(func(i: int) -> void: _mudar("escala", i + 2))
	_controles_botao.pressed.connect(_mostrar_controles)
	_voltar.pressed.connect(fechar)
	_fechar_lista.pressed.connect(_mostrar_opcoes)
	_linhas_da_lista.text = _texto_dos_controles()


func abrir() -> void:
	var atuais: Configuracoes = ConfiguracoesManager.atuais
	_geral.indice = roundi(atuais.volume_geral * 10.0)
	_musica.indice = roundi(atuais.volume_da_musica * 10.0)
	_efeitos.indice = roundi(atuais.volume_dos_efeitos * 10.0)
	_tela_cheia.indice = 1 if atuais.tela_cheia else 0
	_escala.indice = atuais.escala - 2
	show()
	_mostrar_opcoes()


func fechar() -> void:
	if not visible:
		return
	hide()
	fechada.emit()


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		if _lista.visible:
			_mostrar_opcoes()
		else:
			fechar()


func _mudar(campo: String, valor: Variant) -> void:
	ConfiguracoesManager.atuais.set(campo, valor)
	ConfiguracoesManager.aplicar()
	ConfiguracoesManager.salvar()


func _mostrar_controles() -> void:
	_opcoes.hide()
	_lista.show()
	_fechar_lista.grab_focus()


func _mostrar_opcoes() -> void:
	_lista.hide()
	_opcoes.show()
	_geral.grab_focus()


## A lista sai do mapa de entrada do projeto, e não de um texto à parte: trocar uma
## tecla nas configurações do Godot já aparece aqui.
func _texto_dos_controles() -> String:
	var linhas := PackedStringArray()
	for par: Array in CONTROLES:
		var teclas := PackedStringArray()
		for evento: InputEvent in InputMap.action_get_events(par[0]):
			if evento is InputEventKey:
				var nome: String = OS.get_keycode_string((evento as InputEventKey).physical_keycode)
				teclas.append(NOMES_DE_TECLA.get(nome, nome.to_upper()))
		linhas.append("%s   %s" % [par[1], "  ".join(teclas)])
	return "\n".join(linhas)
