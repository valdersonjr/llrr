class_name ApresentacaoDaNave
extends Node2D

## Tudo que a nave mostra, e nada do que ela simula.
##
## Existe separado porque casco, chama e luz de motor não têm relação nenhuma
## com inércia, massa ou avaliação de pouso: só precisam saber quanto empuxo
## está saindo. Enquanto isso morava em `nave.gd`, o código de física carregava
## três referências de nó de desenho no meio das forças.
##
## O fluxo é de mão única: a nave manda, esta classe desenha. Ela não conhece
## `Nave` e não lê o pai, então trocar a aparência não toca na simulação.

## Abaixo disto o motor está em marcha lenta e a chama não acende.
const EMPUXO_MINIMO_VISIVEL: float = 0.05

## Altura da chama com o motor em marcha lenta, como fração do desenho cheio.
@export var chama_minima: float = 0.45
## Quanto o motor ilumina o que está em volta, no empuxo máximo.
@export var energia_da_luz: float = 1.7

@onready var _casco: Sprite2D = $Casco
@onready var _chama: Polygon2D = $Chama
@onready var _luz_do_motor: PointLight2D = $Chama/Luz


func _ready() -> void:
	apagar()


## A arte do casco vem da ficha do modelo, então quem veste a nave é quem leu a
## ficha. Esta classe não escolhe textura.
func vestir(arte: Texture2D) -> void:
	_casco.texture = arte


## `empuxo` é 0 a 1: a nave decide quanto o motor está empurrando, esta classe
## só desenha o que ela decidiu.
func atualizar(empuxo: float) -> void:
	var acesa: bool = empuxo > EMPUXO_MINIMO_VISIVEL
	_chama.visible = acesa
	# O motor é emissivo: ele ilumina o terreno e o próprio casco, não só
	# desenha uma chama. É o que faz o pouso ler à noite.
	_luz_do_motor.energy = energia_da_luz * empuxo if acesa else 0.0
	if acesa:
		_chama.scale.y = lerpf(chama_minima, 1.0, empuxo)


func apagar() -> void:
	atualizar(0.0)
