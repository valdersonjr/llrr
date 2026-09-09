class_name Nave
extends CharacterBody2D
## Nave do jogador: inércia, massa, combustível e avaliação de pouso.
##
## Integração manual em vez de RigidBody2D. O pouso precisa de desfecho
## autoral — raspão, perna quebrada e impacto frontal são coisas diferentes
## (seção 4 do conceito) — e escrever isso controlando a velocidade é mais
## direto, e muito mais fácil de depurar, do que calibrar atrito e
## restituição de um corpo rígido.
##
## Convenção de eixo: o "para frente" da nave é `Vector2.UP`, então
## `rotation == 0` é a nave em pé, exatamente como o sprite é desenhado.
## Não existe offset de -90° na cena.
##
## Camadas de física: a nave é `naves` (2) e só enxerga `terreno` (1), o que
## também impede os raycasts das pernas de acertarem o próprio casco.

signal pousou(plataforma: Node)
signal decolou()
signal impacto(dano: float, velocidade: float, desalinhamento: float)
signal destruida()

enum Estado {
	VOANDO,    ## no ar, sob controle
	TOCANDO,   ## alguma perna encostou, ainda não assentou
	POUSADA,   ## parada, nivelada e estável pelo tempo exigido
	DESTRUIDA, ## integridade zerada, sem controle
}

const GRUPO_PLATAFORMA := &"plataforma_de_pouso"

## Comandos de voo, para poder soltar todos de uma vez. A seção 6 promete que
## trocar de dispositivo ou voltar de uma suspensão nunca deixa o propulsor
## travado ligado — e é isto que cumpre a promessa.
const ACOES_DE_VOO: Array[StringName] = [
	&"empuxo", &"girar_esquerda", &"girar_direita",
	&"lateral_esquerda", &"lateral_direita",
]

## Dano por px/s de velocidade acima do que o trem de pouso absorve.
const DANO_POR_VELOCIDADE := 1.6
## Bater de casco custa mais caro que bater de perna.
const MULTIPLICADOR_CASCO := 2.5
## Cada grau de desalinhamento acima do limite divide a tolerância por isto.
const PESO_DESALINHAMENTO := 2.0
## Abaixo disto o contato é apoio, não impacto: não vale reavaliar todo quadro.
const LIMIAR_IMPACTO := 3.0
const ATRITO_SOLO := 260.0
const LIMIAR_REPOUSO := 6.0
const LIMIAR_GIRO_REPOUSO := 4.0
## Frações de integridade acima das quais cada estado de casco vale.
const LIMIARES_DE_DANO: Array[float] = [0.6, 0.25]

@export var casco: Casco
## Definida pela região, não pela nave — cada corpo celeste tem a sua.
## 0 é vácuo, e no vácuo desligar o motor não freia.
@export var gravidade: float = 0.0
@export var carga: float = 0.0
## Acessibilidade: existe desde o início e não se cobra créditos por ela
## (seção 4). Gasta combustível como qualquer outro comando de manobra.
@export var estabilizacao_ativa: bool = true

## Distância da origem da nave até a sola, em pixels. Cada casco tem a sua, e
## quem posiciona a nave precisa dela para não enterrá-la nem soltá-la no ar.
@export var altura_dos_pes: float = 15.0


var combustivel: float = 0.0
## Atribuir integridade atualiza o sprite junto. Antes era responsabilidade de
## quem escrevia lembrar de chamar `_atualizar_casco()`, e quem esquecesse
## ficava com um casco intacto na tela e destruído nos números.
var integridade: float = 0.0:
	set(valor):
		integridade = valor if casco == null else clampf(valor, 0.0, casco.integridade_maxima)
		if is_node_ready():
			_apresentacao.atualizar(0.0, _empuxo_aplicado(), estado_de_dano())
## Velocidade angular em graus/s.
var giro: float = 0.0
var estado: Estado = Estado.VOANDO

var _acelerador: float = 0.0
var _comando_giro: float = 0.0
var _comando_lateral: float = 0.0
## Fração da autoridade angular que a estabilização automática usou.
var _comando_estabilizacao: float = 0.0
var _tempo_estavel: float = 0.0

