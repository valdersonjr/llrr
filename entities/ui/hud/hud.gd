class_name Hud
extends CanvasLayer
## Instrumentos de voo: o que o jogador precisa para decidir se pode pousar.
##
## Nada aqui é enfeite — combustível, casco, as quatro medidas que o trem de
## pouso avalia, e a massa, que explica por que a nave acelera diferente com
## o tanque cheio. Valor fora do limite do trem de pouso acende em laranja:
## a informação chega pela cor E pelo número, nunca só pela cor.

const COR_OK := Color("a8aec4")
const COR_ALERTA := Color("ef7d57")
const COR_BOM := Color("5ab552")
const COR_ATENCAO := Color("f2c14e")
const COR_APAGADO := Color("6b7185")

const LARGURA_BARRA := 56.0
const DURACAO_AVISO := 3.5

var _nave: Nave
var _tempo_aviso := 0.0

@onready var _barra_combustivel: ColorRect = $Raiz/BarraCombustivel
@onready var _barra_integridade: ColorRect = $Raiz/BarraIntegridade
@onready var _telemetria: RichTextLabel = $Raiz/Telemetria
@onready var _aviso: Label = $Raiz/Aviso


func _ready() -> void:
	_aviso.text = ""


func acompanhar(nave: Nave) -> void:
	_nave = nave


func avisar(texto: String, cor: Color) -> void:
	_aviso.text = texto
	_aviso.add_theme_color_override(&"font_color", cor)
	_tempo_aviso = DURACAO_AVISO


func _process(delta: float) -> void:
	if _tempo_aviso > 0.0:
		_tempo_aviso -= delta
		if _tempo_aviso <= 0.0:
			_aviso.text = ""
	if _nave == null:
		return
	_atualizar_barras()
	_telemetria.text = _texto_telemetria()


func _atualizar_barras() -> void:
	var casco := _nave.casco
	var combustivel := _nave.combustivel / casco.combustivel_maximo
	_barra_combustivel.size.x = roundf(LARGURA_BARRA * combustivel)
	_barra_combustivel.color = COR_ALERTA if combustivel < 0.12 \
		else (COR_ATENCAO if combustivel < 0.3 else COR_BOM)

	var integridade := _nave.integridade / casco.integridade_maxima
	_barra_integridade.size.x = roundf(LARGURA_BARRA * integridade)
	_barra_integridade.color = COR_ALERTA if integridade < 0.35 else COR_OK


func _texto_telemetria() -> String:
	var casco := _nave.casco
	var vertical := _nave.velocity.y
	var horizontal := _nave.velocity.x
	var velocidade := _nave.velocity.length()
	var inclinacao := _nave.inclinacao()

	var texto := _linha("VERT", "%+d P/S" % roundi(vertical), velocidade > casco.pouso_velocidade_maxima)
	texto += _linha("HORIZ", "%+d P/S" % roundi(horizontal), velocidade > casco.pouso_velocidade_maxima)
	texto += _linha("INCL", "%+d°" % roundi(inclinacao), absf(inclinacao) > casco.pouso_angulo_maximo)
	texto += _linha("GIRO", "%+d °/S" % roundi(_nave.giro), absf(_nave.giro) > casco.pouso_giro_maximo)
	texto += _linha("CARGA", "%.1f / %.0f T" % [_nave.carga, casco.capacidade_carga],
		_nave.carga >= casco.capacidade_carga)
	texto += _linha("MASSA", "%.1f T" % _nave.massa(), false)
	texto += _linha("ACEL", "%d P/S²" % roundi(_nave.aceleracao_disponivel()), _nave.combustivel <= 0.0)
	texto += _linha("ESTAB", "LIGADA" if _nave.estabilizacao_ativa else "DESLIGADA",
		not _nave.estabilizacao_ativa)
	return texto + "[color=#%s]%s[/color]" % [COR_APAGADO.to_html(false), _texto_estado()]


func _linha(rotulo: String, valor: String, alerta: bool) -> String:
	var cor := COR_ALERTA if alerta else COR_OK
	return "[color=#%s]%s[/color] [color=#%s]%s[/color]\n" % [
		COR_APAGADO.to_html(false), rotulo, cor.to_html(false), valor]


func _texto_estado() -> String:
	match _nave.estado:
		Nave.Estado.TOCANDO:
			return "TOCANDO"
		Nave.Estado.POUSADA:
			return "POUSADA"
		Nave.Estado.DESTRUIDA:
			return "DESTRUÍDA"
		_:
			return "EM VOO"
