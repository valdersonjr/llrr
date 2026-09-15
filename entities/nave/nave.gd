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
## no meio do casco, ela vira com 40 graus de inclinação; a 40% do caminho entre o
## meio e a base do desenho, aguenta 60. É uma fração da altura da arte, e não um
## ponto fixo, para trocar o casco levar o centro junto.
const CENTRO_DE_MASSA_ATE_A_BASE: float = 0.4

## Até onde o altímetro enxerga para baixo, em pixels. Acima disso a nave está
## subindo para a tela de regiões, e altitude deixa de ser informação de pouso.
const ALCANCE_DO_ALTIMETRO: float = 2000.0

## No espaço cada pixel da arte ocupa meio pixel da tela base: um pixel inteiro de
## janela na escala 2x, dois na 4x. Nunca uma fração, que é o que borra.
const MEIO_PIXEL_DA_TELA: float = 0.5

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
## As duas componentes do toque, guardadas pelo mesmo motivo. É com elas que a
## especificação do lugar diz se o toque valeu.
var vertical_do_toque: float = 0.0
var horizontal_do_toque: float = 0.0

## O que o lugar de pouso atual exige. Quem sabe onde a nave está é a cena do
## sistema, e é ela que entrega e retira; sem especificação valem só os limites
## do trem de pouso do modelo.
var especificacao: EspecificacaoDePouso = null

var _velocidade_anterior: float = 0.0
var _vertical_anterior: float = 0.0
var _horizontal_anterior: float = 0.0

var _tempo_estavel: float = 0.0
var _empuxo: float = 0.0
## A ponta mais baixa da silhueta, em pixels abaixo da origem: é de onde o
## altímetro mede, para marcar zero com as pernas no chão.
var _pe: float = 0.0
## A última leitura do altímetro, em metros; negativa quando não há chão embaixo.
var _altitude: float = -1.0

@onready var _apresentacao: ApresentacaoDaNave = $Apresentacao


func _ready() -> void:
	assert(modelo != null, "nave.tscn precisa de um ModeloDeNave em `modelo`.")
	assert(modelo.arte != null, "O ModeloDeNave precisa de uma textura em `arte`.")
	contact_monitor = true
	max_contacts_reported = 8
	mass = modelo.massa
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2(0.0, modelo.arte.get_height() * 0.5 * CENTRO_DE_MASSA_ATE_A_BASE)
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
		for ponto: Vector2 in contorno:
			_pe = maxf(_pe, ponto.y)


func _physics_process(delta: float) -> void:
	_aplicar_comandos(delta)
	_apresentacao.atualizar(_empuxo)
	_avaliar_pouso(delta)
	_medir_altitude()
	_velocidade_anterior = velocidade()
	_vertical_anterior = velocidade_vertical()
	_horizontal_anterior = velocidade_horizontal()


## Velocidade em metros por segundo, não em pixels. Quem mostra telemetria e quem
## compara com o limite do trem de pouso falam a mesma língua do resto do jogo.
func velocidade() -> float:
	return Escala.para_metros(linear_velocity.length())


## Velocidade vertical em metros por segundo, positiva descendo: é a leitura que
## quem pilota um módulo de pouso quer, e o sinal diz o sentido.
func velocidade_vertical() -> float:
	return Escala.para_metros(linear_velocity.y)


## Velocidade horizontal em metros por segundo, positiva para a direita.
func velocidade_horizontal() -> float:
	return Escala.para_metros(linear_velocity.x)


## Distância do pé da nave até o chão logo abaixo, em metros. Negativa quando não
## há chão ao alcance, que é sempre o caso no espaço.
##
## A consulta ao espaço físico só vale dentro do passo de física, por isso a
## medida é feita lá e aqui só se lê a última.
func altitude() -> float:
	return _altitude


## Quanto a nave está fora do prumo, em graus, sem sinal.
func inclinacao_em_graus() -> float:
	return absf(rad_to_deg(wrapf(rotation, -PI, PI)))


## Giro em graus por segundo.
func giro_por_segundo() -> float:
	return absf(rad_to_deg(angular_velocity))


## Os limites que valem agora: o mais apertado entre o trem de pouso do modelo e a
## especificação do lugar. Um lugar pode exigir mais do que o trem aguenta, nunca
## menos.
func limite_vertical() -> float:
	return minf(modelo.velocidade_maxima_de_toque,
		especificacao.vertical_maxima if especificacao != null else INF)


func limite_horizontal() -> float:
	return minf(modelo.velocidade_maxima_de_toque,
		especificacao.horizontal_maxima if especificacao != null else INF)


func limite_de_inclinacao() -> float:
	return minf(modelo.inclinacao_em_graus,
		especificacao.inclinacao_maxima if especificacao != null else INF)


func limite_de_giro() -> float:
	return minf(modelo.giro_por_segundo,
		especificacao.giro_maximo if especificacao != null else INF)


func vertical_no_limite() -> bool:
	return absf(velocidade_vertical()) <= limite_vertical()


func horizontal_no_limite() -> bool:
	return absf(velocidade_horizontal()) <= limite_horizontal()


## A velocidade total ainda é o que o trem de pouso aguenta, e as componentes são
## o que o lugar exige: as três precisam caber.
func velocidade_no_limite() -> bool:
	return (velocidade() <= modelo.velocidade_maxima_de_toque
		and vertical_no_limite() and horizontal_no_limite())


func inclinacao_no_limite() -> bool:
	return inclinacao_em_graus() <= limite_de_inclinacao()


func giro_no_limite() -> bool:
	return giro_por_segundo() <= limite_de_giro()


func dentro_dos_limites() -> bool:
	return velocidade_no_limite() and inclinacao_no_limite() and giro_no_limite()


func empuxo() -> float:
	return _empuxo


## O toque foi dentro do que o trem de pouso aguenta e do que o lugar exige.
func toque_no_limite() -> bool:
	return (velocidade_do_toque <= modelo.velocidade_maxima_de_toque
		and absf(vertical_do_toque) <= limite_vertical()
		and absf(horizontal_do_toque) <= limite_horizontal())


## O raio desce reto no mundo, e não na direção do casco: altitude é distância
## até o chão embaixo, esteja a nave torta ou não.
func _medir_altitude() -> void:
	var de: Vector2 = global_position
	var consulta := PhysicsRayQueryParameters2D.create(
		de, de + Vector2(0.0, ALCANCE_DO_ALTIMETRO), collision_mask, [get_rid()]
	)
	var achado: Dictionary = get_world_2d().direct_space_state.intersect_ray(consulta)
	if achado.is_empty():
		_altitude = -1.0
	else:
		_altitude = Escala.para_metros(maxf(0.0, (achado.position as Vector2).y - de.y - _pe))


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
		vertical_do_toque = _vertical_anterior
		horizontal_do_toque = _horizontal_anterior
	estado = novo
	pouso_mudou.emit(estado)


## No espaço o casco perde a borda contra o vazio e encolhe com a câmera afastada:
## a apresentação acende um anel em volta dele e troca de escala para o desenho
## cair em pixel inteiro de janela. `zoom` é o da câmera no espaço. Só o desenho
## muda; a colisão continua a mesma, e no espaço não há com o que colidir. Quem
## sabe em que vista a nave está é a cena do sistema.
func realcar_no_espaco(sim: bool, zoom: float = 1.0) -> void:
	_apresentacao.modo_de_espaco(sim, MEIO_PIXEL_DA_TELA / zoom)


## Quantos pixels de mundo cada pixel da arte ocupa agora.
func escala_do_desenho() -> float:
	return _apresentacao.scale.x


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
