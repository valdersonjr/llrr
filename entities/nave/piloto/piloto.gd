class_name Piloto
extends Node2D

## O astronauta que pilota a nave. Ele é o rosto do jogo: aparece do lado de fora
## da nave onde isso faz sentido (a tela de título, os créditos), e não simula nada.
##
## A origem é o meio dos pés, para ele pisar em qualquer chão pela mesma conta. As
## tiras são quadros de 20x22 com o boneco nas 16 colunas da esquerda; as 4 da
## direita são o ar para o braço do aceno, e por isso o deslocamento muda quando
## ele vira para a esquerda.

const QUADROS: int = 4
const LADO_DO_QUADRO: Vector2i = Vector2i(20, 22)
## Quadros por segundo de cada pose: respirar é devagar, andar é o passo.
const VELOCIDADES: Dictionary = {"parado": 3.0, "acenando": 6.0, "andando": 8.0}

@export var parado: Texture2D
@export var acenando: Texture2D
@export var andando: Texture2D

var _para_a_esquerda: bool = false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	var tiras: Dictionary = {"parado": parado, "acenando": acenando, "andando": andando}
	for pose_da_tira: String in tiras:
		var tira: Texture2D = tiras[pose_da_tira]
		quadros.add_animation(pose_da_tira)
		quadros.set_animation_speed(pose_da_tira, VELOCIDADES[pose_da_tira])
		quadros.set_animation_loop(pose_da_tira, true)
		for i: int in QUADROS:
			var recorte := AtlasTexture.new()
			recorte.atlas = tira
			recorte.region = Rect2(i * LADO_DO_QUADRO.x, 0, LADO_DO_QUADRO.x, LADO_DO_QUADRO.y)
			quadros.add_frame(pose_da_tira, recorte)
	_sprite.sprite_frames = quadros
	parar()


## Respira no lugar, virado para onde estava.
func parar() -> void:
	_tocar("parado", _para_a_esquerda)


## Acena para quem está olhando. O braço erguido é o direito, então ele acena
## virado para a direita.
func acenar() -> void:
	_tocar("acenando", false)


func andar(para_a_esquerda: bool) -> void:
	_tocar("andando", para_a_esquerda)


func pose() -> String:
	return _sprite.animation


func _tocar(qual: String, para_a_esquerda: bool) -> void:
	_para_a_esquerda = para_a_esquerda
	_sprite.flip_h = para_a_esquerda
	# O boneco ocupa as 16 colunas da esquerda do quadro; espelhado, ocupa as da
	# direita. O deslocamento mantém o meio dele na origem nos dois casos.
	_sprite.offset = Vector2(-12.0 if para_a_esquerda else -8.0, -float(LADO_DO_QUADRO.y))
	if _sprite.animation != qual or not _sprite.is_playing():
		_sprite.play(qual)
