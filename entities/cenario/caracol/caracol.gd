class_name Caracol
extends Node2D

## Cenário: parece vivo e não faz nada. A regra que segura esta categoria está no
## CLAUDE.md da raiz. Cenário nunca vira tarefa, nunca disputa leitura com o lugar
## de pouso e nunca entra no save, porque vive na cena da região e morre com ela.

const QUADROS: int = 8
const QUADROS_POR_SEGUNDO: float = 7.0

@export var velocidade: float = 5.0
@export var alcance: float = 36.0

var _origem: float = 0.0
var _tempo: float = 0.0
var _sentido: float = 1.0

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_origem = position.x
	_tempo = randf() * 10.0


func _process(delta: float) -> void:
	_tempo += delta
	_sprite.frame = int(_tempo * QUADROS_POR_SEGUNDO) % QUADROS
	position.x += velocidade * _sentido * delta
	if absf(position.x - _origem) > alcance:
		_sentido = -_sentido
		_sprite.flip_h = _sentido < 0.0
