class_name SinalDePouso
extends Node2D

## O sinal luminoso de um lugar de pouso: pisca enquanto a nave desce, fica firme
## no contato e muda de cor quando o pouso vale.
##
## Ele não conhece a nave. Escuta o `ponto_de_coleta`, que é quem recebe o estado
## da cena do sistema, e por isso a região continua abrindo sozinha por `--scene`.
##
## A arte é do lugar: a instância aponta a tira de quadros e diz qual quadro é
## cada estado. A luz de cada quadro acompanha, porque a cor sozinha não basta,
## mas cor e luz juntas leem de longe.

@export var ponto_de_coleta: NodePath
@export_group("Arte")
## Tira horizontal com todos os quadros do sinal, lida com `hframes`.
@export var folha: Texture2D
@export var quadros: int = 4
## Quadros que se alternam enquanto a nave ainda não encostou.
@export var piscando: PackedInt32Array = PackedInt32Array([1, 2])
@export var no_contato: int = 2
@export var pousada: int = 3
@export var quadros_por_segundo: float = 3.0
@export_group("Luz")
## Cor da luz para cada quadro da tira; alfa zero apaga a luz naquele quadro.
@export var cores_da_luz: PackedColorArray = PackedColorArray([
	Color(0, 0, 0, 0), Color(0.91, 0.23, 0.23), Color(0.98, 0.76, 0.17), Color(0.12, 0.74, 0.45)
])
@export var energia: float = 1.1

var _estado: Nave.Estado = Nave.Estado.VOANDO
var _tempo: float = 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _luz: PointLight2D = $Luz


func _ready() -> void:
	_sprite.texture = folha
	_sprite.hframes = maxi(quadros, 1)
	var ponto := get_node_or_null(ponto_de_coleta) as PontoDeColeta
	if ponto != null:
		ponto.estado_mudou.connect(_ao_mudar_estado)
		_estado = ponto.estado_atual
	_mostrar(_quadro_agora())


func _process(delta: float) -> void:
	_tempo += delta
	_mostrar(_quadro_agora())


func _ao_mudar_estado(estado: Nave.Estado) -> void:
	_estado = estado


func _quadro_agora() -> int:
	match _estado:
		Nave.Estado.TOCANDO:
			return no_contato
		Nave.Estado.POUSADA:
			return pousada
	if piscando.is_empty():
		return 0
	return piscando[int(_tempo * quadros_por_segundo) % piscando.size()]


func _mostrar(quadro: int) -> void:
	_sprite.frame = clampi(quadro, 0, _sprite.hframes - 1)
	var cor: Color = cores_da_luz[quadro] if quadro < cores_da_luz.size() else Color(0, 0, 0, 0)
	_luz.color = cor
	_luz.energy = 0.0 if cor.a == 0.0 else energia