@onready var _pe_esquerdo: RayCast2D = $PeEsquerdo
@onready var _pe_direito: RayCast2D = $PeDireito
@onready var _apresentacao: ApresentacaoDaNave = $Apresentacao


func _ready() -> void:
	assert(casco != null, "Nave sem casco: defina o Casco na cena do casco.")
	combustivel = casco.combustivel_maximo
	integridade = casco.integridade_maxima
	carga = clampf(carga, 0.0, casco.capacidade_carga)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("alternar_estabilizacao"):
		estabilizacao_ativa = not estabilizacao_ativa


func _notification(que: int) -> void:
	if que == NOTIFICATION_APPLICATION_FOCUS_OUT or que == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		soltar_comandos()


## Zera os comandos e solta as ações no servidor de input. Só zerar as
## variáveis não bastaria: o SO pode continuar reportando a tecla presa
## quando a janela volta, e o motor religaria sozinho.
func soltar_comandos() -> void:
	for acao in ACOES_DE_VOO:
		Input.action_release(acao)
	_acelerador = 0.0
	_comando_giro = 0.0
	_comando_lateral = 0.0
	_comando_estabilizacao = 0.0
	if is_node_ready():
		_apresentacao.apagar()


func _physics_process(delta: float) -> void:
	_pe_esquerdo.force_raycast_update()
	_pe_direito.force_raycast_update()

	if estado == Estado.DESTRUIDA:
		_acelerador = 0.0
		_comando_giro = 0.0
		_comando_lateral = 0.0
		_comando_estabilizacao = 0.0
	else:
		_ler_comandos(delta)
		_consumir_combustivel(delta)
		_aplicar_rotacao(delta)

	_aplicar_aceleracao(delta)

	var velocidade_antes := velocity
	move_and_slide()

	_pe_esquerdo.force_raycast_update()
	_pe_direito.force_raycast_update()
	_resolver_contatos(velocidade_antes)
	_atualizar_estado(delta)
	_assentar(delta)
	_apresentacao.atualizar(delta, _empuxo_aplicado(), estado_de_dano())


# --- leitura de estado, para HUD e para quem escuta -------------------------

func massa() -> float:
	return casco.massa_seca + combustivel + carga


## Aceleração que o motor principal consegue entregar agora, em px/s².
## Cai com carga e com o tanque cheio, e some sem combustível.
func aceleracao_disponivel() -> float:
	return 0.0 if combustivel <= 0.0 else casco.empuxo_principal / massa()


func aceleracao_angular() -> float:
	return casco.torque_manobra / massa()


## Empuxo que o motor está de fato entregando, de 0 a 1. Sem combustível não
## há empuxo, e é isso que a apresentação desenha.
func _empuxo_aplicado() -> float:
	return _acelerador if combustivel > 0.0 else 0.0


## Quanto resta do casco, de 0 a 1. Quem só quer mostrar uma barra ou comparar
## com um limiar não precisa saber que existe `casco.integridade_maxima`.
func integridade_fracao() -> float:
	return 0.0 if casco == null else integridade / casco.integridade_maxima


func combustivel_fracao() -> float:
	return 0.0 if casco == null else combustivel / casco.combustivel_maximo


func intacta() -> bool:
	return casco != null and is_equal_approx(integridade, casco.integridade_maxima)


## 0 íntegro, 1 degradado, 2 crítico.
func estado_de_dano() -> int:
	var fracao := integridade_fracao()
	for i in LIMIARES_DE_DANO.size():
		if fracao > LIMIARES_DE_DANO[i]:
			return i
	return LIMIARES_DE_DANO.size()


## Inclinação em relação à vertical do mundo, em graus. Negativa para bombordo.
func inclinacao() -> float:
	return rad_to_deg(wrapf(rotation, -PI, PI))


func pernas_em_contato() -> int:
	return int(_pe_esquerdo.is_colliding()) + int(_pe_direito.is_colliding())


