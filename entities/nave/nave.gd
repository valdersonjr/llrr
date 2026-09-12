class_name Nave
extends RigidBody2D

## A nave do jogador, que é o personagem principal do jogo. Um corpo físico só:
## os três modelos são fichas diferentes em `modelo`, nunca cenas diferentes.
##
## Este script simula e avalia, e não desenha nada. Quem desenha é
## `ApresentacaoDaNave`, no nó filho `Apresentacao`, e o fluxo é de mão única:
## a nave manda o empuxo, a apresentação decide como mostrar.
##
## Corpo rígido é escolha de protótipo, não dogma. Inércia, massa que muda com a
## carga e torque saem de graça daqui, e o conceito diz que a sensação de voo só
## se decide voando. Se o voo pedir outra coisa, o lugar de trocar é este.

## Só o que é discreto vira sinal. Velocidade, inclinação e giro são contínuos e
## o HUD lê direto pelos métodos públicos abaixo, sem fio ligado por quadro.
signal pouso_mudou(novo: Estado)

## VOANDO: sem contato com um ponto de coleta.
## TOCANDO: encostou, mas alguma medida está fora do limite ou ainda não assentou.
## POUSADA: dentro de todos os limites e parada tempo suficiente.
enum Estado { VOANDO, TOCANDO, POUSADA }

## Segundos de contato calmo até o pouso valer. A seção 4 do conceito é explícita:
## pouso é um estado, não um evento único de colisão.
const TEMPO_ATE_ASSENTAR: float = 0.7

## O centro de massa fica embaixo, perto das pernas, como em qualquer módulo de
## pouso de verdade. É o que decide se a nave assenta torta ou tomba: com o centro
## no meio do casco, ela vira com 40 graus de inclinação; com ele aqui, aguenta 60.
const CENTRO_DE_MASSA: Vector2 = Vector2(0.0, 6.0)

@export var modelo: ModeloDeNave

var estado: Estado = Estado.VOANDO
var estabilizacao_ligada: bool = true

## Com que velocidade a nave encostou, em metros por segundo.
##
## O contato zera a velocidade dentro do mesmo passo de física, então ler depois
## do toque sempre dá zero. O número só existe se for guardado no quadro anterior.
## É este o valor que uma consequência de pouso ruim vai usar quando a seção 18
## do conceito for respondida.
var velocidade_do_toque: float = 0.0

var _velocidade_anterior: float = 0.0

var _tempo_estavel: float = 0.0
var _empuxo: float = 0.0

@onready var _apresentacao: ApresentacaoDaNave = $Apresentacao


func _ready() -> void:
	assert(modelo != null, "nave.tscn precisa de um ModeloDeNave em `modelo`.")
	assert(modelo.arte != null, "O ModeloDeNave precisa de uma textura em `arte`.")
	contact_monitor = true
	max_contacts_reported = 8
	mass = modelo.massa
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = CENTRO_DE_MASSA
	# Congelada, a nave ainda precisa ser levada de um ponto a outro: é assim que
	# a chegada numa região acontece.
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	_montar_colisao()
	_apresentacao.vestir(modelo.arte)


## A colisão sai do alfa da mesma arte que a apresentação veste, então silhueta e
## desenho não têm como discordar, e trocar o casco de um modelo é trocar um
## arquivo. A conta mora em `Silhueta`, porque a pedra do terreno faz a mesma.
func _montar_colisao() -> void:
	for contorno: PackedVector2Array in Silhueta.contornos_do_alfa(
		modelo.arte, modelo.tolerancia_da_colisao, true
	):
		var forma := CollisionPolygon2D.new()
		forma.polygon = contorno
		add_child(forma)


func _physics_process(delta: float) -> void:
	_aplicar_comandos(delta)
	_apresentacao.atualizar(_empuxo)
	_avaliar_pouso(delta)
	_velocidade_anterior = velocidade()


## Velocidade em metros por segundo, não em pixels. Quem mostra telemetria e quem
## compara com o limite do trem de pouso falam a mesma língua do resto do jogo.
func velocidade() -> float:
	return Escala.para_metros(linear_velocity.length())


## Quanto a nave está fora do prumo, em graus, sem sinal.
func inclinacao_em_graus() -> float:
	return absf(rad_to_deg(wrapf(rotation, -PI, PI)))


## Giro em graus por segundo.
func giro_por_segundo() -> float:
	return absf(rad_to_deg(angular_velocity))


func velocidade_no_limite() -> bool:
	return velocidade() <= modelo.velocidade_maxima_de_toque


func inclinacao_no_limite() -> bool:
	return inclinacao_em_graus() <= modelo.inclinacao_em_graus


func giro_no_limite() -> bool:
	return giro_por_segundo() <= modelo.giro_por_segundo


func dentro_dos_limites() -> bool:
	return velocidade_no_limite() and inclinacao_no_limite() and giro_no_limite()


