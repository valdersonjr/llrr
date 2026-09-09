class_name ApresentacaoDaNave
extends Node2D
## Tudo que a nave mostra, e nada do que ela simula.
##
## Existe separado porque chama, textura de dano e luz de motor não têm relação
## nenhuma com inércia, combustível ou avaliação de pouso — só precisam saber
## quanto empuxo está saindo e em que estado o casco está. Enquanto isso morava
## em `nave.gd`, a classe carregava três exports de textura, três variáveis de
## animação e um relógio de quadro no meio do código de física.
##
## O fluxo é de mão única: a nave manda, esta classe desenha. Ela não conhece
## `Nave`, não lê o pai, e por isso pode ser trocada por outra apresentação
## sem tocar na simulação.

const QUADROS_CHAMA_POR_SEGUNDO := 14.0
## Abaixo disto o motor está em marcha lenta e a chama não acende.
const EMPUXO_MINIMO_VISIVEL := 0.02

## Texturas do casco do íntegro ao crítico. Casco sem as três simplesmente não
## muda de aparência, em vez de quebrar.
@export var texturas_de_dano: Array[Texture2D] = []
@export var quadros_chama: Array[Texture2D] = []
## Altura desenhada da chama, em pixels. O empuxo corta o `region_rect` nessa
## altura, então a chama encurta sem sair do grid de pixel.
@export var altura_chama: int = 13
## Quanto o motor ilumina o que está em volta, no empuxo máximo.
@export var energia_da_luz: float = 0.8

var _relogio_chama: float = 0.0
var _quadro_chama: int = 0
var _dano_mostrado: int = -1

@onready var _corpo: Sprite2D = $Corpo
@onready var _chamas: Array[Node] = $Chamas.get_children()
@onready var _luz_motor: PointLight2D = $LuzDoMotor


## `empuxo` é 0 a 1 e já considera combustível: a nave decide se o motor pode
## empurrar, esta classe só desenha o que ela decidiu.
func atualizar(delta: float, empuxo: float, estado_de_dano: int) -> void:
	_mostrar_dano(estado_de_dano)
	_mostrar_chama(delta, empuxo)


func apagar() -> void:
	_mostrar_chama(0.0, 0.0)


func _mostrar_dano(estado: int) -> void:
	if estado == _dano_mostrado or estado >= texturas_de_dano.size():
		return
	_dano_mostrado = estado
	_corpo.texture = texturas_de_dano[estado]


func _mostrar_chama(delta: float, empuxo: float) -> void:
	var acesa := empuxo > EMPUXO_MINIMO_VISIVEL
	for chama in _chamas:
		(chama as Sprite2D).visible = acesa
	# O motor é emissivo: ele ilumina o terreno e o próprio casco, não só
	# desenha uma chama. É o que faz o pouso ler à noite.
	_luz_motor.energy = energia_da_luz * empuxo if acesa else 0.0
	if not acesa:
		return

	var corte := Rect2(0.0, 0.0, 16.0, roundf(altura_chama * empuxo))
	for chama in _chamas:
		(chama as Sprite2D).region_rect = corte
	if quadros_chama.size() < 2:
		return
	_relogio_chama += delta
	if _relogio_chama < 1.0 / QUADROS_CHAMA_POR_SEGUNDO:
		return
	_relogio_chama = 0.0
	_quadro_chama = (_quadro_chama + 1) % quadros_chama.size()
	for chama in _chamas:
		(chama as Sprite2D).texture = quadros_chama[_quadro_chama]
