class_name Hud
extends CanvasLayer
## Instrumentos de voo: o que o jogador precisa para decidir se pode pousar.
##
## Nada aqui é enfeite — as quatro medidas que o trem de pouso avalia, e a
## massa, que explica por que a nave acelera diferente carregada. Valor fora do
## limite do trem de pouso acende em laranja: a informação chega pela cor E pelo
## número, nunca só pela cor.
##
## Não há barra nenhuma. O jogo não tem dano nem recurso consumível, então não
## sobrou grandeza contínua para uma barra mostrar.

const COR_OK := Color("a8aec4")
const COR_ALERTA := Color("ef7d57")
const COR_BOM := Color("5ab552")
const COR_ATENCAO := Color("f2c14e")
const COR_APAGADO := Color("6b7185")

const DURACAO_AVISO := 3.5

var _nave: Nave
var _tempo_aviso := 0.0

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
	_telemetria.text = _texto_telemetria()


func _texto_telemetria() -> String:
	var modelo := _nave.modelo
	var vertical := _nave.velocity.y
	var horizontal := _nave.velocity.x
	var velocidade := _nave.velocity.length()
	var inclinacao := _nave.inclinacao()

	# O chassi vem antes dos números: sem isto o jogador não sabe que existem
	# outros modelos, nem qual está pilotando depois de trocar. Sem rótulo
	# porque "CASCO CARGUEIRO RESISTENTE" não cabe na coluna.
	var texto := "[color=#%s]%s[/color]\n" % [
		COR_OK.to_html(false), modelo.nome.to_upper()]
	texto += _linha("VERT", "%+d P/S" % roundi(vertical), velocidade > modelo.pouso_velocidade_maxima)
	texto += _linha("HORIZ", "%+d P/S" % roundi(horizontal), velocidade > modelo.pouso_velocidade_maxima)
	texto += _linha("INCL", "%+d°" % roundi(inclinacao), absf(inclinacao) > modelo.pouso_angulo_maximo)
	texto += _linha("GIRO", "%+d °/S" % roundi(_nave.giro), absf(_nave.giro) > modelo.pouso_giro_maximo)
	texto += _linha("CARGA", "%.1f / %.0f T" % [_nave.carga, modelo.capacidade_carga],
		_nave.carga >= modelo.capacidade_carga)
	texto += _linha("MASSA", "%.1f T" % _nave.massa(), false)
	texto += _linha("ACEL", "%d P/S²" % roundi(_nave.aceleracao_disponivel()), false)
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
		_:
			return "EM VOO"
