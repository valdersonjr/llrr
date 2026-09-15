class_name CenaDoTitulo
extends Node2D

## O laço animado da tela de título: a nave desce numa doca no espaço, apaga a
## chama no toque, o piloto sai, acena e volta, e a nave sobe de novo.
##
## A doca não é de planeta nenhum, de propósito: a tela de título vale para o jogo
## inteiro, e o jogo vai ter lugares que ainda não existem. O que dá rosto ao jogo
## é a nave e o piloto.
##
## O laço é uma linha do tempo fixa, calculada a cada quadro a partir do tempo:
## sem estado acumulado, qualquer instante do laço é reproduzível, e é isso que
## deixa a conferência perguntar onde a nave está em 2 s e em 8 s.
##
## A origem da cena é o canto de cima à esquerda da doca, que tem 96 px de largura.

const DURACAO: float = 18.0
const CHEGADA: float = 4.0
const SAIDA_DO_PILOTO: float = 5.5
const ACENO: float = 7.0
const RESPIRO: float = 10.0
const VOLTA_DO_PILOTO: float = 12.0
## As luzes voltam a piscar antes da partida, e a chama acende meio segundo depois.
const AVISO_DE_PARTIDA: float = 13.5
const IGNICAO: float = 14.0
const PARTIDA: float = 14.5
const FIM_DA_SUBIDA: float = 17.5
## A nave pousada: o meio do desenho, com as sapatas na linha de cima da doca.
const POUSADA: Vector2 = Vector2(48.0, -24.0)
## Quanto acima da doca a nave começa e termina, fora da tela.
const ALTURA_DE_VOO: float = 330.0
const PILOTO_ESCONDIDO_X: float = 56.0
const PILOTO_A_VISTA_X: float = 78.0
const SEQUENCIA_DA_CHAMA: Array[int] = [0, 1, 0, 2]
## O mesmo anel que a nave ganha na vista de espaço, pelo mesmo motivo: contra o
## fundo escuro o contorno do casco some.
const COR_DO_ANEL: Color = Color("7f708a")  # neutros_frios:1

enum Luz { APAGADA, VERMELHA, AMARELA, VERDE }

var tempo: float = 0.0

@onready var _foguete: Node2D = $Foguete
@onready var _anel: Sprite2D = $Foguete/Anel
@onready var _casco: Sprite2D = $Foguete/Casco
@onready var _chama: Sprite2D = $Foguete/Chama
@onready var _vapor: Sprite2D = $Vapor
@onready var _piloto: Piloto = $Piloto
@onready var _luzes: Array[Sprite2D] = [$PosteEsquerdo/Luz, $PosteDireito/Luz]


func _ready() -> void:
	_anel.texture = ApresentacaoDaNave.anel_de(_casco.texture, COR_DO_ANEL)
	_atualizar()


func _process(delta: float) -> void:
	tempo = fposmod(tempo + delta, DURACAO)
	_atualizar()


## A altura da nave acima da posição pousada num instante do laço, em pixels.
func altura_da_nave(t: float) -> float:
	if t < CHEGADA:
		var falta: float = 1.0 - t / CHEGADA
		return ALTURA_DE_VOO * falta * falta
	if t < PARTIDA:
		return 0.0
	if t < FIM_DA_SUBIDA:
		var subida: float = (t - PARTIDA) / (FIM_DA_SUBIDA - PARTIDA)
		return ALTURA_DE_VOO * subida * subida
	return ALTURA_DE_VOO + 100.0


## A chama só acende quando a nave está empurrando: descendo e subindo.
func chama_acesa(t: float) -> bool:
	return t < CHEGADA or (t >= IGNICAO and t < FIM_DA_SUBIDA)


func _atualizar() -> void:
	var t: float = tempo
	_foguete.position = (POUSADA - Vector2(0.0, altura_da_nave(t))).round()
	_foguete.visible = t < FIM_DA_SUBIDA
	_chama.visible = chama_acesa(t)
	_chama.frame = SEQUENCIA_DA_CHAMA[int(t * 14.0) % SEQUENCIA_DA_CHAMA.size()]

	var luz: Luz = Luz.APAGADA
	if t < CHEGADA or (t >= AVISO_DE_PARTIDA and t < FIM_DA_SUBIDA):
		luz = Luz.VERMELHA if int(t * 2.5) % 2 == 0 else Luz.AMARELA
	elif t < AVISO_DE_PARTIDA:
		luz = Luz.VERDE
	for lampada: Sprite2D in _luzes:
		lampada.frame = luz

	# Vapor dos motores no instante do toque, uma vez.
	_vapor.visible = t >= CHEGADA and t < CHEGADA + 0.4
	_vapor.frame = mini(3, int((t - CHEGADA) * 10.0)) if _vapor.visible else 0

	_mover_piloto(t)


func _mover_piloto(t: float) -> void:
	_piloto.visible = t >= SAIDA_DO_PILOTO and t < AVISO_DE_PARTIDA
	if not _piloto.visible:
		return
	var x: float = PILOTO_A_VISTA_X
	if t < ACENO:
		x = lerpf(PILOTO_ESCONDIDO_X, PILOTO_A_VISTA_X, (t - SAIDA_DO_PILOTO) / (ACENO - SAIDA_DO_PILOTO))
		_piloto.andar(false)
	elif t < RESPIRO:
		_piloto.acenar()
	elif t < VOLTA_DO_PILOTO:
		_piloto.parar()
	else:
		x = lerpf(PILOTO_A_VISTA_X, PILOTO_ESCONDIDO_X, (t - VOLTA_DO_PILOTO) / (AVISO_DE_PARTIDA - VOLTA_DO_PILOTO))
		_piloto.andar(true)
	_piloto.position = Vector2(roundf(x), 0.0)
	# Perto da nave ele passa por trás dela: é assim que ele entra e sai.
	_piloto.z_index = -1 if x < POUSADA.x + 18.0 else 1
