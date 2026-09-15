class_name Hud
extends Control

## Painel de telemetria. A versão 0.10 do conceito devolveu a moldura ao HUD, e só
## a moldura: não existe barra, porque não existe grandeza contínua para uma barra
## mostrar. Não há dano, não há estrutura, não há alerta de casco.
##
## Uma informação abaixo da outra, e só o que ajuda a descer: velocidade vertical
## e horizontal, altitude sobre o chão e inclinação. O resto aparece quando conta:
## o giro quando passa do limite, a estabilização quando está desligada e a
## situação quando a nave encosta. Um painel que mostra zeros o tempo todo toma
## tela e não diz nada.
##
## Na superfície cada número é julgado pela especificação de pouso da região:
## verde dentro, vermelho fora. Cor sozinha nunca basta (seção 14 do conceito),
## então o que está fora também troca o ícone da linha por um triângulo de alerta
## piscando. No espaço não há lugar de pouso, e os números ficam neutros.

const NEUTRO: Color = Color(0.78039217, 0.8627451, 0.8156863, 1)  # neutros_frios:3
const DENTRO: Color = Color(0.5686275, 0.85882354, 0.4117647, 1)  # verdes:3
const FORA: Color = Color(0.9098039, 0.23137255, 0.23137255, 1)  # vermelho_laranja:1
const COR_DE_CONTATO: Color = Color(0.9764706, 0.7607843, 0.16862745, 1)  # vermelho_laranja:4

## A tira de ícones de 8x8, na ordem deste enum.
const ICONES: Texture2D = preload("res://ui/hud/art/icones.png")
enum Icone { DESCER, SUBIR, ESQUERDA, DIREITA, ALTITUDE, INCLINACAO, GIRO, ALERTA,
	ESTAB_LIGADA, ESTAB_DESLIGADA, CONTATO, POUSADA, TOQUE_DURO }
enum Leitura { NEUTRA, DENTRO, FORA }
const LADO_DO_ICONE: int = 8
const PISCA_A_CADA_MS: int = 300
## Abaixo disto a seta não troca de sentido: parada, a nave tem resíduo de
## velocidade de física, e a seta ficaria virando de um lado para o outro.
const SENTIDO_MINIMO: float = 0.05

var _nave: Nave
var _avaliando_pouso: bool = true
var _recortes: Dictionary = {}
var _seta_vertical: Icone = Icone.DESCER
var _seta_horizontal: Icone = Icone.DIREITA

@onready var _vertical: Control = $Painel/Linhas/Vertical
@onready var _horizontal: Control = $Painel/Linhas/Horizontal
@onready var _altitude: Control = $Painel/Linhas/Altitude
@onready var _inclinacao: Control = $Painel/Linhas/Inclinacao
@onready var _giro: Control = $Painel/Linhas/Giro
@onready var _estab: Control = $Painel/Linhas/Estab
@onready var _situacao: Control = $Painel/Linhas/Situacao


func _ready() -> void:
	(_estab.get_node("Icone") as TextureRect).texture = _icone(Icone.ESTAB_DESLIGADA)
	_giro.hide()
	_estab.hide()
	_situacao.hide()


## Quem monta a cena diz qual nave o painel lê. O HUD não procura a nave sozinho.
func acompanhar(nave: Nave) -> void:
	_nave = nave
	_nave.pouso_mudou.connect(_ao_mudar_pouso)
	_ao_mudar_pouso(_nave.estado)


## Ligado na superfície, desligado no espaço. Verde e vermelho julgam o número
## contra o lugar de pouso, e no vácuo não existe lugar nenhum: pintar a viagem
## de vermelho é ruído, não aviso. Quem sabe em que vista estamos é a cena do
## sistema, e é ela que diz.
func avaliar_pouso(avaliando: bool) -> void:
	_avaliando_pouso = avaliando