func empuxo() -> float:
	return _empuxo


## O toque foi dentro do que o trem de pouso aguenta.
func toque_no_limite() -> bool:
	return velocidade_do_toque <= modelo.velocidade_maxima_de_toque


func _aplicar_comandos(delta: float) -> void:
	if Input.is_action_just_pressed("alternar_estabilizacao"):
		estabilizacao_ligada = not estabilizacao_ligada

	_empuxo = Input.get_action_strength("empuxo")
	if _empuxo > 0.0:
		apply_central_force(-global_transform.y * _forca(modelo.empuxo_em_g) * _empuxo)

	var lateral: float = Input.get_axis("lateral_esquerda", "lateral_direita")
	if not is_zero_approx(lateral):
		apply_central_force(global_transform.x * _forca(modelo.empuxo_lateral_em_g) * lateral)

	var giro: float = Input.get_axis("girar_esquerda", "girar_direita")
	if not is_zero_approx(giro):
		# Aceleração angular direta em vez de torque: a autoridade de manobra vira
		# número desenhado em vez de consequência da inércia calculada da forma.
		angular_velocity += deg_to_rad(modelo.aceleracao_angular) * giro * delta
		var teto: float = deg_to_rad(modelo.giro_maximo)
		angular_velocity = clampf(angular_velocity, -teto, teto)
	elif estabilizacao_ligada:
		angular_velocity = move_toward(
			angular_velocity, 0.0, deg_to_rad(modelo.autoridade_de_estabilizacao) * delta
		)


## Empuxo declarado em g vira força: a aceleração pedida, convertida para pixel,
## multiplicada pela massa atual. Como a massa cresce com a carga, aceitar um
## contrato grande derruba o empuxo em g sem ninguém precisar recalcular nada.
func _forca(em_g: float) -> float:
	return mass * Escala.para_pixels(em_g * Escala.G_TERRA)


func _avaliar_pouso(delta: float) -> void:
	if not _encostada_num_ponto_de_coleta():
		_tempo_estavel = 0.0
		_definir_estado(Estado.VOANDO)
		return

	if dentro_dos_limites():
		_tempo_estavel += delta
		var assentou: bool = _tempo_estavel >= TEMPO_ATE_ASSENTAR
		_definir_estado(Estado.POUSADA if assentou else Estado.TOCANDO)
	else:
		_tempo_estavel = 0.0
		_definir_estado(Estado.TOCANDO)


## Encostar no terreno não é pousar. Pousar é chegar no lugar demarcado, que é o
## que o grupo `pontos_de_coleta` marca.
func _encostada_num_ponto_de_coleta() -> bool:
	for corpo: Node in get_colliding_bodies():
		if corpo.is_in_group("pontos_de_coleta"):
			return true
	return false


func _definir_estado(novo: Estado) -> void:
	if novo == estado:
		return
	if estado == Estado.VOANDO:
		velocidade_do_toque = _velocidade_anterior
	estado = novo
	pouso_mudou.emit(estado)


## Guardada: sem comandos, sem simulação e com o motor apagado. É o estado da
## nave enquanto o jogador lê a tela de regiões, e enquanto o piloto automático a
## leva até o ponto de aparecimento. Quem decide isso é a cena do sistema.
func congelar() -> void:
	freeze = true
	set_physics_process(false)
	_empuxo = 0.0
	_apresentacao.atualizar(0.0)
	estabilizacao_ligada = true


func soltar() -> void:
	freeze = false
	set_physics_process(true)


func congelada() -> bool:
	return freeze


## Move a nave sem tocar em velocidade, ângulo nem giro. É com isto que uma
## região dá a volta: sair por um lado e entrar pelo outro não é um recomeço, é o
## mesmo voo continuando do outro lado da tela.
func deslocar(por: Vector2) -> void:
	var corpo: RID = get_rid()
	var onde: Transform2D = PhysicsServer2D.body_get_state(
		corpo, PhysicsServer2D.BODY_STATE_TRANSFORM
	)
	PhysicsServer2D.body_set_state(
		corpo,
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		Transform2D(onde.get_rotation(), onde.origin + por)
	)


## Recolocar um corpo rígido não se faz mexendo no transform: o servidor de física
## sobrescreve. Usado pela ferramenta de dev que reinicia o pouso, e pelas
## conferências, que precisam plantar a nave num ponto com uma velocidade dada.
func reposicionar(em: Vector2, com_velocidade: Vector2 = Vector2.ZERO) -> void:
	var corpo: RID = get_rid()
	PhysicsServer2D.body_set_state(
		corpo, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, em)
	)
	PhysicsServer2D.body_set_state(
		corpo, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, com_velocidade
	)
	PhysicsServer2D.body_set_state(corpo, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	_tempo_estavel = 0.0