## Restaura o casco e o estado de dano visível. Quem cobra por isso é quem
## chamou — a nave não conhece porto nem preço.
func reparar() -> void:
	integridade = casco.integridade_maxima
	if estado == Estado.DESTRUIDA:
		estado = Estado.VOANDO


func abastecer() -> void:
	combustivel = casco.combustivel_maximo


## Embarca até `toneladas` no porão e devolve quanto de fato coube.
func carregar(toneladas: float) -> float:
	var coube := clampf(toneladas, 0.0, casco.capacidade_carga - carga)
	carga += coube
	return coube


## Esvazia o porão e devolve quantas toneladas saíram.
func descarregar() -> float:
	var saiu := carga
	carga = 0.0
	return saiu


## A plataforma sob a nave, ou null se ela está apoiada em outra coisa.
## Exige as duas pernas na plataforma: meia nave para fora não é pouso.
func plataforma_sob_a_nave() -> Node:
	var esquerda := _pe_esquerdo.get_collider()
	var direita := _pe_direito.get_collider()
	if esquerda == null or direita == null:
		return null
	if not (esquerda.is_in_group(GRUPO_PLATAFORMA) and direita.is_in_group(GRUPO_PLATAFORMA)):
		return null
	return esquerda as Node


# --- comandos ---------------------------------------------------------------

func _ler_comandos(delta: float) -> void:
	_acelerador = Input.get_action_strength("empuxo")
	_comando_giro = Input.get_axis("girar_esquerda", "girar_direita")
	_comando_lateral = Input.get_axis("lateral_esquerda", "lateral_direita")

	_comando_estabilizacao = 0.0
	if estabilizacao_ativa and is_zero_approx(_comando_giro) and not is_zero_approx(giro):
		# Só cobra pelo que a estabilização de fato precisou corrigir: parar um
		# giro residual mínimo custa uma fração do que custa parar um pião.
		var autoridade := aceleracao_angular() * delta
		_comando_estabilizacao = minf(absf(giro) / maxf(autoridade, 0.0001), 1.0)

	if combustivel <= 0.0:
		_acelerador = 0.0
		_comando_giro = 0.0
		_comando_lateral = 0.0
		_comando_estabilizacao = 0.0


func _consumir_combustivel(delta: float) -> void:
	var manobra := absf(_comando_giro) + absf(_comando_lateral) + _comando_estabilizacao
	var taxa := casco.consumo_principal * _acelerador + casco.consumo_manobra * manobra
	combustivel = maxf(combustivel - taxa * delta, 0.0)


func _aplicar_rotacao(delta: float) -> void:
	var autoridade := aceleracao_angular() * delta
	if not is_zero_approx(_comando_giro):
		giro = clampf(giro + autoridade * _comando_giro, -casco.giro_maximo, casco.giro_maximo)
	elif _comando_estabilizacao > 0.0:
		giro = move_toward(giro, 0.0, autoridade)
	rotation += deg_to_rad(giro) * delta


func _aplicar_aceleracao(delta: float) -> void:
	var m := massa()
	var aceleracao := Vector2(0.0, gravidade)
	aceleracao += Vector2.UP.rotated(rotation) * (casco.empuxo_principal * _acelerador / m)
	aceleracao += Vector2.RIGHT.rotated(rotation) * (casco.empuxo_manobra * _comando_lateral / m)
	velocity += aceleracao * delta


## Atrito no sentido da superfície enquanto a nave está encostada. É isto que
## faz a nave parada no chão não sair andando sozinha, e só mexe na componente
## tangencial — decolar continua sendo só empurrar para cima.
##
## **IMPORTANT:** roda depois de `move_and_slide()`, e o apoio vem das colisões
## dela, não dos raycasts das pernas. Os raycasts enxergam o chão alguns pixels
## antes do toque; usá-los aqui matava a descida antes da colisão existir e
## nenhum pouso chegava a ser rápido o bastante para causar dano.
func _assentar(delta: float) -> void:
	if get_slide_collision_count() == 0:
		return
	var normal := _normal_do_apoio()
	var tangente := normal.orthogonal()
	var v_tangente := move_toward(velocity.dot(tangente), 0.0, ATRITO_SOLO * delta)
	var v_normal := maxf(velocity.dot(normal), 0.0)
	velocity = tangente * v_tangente + normal * v_normal