func _process(_delta: float) -> void:
	if _nave == null:
		return
	var vertical: float = _nave.velocidade_vertical()
	var horizontal: float = _nave.velocidade_horizontal()
	if absf(vertical) >= SENTIDO_MINIMO:
		_seta_vertical = Icone.DESCER if vertical > 0.0 else Icone.SUBIR
	if absf(horizontal) >= SENTIDO_MINIMO:
		_seta_horizontal = Icone.DIREITA if horizontal > 0.0 else Icone.ESQUERDA
	_escrever(_vertical, _seta_vertical, "%.1f" % absf(vertical), _julgar(_nave.vertical_no_limite()))
	_escrever(_horizontal, _seta_horizontal, "%.1f" % absf(horizontal), _julgar(_nave.horizontal_no_limite()))
	var altitude: float = _nave.altitude()
	_escrever(_altitude, Icone.ALTITUDE, "--" if altitude < 0.0 else "%.1f" % altitude, Leitura.NEUTRA)
	_escrever(_inclinacao, Icone.INCLINACAO, "%.1f" % _nave.inclinacao_em_graus(),
		_julgar(_nave.inclinacao_no_limite()))

	# Com a estabilização ligada o giro é quase sempre zero: a linha só aparece
	# quando ele passa do limite, que é quando ela tem algo a dizer.
	_giro.visible = _julgar(_nave.giro_no_limite()) == Leitura.FORA
	if _giro.visible:
		_escrever(_giro, Icone.GIRO, "%.1f" % _nave.giro_por_segundo(), Leitura.FORA)
	# Ligada é o normal; desligada é o que o piloto precisa lembrar.
	_estab.visible = not _nave.estabilizacao_ligada


func _julgar(no_limite: bool) -> Leitura:
	if not _avaliando_pouso:
		return Leitura.NEUTRA
	return Leitura.DENTRO if no_limite else Leitura.FORA


## Uma linha é ícone, número e unidade. A unidade é fixa na cena; o número fica
## alinhado à direita numa coluna própria para não tremer quando muda de largura.
func _escrever(linha: Control, icone: Icone, texto: String, leitura: Leitura) -> void:
	var fora: bool = leitura == Leitura.FORA
	var alerta_aceso: bool = fora and floori(Time.get_ticks_msec() / float(PISCA_A_CADA_MS)) % 2 == 0
	(linha.get_node("Icone") as TextureRect).texture = _icone(Icone.ALERTA if alerta_aceso else icone)
	var valor: Label = linha.get_node("Valor")
	valor.text = texto
	var cor: Color = NEUTRO
	if leitura == Leitura.DENTRO:
		cor = DENTRO
	elif fora:
		cor = FORA
	valor.add_theme_color_override("font_color", cor)


func _icone(qual: Icone) -> Texture2D:
	if not _recortes.has(qual):
		var recorte := AtlasTexture.new()
		recorte.atlas = ICONES
		recorte.region = Rect2(qual * LADO_DO_ICONE, 0, LADO_DO_ICONE, LADO_DO_ICONE)
		_recortes[qual] = recorte
	return _recortes[qual]


## A situação só aparece com a nave encostada. Pousada com toque fora da
## especificação diz isso, em vermelho: ainda não há consequência para pouso ruim
## (seção 18 do conceito), mas o painel não esconde o que aconteceu.
func _ao_mudar_pouso(novo: Nave.Estado) -> void:
	match novo:
		Nave.Estado.VOANDO:
			_situacao.hide()
		Nave.Estado.TOCANDO:
			_mostrar_situacao(Icone.CONTATO, "CONTATO", COR_DE_CONTATO)
		Nave.Estado.POUSADA:
			if _nave.toque_no_limite():
				_mostrar_situacao(Icone.POUSADA, "POUSADA", DENTRO)
			else:
				_mostrar_situacao(Icone.TOQUE_DURO, "DURO", FORA)


func _mostrar_situacao(icone: Icone, texto: String, cor: Color) -> void:
	(_situacao.get_node("Icone") as TextureRect).texture = _icone(icone)
	var rotulo: Label = _situacao.get_node("Texto")
	rotulo.text = texto
	rotulo.add_theme_color_override("font_color", cor)
	_situacao.show()
