class_name Hud
extends Control

## Painel de telemetria. A versão 0.10 do conceito devolveu a moldura ao HUD, e só
## a moldura: não existe barra, porque não existe grandeza contínua para uma barra
## mostrar. Não há dano, não há estrutura, não há alerta de casco.
##
## O que o painel faz é acender em laranja a medida que está fora do limite de
## pouso, que é a promessa de consequência legível da seção 2.

const DENTRO: Color = Color(0.88, 0.91, 0.84)
const FORA: Color = Color(0.95, 0.58, 0.20)

var _nave: Nave
var _avaliando_pouso: bool = true

@onready var _velocidade: Label = $Moldura/Linhas/Velocidade
@onready var _inclinacao: Label = $Moldura/Linhas/Inclinacao
@onready var _giro: Label = $Moldura/Linhas/Giro
@onready var _situacao: Label = $Situacao


## Quem monta a cena diz qual nave o painel lê. O HUD não procura a nave sozinho.
func acompanhar(nave: Nave) -> void:
	_nave = nave
	_nave.pouso_mudou.connect(_ao_mudar_pouso)
	_ao_mudar_pouso(_nave.estado)


## Ligado na superfície, desligado no espaço. O laranja de fora do limite quer
## dizer "isto quebra o trem de pouso", e no vácuo não existe chão para quebrar
## nada: pintar a viagem inteira de laranja é ruído, não aviso. Quem sabe em que
## vista estamos é a cena do sistema, e é ela que diz.
func avaliar_pouso(avaliando: bool) -> void:
	_avaliando_pouso = avaliando


func _process(_delta: float) -> void:
	if _nave == null:
		return
	_escrever(_velocidade, "VEL", _nave.velocidade(), "m/s", _nave.velocidade_no_limite())
	_escrever(_inclinacao, "INC", _nave.inclinacao_em_graus(), "°", _nave.inclinacao_no_limite())
	_escrever(_giro, "GIR", _nave.giro_por_segundo(), "°/s", _nave.giro_no_limite())


func _escrever(rotulo: Label, sigla: String, valor: float, unidade: String, no_limite: bool) -> void:
	rotulo.text = "%s %5.1f %s" % [sigla, valor, unidade]
	var acusar: bool = _avaliando_pouso and not no_limite
	rotulo.add_theme_color_override("font_color", FORA if acusar else DENTRO)


func _ao_mudar_pouso(novo: Nave.Estado) -> void:
	match novo:
		Nave.Estado.VOANDO:
			_situacao.text = ""
		Nave.Estado.TOCANDO:
			_situacao.text = "CONTATO"
			_situacao.add_theme_color_override("font_color", FORA)
		Nave.Estado.POUSADA:
			_situacao.text = "POUSADA"
			_situacao.add_theme_color_override("font_color", DENTRO)
