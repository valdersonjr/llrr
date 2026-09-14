class_name ArbustoSeco
extends Node2D

## Cenário: o arbusto seco que o vento empurra pela região. Parece vivo e não faz
## nada. Não colide, não vira tarefa e não entra no save.
##
## Rola sempre para o mesmo lado e, ao sair da tela, volta pelo outro, como a
## nave dá a volta nas bordas da região. A sombra é filha dele e fica no chão
## enquanto o desenho quica por cima.

@export var velocidade: float = 24.0

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_sprite.flip_h = velocidade < 0.0


func _process(delta: float) -> void:
	position.x += velocidade * delta
	var largura: float = Regiao.TAMANHO.x
	if position.x > largura + 16.0:
		position.x = -16.0
	elif position.x < -16.0:
		position.x = largura + 16.0
