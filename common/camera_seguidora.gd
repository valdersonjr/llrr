class_name CameraSeguidora
extends Camera2D
## Câmera que segue um alvo olhando um pouco à frente do movimento dele.
##
## A antecipação é medida em segundos de velocidade do alvo e tem teto em
## pixels: acompanhar o movimento ajuda a ler para onde se está indo, mas
## antecipação sem limite joga o chão para fora da tela justo na descida
## rápida, que é quando ele mais importa.
##
## Deriva a velocidade da própria posição do alvo, então serve para qualquer
## Node2D — não sabe o que é uma nave, e não deve saber.

## Atribua por código (`camera.alvo = nave`). Referência de nó exportada não
## sobrevive a `.tscn` escrito à mão — o NodePath não é resolvido de volta
## para o objeto, e a câmera fica parada sem avisar.
@export var alvo: Node2D:
	set(valor):
		alvo = valor
		_velocidade = Vector2.ZERO
		if valor == null:
			return
		_posicao_anterior = valor.global_position
		if is_inside_tree():
			global_position = valor.global_position
			reset_smoothing()
## Quantos segundos de movimento do alvo a câmera olha à frente.
@export var antecipacao: float = 0.4
## Teto do deslocamento de antecipação, em pixels.
@export var antecipacao_maxima: float = 40.0
## Suavização da estimativa de velocidade. Sem ela a antecipação treme.
@export_range(0.01, 1.0) var suavizacao_da_velocidade: float = 0.12
## Teto do tremor, em pixels.
@export var tremor_maximo: float = 6.0
@export var decaimento_do_tremor: float = 9.0

var _posicao_anterior := Vector2.ZERO
var _velocidade := Vector2.ZERO
var _tremor := 0.0


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if alvo == null or is_zero_approx(delta):
		return
	var posicao := alvo.global_position
	_velocidade = _velocidade.lerp((posicao - _posicao_anterior) / delta, suavizacao_da_velocidade)
	_posicao_anterior = posicao
	global_position = posicao + (_velocidade * antecipacao).limit_length(antecipacao_maxima)
	_aplicar_tremor(delta)


## Sacode a câmera. Usa `offset`, não a posição: assim quem lê a posição da
## câmera continua lendo para onde ela está olhando, sem o ruído do tremor.
func sacudir(intensidade: float) -> void:
	_tremor = minf(maxf(_tremor, intensidade), tremor_maximo)


func _aplicar_tremor(delta: float) -> void:
	if _tremor <= 0.0:
		offset = Vector2.ZERO
		return
	_tremor = move_toward(_tremor, 0.0, decaimento_do_tremor * delta)
	# Arredondado para o grid: tremor em subpixel faz a arte inteira vibrar.
	offset = Vector2(randf_range(-_tremor, _tremor), randf_range(-_tremor, _tremor)).round()
