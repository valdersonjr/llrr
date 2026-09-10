class_name Nave
extends CharacterBody2D
## Nave do jogador: inércia, massa, carga e avaliação de pouso.
##
## Integração manual em vez de RigidBody2D. O contato precisa de regra autoral
## — o que conta como pouso assentado é decisão de design (seção 4 do conceito)
## — e escrever isso controlando a velocidade é mais direto, e muito mais fácil
## de depurar, do que calibrar atrito e restituição de um corpo rígido.
##
## **A nave não tem dano.** Não existe integridade, casco quebrado nem estado
## destruído: a seção 5 do conceito removeu o dano do jogo. Bater não tem
## consequência, e a pergunta de o que substitui isso está na seção 18.
##
## Convenção de eixo: o "para frente" da nave é `Vector2.UP`, então
## `rotation == 0` é a nave em pé, exatamente como o sprite é desenhado.
## Não existe offset de -90° na cena.
##
## Camadas de física: a nave é `naves` (2) e só enxerga `terreno` (1), o que
## também impede os raycasts das pernas de acertarem o próprio casco.

signal pousou(plataforma: Node)
signal decolou()

enum Estado {
	VOANDO,  ## no ar, sob controle
	TOCANDO, ## alguma perna encostou, ainda não assentou
	POUSADA, ## parada, nivelada e estável pelo tempo exigido
}

const GRUPO_PLATAFORMA := &"plataforma_de_pouso"

## Comandos de voo, para poder soltar todos de uma vez. A seção 6 promete que
## trocar de dispositivo ou voltar de uma suspensão nunca deixa o propulsor
## travado ligado — e é isto que cumpre a promessa.
const ACOES_DE_VOO: Array[StringName] = [
	&"empuxo", &"girar_esquerda", &"girar_direita",
	&"lateral_esquerda", &"lateral_direita",
]

const ATRITO_SOLO := 260.0
const LIMIAR_REPOUSO := 6.0
const LIMIAR_GIRO_REPOUSO := 4.0

@export var modelo: Modelo
## Definida pela região, não pela nave — cada corpo celeste tem a sua.
## 0 é vácuo, e no vácuo desligar o motor não freia.
@export var gravidade: float = 0.0
@export var carga: float = 0.0
## Acessibilidade: existe desde o início e não se cobra créditos por ela
## (seção 4).
@export var estabilizacao_ativa: bool = true

## Distância da origem da nave até a sola, em pixels. Cada modelo tem a sua, e
## quem posiciona a nave precisa dela para não enterrá-la nem soltá-la no ar.
@export var altura_dos_pes: float = 15.0


## Velocidade angular em graus/s.
var giro: float = 0.0
var estado: Estado = Estado.VOANDO

var _acelerador: float = 0.0
var _comando_giro: float = 0.0
var _comando_lateral: float = 0.0
## A estabilização automática está corrigindo o giro neste quadro.
var _estabilizando: bool = false
var _tempo_estavel: float = 0.0

@onready var _pe_esquerdo: RayCast2D = $PeEsquerdo
@onready var _pe_direito: RayCast2D = $PeDireito
@onready var _apresentacao: ApresentacaoDaNave = $Apresentacao


func _ready() -> void:
	assert(modelo != null, "Nave sem modelo: defina o Modelo na cena do modelo.")
	carga = clampf(carga, 0.0, modelo.capacidade_carga)


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
	_estabilizando = false
	if is_node_ready():
		_apresentacao.apagar()


func _physics_process(delta: float) -> void:
	_pe_esquerdo.force_raycast_update()
	_pe_direito.force_raycast_update()

	_ler_comandos()
	_aplicar_rotacao(delta)
	_aplicar_aceleracao(delta)
	move_and_slide()

	_pe_esquerdo.force_raycast_update()
	_pe_direito.force_raycast_update()
	_atualizar_estado(delta)
	_assentar(delta)
	_apresentacao.atualizar(delta, _empuxo_aplicado())


# --- leitura de estado, para HUD e para quem escuta -------------------------

func massa() -> float:
	return modelo.massa_seca + carga


## Aceleração que o motor principal consegue entregar agora, em px/s².
## Cai com carga, e é só isso: voar não custa recurso nenhum.
func aceleracao_disponivel() -> float:
	return modelo.empuxo_principal / massa()


func aceleracao_angular() -> float:
	return modelo.torque_manobra / massa()


## Empuxo que o motor está de fato entregando, de 0 a 1. É isso que a
## apresentação desenha.
func _empuxo_aplicado() -> float:
	return _acelerador


## Inclinação em relação à vertical do mundo, em graus. Negativa para bombordo.
func inclinacao() -> float:
	return rad_to_deg(wrapf(rotation, -PI, PI))


func pernas_em_contato() -> int:
	return int(_pe_esquerdo.is_colliding()) + int(_pe_direito.is_colliding())


## Embarca até `toneladas` no porão e devolve quanto de fato coube.
func carregar(toneladas: float) -> float:
	var coube := clampf(toneladas, 0.0, modelo.capacidade_carga - carga)
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

func _ler_comandos() -> void:
	_acelerador = Input.get_action_strength("empuxo")
	_comando_giro = Input.get_axis("girar_esquerda", "girar_direita")
	_comando_lateral = Input.get_axis("lateral_esquerda", "lateral_direita")

	_estabilizando = estabilizacao_ativa \
		and is_zero_approx(_comando_giro) \
		and not is_zero_approx(giro)


func _aplicar_rotacao(delta: float) -> void:
	var autoridade := aceleracao_angular() * delta
	if not is_zero_approx(_comando_giro):
		giro = clampf(giro + autoridade * _comando_giro, -modelo.giro_maximo, modelo.giro_maximo)
	elif _estabilizando:
		giro = move_toward(giro, 0.0, autoridade)
	rotation += deg_to_rad(giro) * delta


func _aplicar_aceleracao(delta: float) -> void:
	var m := massa()
	var aceleracao := Vector2(0.0, gravidade)
	aceleracao += Vector2.UP.rotated(rotation) * (modelo.empuxo_principal * _acelerador / m)
	aceleracao += Vector2.RIGHT.rotated(rotation) * (modelo.empuxo_manobra * _comando_lateral / m)
	velocity += aceleracao * delta


## Atrito no sentido da superfície enquanto a nave está encostada. É isto que
## faz a nave parada no chão não sair andando sozinha, e só mexe na componente
## tangencial — decolar continua sendo só empurrar para cima.
##
## **IMPORTANT:** roda depois de `move_and_slide()`, e o apoio vem das colisões
## dela, não dos raycasts das pernas. Os raycasts enxergam o chão alguns pixels
## antes do toque; usá-los aqui matava a descida antes da colisão existir e
## nenhum pouso chegava a ser rápido o bastante para ser avaliado direito.
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


# --- estado do pouso --------------------------------------------------------

func _atualizar_estado(delta: float) -> void:
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
				if _tempo_estavel >= modelo.pouso_tempo_estavel:
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
		and absf(inclinacao()) <= modelo.pouso_angulo_maximo
