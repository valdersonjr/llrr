@tool
class_name Asteroide
extends RigidBody2D

## Rocha solta na descida. Não persegue ninguém e não explode: ela atravessa a
## região no seu próprio ritmo, e quem estiver no caminho leva um empurrão.
##
## É a dificuldade que a seção 10 do conceito chama de objeto solto na descida, e
## ela funciona porque a nave tem inércia: um encontrão perto do chão não mata,
## tira a nave do prumo na hora em que ela menos pode corrigir.
##
## **É corpo cinemático congelado, não corpo rígido solto.** Assim ele empurra a
## nave sem ser empurrado, ignora a gravidade do lugar e mantém a rota que o
## projetista desenhou. Asteroide que reage a batida vira bola de sinuca, e a
## região deixa de ser desenhável.
##
## A colisão sai do alfa da própria arte, pela mesma conta que a nave usa para o
## casco, em `Silhueta`. Forma e desenho não têm como discordar.

## Quanto ele passa da borda antes de reaparecer do outro lado. Some fora da tela
## e volta fora da tela: a volta não deve ser vista.
const MARGEM: float = 48.0

@export var arte: Texture2D:
	set(valor):
		arte = valor
		if is_node_ready():
			montar()

## Em pixels por segundo. Cada asteroide tem a sua, e é isso que faz um campo
## deles parecer campo em vez de fileira.
@export var velocidade: Vector2 = Vector2(40.0, 0.0)
## Giro do desenho, em graus por segundo. É enfeite: a colisão gira junto, mas a
## forma é quase redonda e o jogador não lê diferença.
@export var giro: float = 14.0
## Quanto a colisão pode se afastar do contorno, em pixels.
@export var tolerancia: float = 1.5

@onready var _sprite: Sprite2D = $Arte


func _ready() -> void:
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	montar()


func _physics_process(delta: float) -> void:
	position += velocidade * delta
	rotation += deg_to_rad(giro) * delta
	_dar_a_volta()


## A região dá a volta nos lados, e o que vive nela também. Sem isso o campo de
## asteroides se esvazia em vinte segundos.
func _dar_a_volta() -> void:
	var lado: Vector2 = Regiao.TAMANHO
	if position.x < -MARGEM:
		position.x += lado.x + MARGEM * 2.0
	elif position.x > lado.x + MARGEM:
		position.x -= lado.x + MARGEM * 2.0
	if position.y < -MARGEM:
		position.y += lado.y + MARGEM * 2.0
	elif position.y > lado.y + MARGEM:
		position.y -= lado.y + MARGEM * 2.0


func montar() -> void:
	for velho: Node in get_children():
		if velho is CollisionPolygon2D:
			velho.queue_free()
	_sprite.texture = arte
	if arte == null:
		return

	for contorno: PackedVector2Array in Silhueta.contornos_do_alfa(arte, tolerancia, true):
		var forma := CollisionPolygon2D.new()
		forma.polygon = contorno
		add_child(forma)
		if Engine.is_editor_hint():
			forma.owner = get_tree().edited_scene_root