## Normal média do que a nave está tocando de fato neste quadro.
func _normal_do_apoio() -> Vector2:
	var soma := Vector2.ZERO
	for i in get_slide_collision_count():
		soma += get_slide_collision(i).get_normal()
	return soma.normalized() if soma != Vector2.ZERO else Vector2.UP


# --- contato e dano ---------------------------------------------------------

func _resolver_contatos(velocidade_antes: Vector2) -> void:
	var pior: KinematicCollision2D = null
	var pior_impacto := 0.0
	for i in get_slide_collision_count():
		var colisao := get_slide_collision(i)
		# Relativa à plataforma: pousar sobre algo que se move considera o
		# movimento dele, não a velocidade absoluta da nave.
		var relativa := velocidade_antes - colisao.get_collider_velocity()
		var contra := -relativa.dot(colisao.get_normal())
		if contra > pior_impacto:
			pior_impacto = contra
			pior = colisao
	if pior == null or pior_impacto < LIMIAR_IMPACTO:
		return

	var desalinhamento := absf(rad_to_deg(Vector2.UP.rotated(rotation).angle_to(pior.get_normal())))
	var dano := _dano_do_impacto(pior_impacto, desalinhamento)
	if dano <= 0.0:
		return

	integridade = maxf(integridade - dano, 0.0)
	impacto.emit(dano, pior_impacto, desalinhamento)
	if integridade <= 0.0 and estado != Estado.DESTRUIDA:
		estado = Estado.DESTRUIDA
		destruida.emit()


## O trem de pouso absorve tanto menos quanto pior o alinhamento no contato.
## Uma regra só, e legível: você bateu rápido demais para o ângulo em que
## estava. Encostar torto devagar não quebra nada — é só encostar torto.
func _dano_do_impacto(velocidade_contra: float, desalinhamento: float) -> float:
	var fator_angulo := desalinhamento / casco.pouso_angulo_maximo
	var fator_giro := absf(giro) / casco.pouso_giro_maximo
	var penalidade := maxf(0.0, maxf(fator_angulo, fator_giro) - 1.0)
	var tolerancia := casco.pouso_velocidade_maxima / (1.0 + PESO_DESALINHAMENTO * penalidade)
	var excesso := maxf(0.0, velocidade_contra - tolerancia)
	if excesso <= 0.0:
		return 0.0
	var dano := excesso * DANO_POR_VELOCIDADE
	if pernas_em_contato() == 0:
		dano *= MULTIPLICADOR_CASCO
	return dano


# --- estado do pouso --------------------------------------------------------

func _atualizar_estado(delta: float) -> void:
	if estado == Estado.DESTRUIDA:
		return

	var pernas := pernas_em_contato()
	match estado:
		Estado.VOANDO:
			if pernas > 0:
				estado = Estado.TOCANDO
				_tempo_estavel = 0.0
		Estado.TOCANDO:
			if pernas == 0:
				estado = Estado.VOANDO
			elif _assentada(pernas):
				_tempo_estavel += delta
				if _tempo_estavel >= casco.pouso_tempo_estavel:
					estado = Estado.POUSADA
					pousou.emit(plataforma_sob_a_nave())
			else:
				_tempo_estavel = 0.0
		Estado.POUSADA:
			if pernas == 0:
				estado = Estado.VOANDO
				decolou.emit()


## Pouso é estado, não evento: as duas pernas apoiadas, parada e nivelada.
func _assentada(pernas: int) -> bool:
	return pernas == 2 \
		and velocity.length() <= LIMIAR_REPOUSO \
		and absf(giro) <= LIMIAR_GIRO_REPOUSO \
		and absf(inclinacao()) <= casco.pouso_angulo_maximo
