extends Node2D

## A cena que roda o jogo, e o único lugar que sabe em qual vista estamos.
##
## A nave é criada aqui uma vez e nunca é recriada. A região de um lugar entra e
## sai como filha de `LugarAtual`, e é o terreno que aparece em volta da nave.
##
## IMPORTANT: nunca use change_scene_to_file() para entrar ou sair de um lugar.
## Ver a seção "Os lugares" no CLAUDE.md da raiz.
##
## ## As três vistas
##
## | Vista | A nave | O que se vê |
## |---|---|---|
## | `ESPACO` | voando, solta | o sistema, com os corpos e as estrelas |
## | `ORBITA` | parada e guardada | a tela de regiões do corpo, sem nave |
## | `SUPERFICIE` | voando, solta | a região escolhida, com a câmera perto |
##
## `CHEGANDO` é o intervalo entre as duas últimas: a região já está na cena e a
## nave vai por piloto automático até o ponto que a ficha definiu. O jogador não
## comanda nada nesse trecho, e é de propósito: onde a nave aparece é decisão de
## quem desenhou o lugar, não consequência da trajetória de chegada.
##
## **O espaço é finito e dá a volta.** Sair por cima é entrar por baixo, e sair
## pela direita é entrar pela esquerda, pelo mesmo mecanismo que uma região usa
## nos lados. O conceito pede um sistema finito, e fechar o espaço em vez de
## cercá-lo evita tanto a parede invisível quanto a deriva infinita. O tamanho é
## calibração: ele cresce quando entrarem mais corpos.
##
## **Entrar não é atravessar.** Chegar perto de um corpo acende o convite; a
## tecla para a nave e abre a tela de regiões. Sair é o contrário: ganhar
## altitude devolve a tela de regiões. Para os lados a região dá a volta, e para
## baixo está o chão.

enum Vista { ESPACO, ORBITA, CHEGANDO, SUPERFICIE }

## Quanto tempo o terreno leva para entrar e sair.
const SEGUNDOS_DE_DISSOLVENCIA: float = 0.7
## Quanto dura a chegada por piloto automático. Curta: é uma vinheta, não uma
## viagem, e o jogador está esperando para pilotar.
const SEGUNDOS_DE_CHEGADA: float = 1.1

## Onde a nave nasce, no espaço. O jogo abre à deriva e com um corpo à vista: o
## primeiro lugar é escolha do jogador, não começo imposto.
@export var nascer_em: Vector2 = Vector2(320.0, -520.0)

## O sistema inteiro, em pixels de mundo. Cruzar uma borda devolve a nave pela
## borda oposta. Hoje cabem umas três telas de espaço em cada direção, que é o
## bastante para a viagem existir sem virar espera; cresce com o conteúdo.
@export var espaco: Rect2 = Rect2(-1728.0, -972.0, 4096.0, 2304.0)

var vista: Vista = Vista.ESPACO

var _lugar: CorpoNoEspaco = null
var _regiao: Regiao = null
var _ficha: FichaDeRegiao = null
var _corpos: Array[CorpoNoEspaco] = []
var _convidando: CorpoNoEspaco = null
## Onde a nave ficou parada ao entrar em órbita. Fechar a tela de regiões devolve
## ela exatamente ali: ninguém perde a posição por ter parado para ler.
var _parada_no_espaco: Vector2 = Vector2.ZERO
## A chegada em curso, se houver. Ela precisa ser cancelável: quem sai do lugar
## no meio dela não pode receber o fim dela depois, num estado que já mudou.
var _chegada: Tween = null
var _nasceu: bool = false

@onready var _nave: Nave = $Nave
@onready var _lugar_atual: Node2D = $LugarAtual
@onready var _camera: CameraDoSistema = $Camera
@onready var _hud: Hud = $Interface/Hud
@onready var _orbita: Orbita = $Interface/Orbita
@onready var _mapa: Mapa = $Interface/Mapa
@onready var _pausa: TelaDePausa = $Interface/Pausa
@onready var _estrelas: Node2D = $Estrelas


func _ready() -> void:
	_hud.acompanhar(_nave)
	_camera.seguir(_nave)
	_nave.pouso_mudou.connect(_ao_mudar_o_pouso)
	_orbita.regiao_escolhida.connect(_ao_escolher_regiao)
	_orbita.fechada.connect(_ao_fechar_orbita)
	for corpo: Node in get_tree().get_nodes_in_group("planetas"):
		_corpos.append(corpo as CorpoNoEspaco)
	_mapa.acompanhar(_nave, _corpos, espaco)
	_conferir_a_costura()

	assert(not _corpos.is_empty(), "sistema.tscn precisa de pelo menos um CorpoNoEspaco em Corpos.")
	# Um quadro depois: recolocar um corpo rígido dentro do `_ready` é falar com o
	# servidor de física antes de o corpo existir nele, e a nave nasceria onde a
	# cena a deixou em vez de no ponto de partida.
	nascer_no_espaco.call_deferred()


## O campo de estrelas fecha na borda do sistema só se o deslocamento dele numa
## volta inteira for um número redondo de mosaicos. Mexer no tamanho do espaço
## sem olhar para isto reabre a costura, e a borda volta a ser visível.
func _conferir_a_costura() -> void:
	for camada: CampoDeEstrelas in _estrelas.get_children():
		var passo: Vector2 = espaco.size * camada.fator
		var mosaico: Vector2 = camada.mosaico()
		var sobra := Vector2(
			fposmod(passo.x, mosaico.x), fposmod(passo.y, mosaico.y)
		)
		if not (is_zero_approx(sobra.x) and is_zero_approx(sobra.y)):
			push_warning(
				"Estrelas %s: o espaço anda %s por volta, que não é múltiplo do mosaico %s. A borda vai aparecer." % [camada.name, passo, mosaico]
			)


## Que lugar está carregado agora, ou `null` quando a nave está no espaço.
func lugar_atual() -> CorpoNoEspaco:
	return _lugar


## Que região está carregada agora, ou `null` fora de uma.
func regiao_atual() -> FichaDeRegiao:
	return _ficha


func no_espaco() -> bool:
	return vista == Vista.ESPACO


## A nave está numa região e sob comando do jogador. É diferente de estar numa
## região: durante a chegada o terreno já existe e quem pilota é o automático.
func em_superficie() -> bool:
	return vista == Vista.SUPERFICIE


## Os corpos do sistema, na ordem em que a cena os declara.
func corpos() -> Array[CorpoNoEspaco]:
	return _corpos


## De que corpo a nave está perto o bastante para entrar, ou `null`.
func corpo_ao_alcance() -> CorpoNoEspaco:
	return _convidando


func _physics_process(_delta: float) -> void:
	match vista:
		Vista.ESPACO:
			_fechar_o_espaco()
			_oferecer_entrada()
		Vista.SUPERFICIE:
			if _lugar == null:
				return
			_dar_a_volta()
			if _lugar.subiu_demais(_nave.global_position):
				voltar_para_a_orbita()


func _unhandled_input(evento: InputEvent) -> void:
	# A pausa só abre sem outra tela na frente: com o mapa ou a tela de regiões
	# abertos, o Esc é delas.
	if evento.is_action_pressed("pausa") and not _pausa.aberta() and not _orbita.aberta() and not _mapa.aberto():
		get_viewport().set_input_as_handled()
		_pausa.abrir()
		return
	# O mapa é sobre o sistema, então ele só abre no espaço: dentro de uma região
	# não há para onde navegar. Ele não para o jogo: é para se localizar **no meio
	# do voo**, e a nave continua andando com o marcador acompanhando.
	if evento.is_action_pressed("mapa") and vista == Vista.ESPACO:
		_mapa.abrir()
		return
	if evento.is_action_pressed("entrar") and vista == Vista.ESPACO and _convidando != null:
		entrar_em_orbita(_convidando)
		return
	# `reiniciar` é ferramenta de dev, declarada no CLAUDE.md da raiz: devolve a
	# nave ao ponto de partida sem fechar o jogo, o que também é a saída de quem
	# se perdeu. Não é mecânica e não aparece ao jogador.
	if evento.is_action_pressed("reiniciar"):
		nascer_no_espaco()


## Abre a tela de regiões de um corpo. A nave para onde está e some da tela: a
## vista de órbita é sobre o lugar, não sobre ela.
func entrar_em_orbita(corpo: CorpoNoEspaco) -> void:
	_cancelar_a_chegada()
	if vista == Vista.ESPACO:
		_parada_no_espaco = _nave.global_position
	_apagar_convite()
	_mapa.fechar()
	_esvaziar_lugar()
	_lugar = corpo
	_ficha = null
	_guardar_nave()
	# O painel é telemetria de voo. Na tela de regiões não há voo, e durante a
	# chegada quem voa é o automático: mostrar a velocidade dele seria mentir
	# sobre o que o jogador está fazendo.
	_hud.hide()
	vista = Vista.ORBITA
	_orbita.abrir(corpo)


## Ganhar altitude numa região devolve a tela de regiões do mesmo corpo.
func voltar_para_a_orbita() -> void:
	if _lugar != null:
		entrar_em_orbita(_lugar)


## Leva a nave a uma região: o terreno entra, a nave aparece no ponto de onde a
## ficha diz que ela vem e o piloto automático a põe no ponto de aparecimento.
func chegar_em(corpo: CorpoNoEspaco, ficha: FichaDeRegiao) -> void:
	_cancelar_a_chegada()
	_apagar_convite()
	_orbita.retirar()
	_montar_regiao(corpo, ficha)
	_regiao.revelar(SEGUNDOS_DE_DISSOLVENCIA)
	_estrelas.modulate.a = 0.0
	corpo.aparecer(false)
	_hud.hide()

	var canto: Vector2 = corpo.canto_da_regiao()
	var entrada: Vector2 = canto + ficha.de_onde_a_nave_vem
	var destino: Vector2 = canto + ficha.onde_a_nave_aparece
	_guardar_nave()
	_nave.show()
	# A chegada já é superfície: a câmera está perto e a nave volta ao tamanho de arte.
	_nave.realcar_no_espaco(false)
	_nave.rotation = 0.0
	_nave.global_position = entrada
	vista = Vista.CHEGANDO
	# A câmera fica no quadro do lugar e deixa a nave entrar por cima. Subir com
	# ela encheria a tela de céu vazio justo quando o jogador quer ver onde vai
	# pousar.
	_camera.enquadrar(corpo.limites_da_camera(), 0.0)
	_camera.assentar()
	_chegada = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_chegada.tween_property(_nave, "global_position", destino, SEGUNDOS_DE_CHEGADA)
	_chegada.finished.connect(_ao_terminar_a_chegada.bind(corpo, destino))


## O começo de tudo: a nave à deriva no ponto de partida, com o espaço aberto.
func nascer_no_espaco() -> void:
	_orbita.retirar()
	_parada_no_espaco = nascer_em
	voltar_para_o_espaco()
	_nasceu = true


## A nave já foi posta no ponto de partida. Serve a quem abre a cena por fora,
## como as conferências: o nascimento acontece um quadro depois do `_ready`, e
## "estar no espaço" já é verdade antes disso.
func nasceu() -> bool:
	return _nasceu


## Fecha a órbita e devolve a nave ao espaço, parada onde ela ficou.
func voltar_para_o_espaco() -> void:
	_cancelar_a_chegada()
	_esvaziar_lugar()
	var deixado: CorpoNoEspaco = _lugar
	_lugar = null
	_ficha = null
	if deixado != null:
		deixado.aparecer(true)
	_estrelas.modulate.a = 1.0
	_hud.show()
	_nave.especificacao = null
	_nave.realcar_no_espaco(true, _camera.zoom_no_espaco)
	_hud.avaliar_pouso(false)
	vista = Vista.ESPACO
	_nave.show()
	_nave.soltar()
	_nave.reposicionar(_parada_no_espaco)
	_camera.enquadrar(Rect2(_parada_no_espaco, Vector2.ZERO), 1.0)
	_camera.assentar()


## No espaço, o corpo mais próximo acende o destaque e o convite. Medido por
## quadro, e não por gatilho, porque a nave pode parar dentro do alcance e voltar
## a andar sem nunca cruzar borda nenhuma.
func _oferecer_entrada() -> void:
	var onde: Vector2 = _nave.global_position
	var achado: CorpoNoEspaco = null
	var menor: float = INF
	for corpo: CorpoNoEspaco in _corpos:
		if not corpo.ao_alcance(onde):
			continue
		var quanto: float = corpo.global_position.distance_to(onde)
		if quanto < menor:
			menor = quanto
			achado = corpo
	if achado == _convidando:
		return
	_apagar_convite()
	_convidando = achado
	if achado != null:
		achado.destacar(true)
		_orbita.convidar(achado.planeta.nome)


func _apagar_convite() -> void:
	if _convidando != null:
		_convidando.destacar(false)
		_convidando = null
	_orbita.retirar_convite()


## Sair por um lado é entrar pelo outro. A região é uma tela, então dar a volta é
## o que sobra: não há mapa ao lado para onde ir, e sumir pela borda seria pior.
## Só nos lados: para baixo está o chão, e para cima está a tela de regiões.
func _dar_a_volta() -> void:
	var area: Rect2 = _lugar.area_da_regiao()
	var onde: Vector2 = _nave.global_position
	if onde.x < area.position.x:
		_nave.deslocar(Vector2(area.size.x, 0.0))
	elif onde.x > area.end.x:
		_nave.deslocar(Vector2(-area.size.x, 0.0))


## O mesmo, no espaço, e nos quatro lados.
##
## **Cruzar a borda não é um evento, e não deve parecer um.** O movimento não
## muda, a câmera pula junto sem deslizar nem recalcular o rumo, e o campo de
## estrelas fecha porque o tamanho do sistema é múltiplo do mosaico dele. Quem
## atravessa só descobre olhando o mapa.
func _fechar_o_espaco() -> void:
	var onde: Vector2 = _nave.global_position
	var volta := Vector2.ZERO
	if onde.x < espaco.position.x:
		volta.x = espaco.size.x
	elif onde.x > espaco.end.x:
		volta.x = -espaco.size.x
	if onde.y < espaco.position.y:
		volta.y = espaco.size.y
	elif onde.y > espaco.end.y:
		volta.y = -espaco.size.y
	if volta == Vector2.ZERO:
		return
	_nave.deslocar(volta)
	# A câmera trata o salto sozinha, no quadro em que a física publica a posição nova.


func _guardar_nave() -> void:
	_nave.congelar()
	_nave.hide()


func _montar_regiao(corpo: CorpoNoEspaco, ficha: FichaDeRegiao) -> void:
	_esvaziar_lugar()
	var regiao: Regiao = ficha.cena.instantiate()
	regiao.position = corpo.canto_da_regiao()
	_lugar_atual.add_child(regiao)
	regiao.aplicar(corpo.planeta)
	_regiao = regiao
	_lugar = corpo
	_ficha = ficha


## Descarta na hora o que sobrou de uma troca anterior. Uma região saindo ainda
## está na cena enquanto se dissolve, e duas regiões juntas seriam dois terrenos.
func _esvaziar_lugar() -> void:
	for filho: Node in _lugar_atual.get_children():
		filho.free()
	_regiao = null


func _cancelar_a_chegada() -> void:
	if _chegada != null and _chegada.is_valid():
		_chegada.kill()
	_chegada = null


func _ao_terminar_a_chegada(_corpo: CorpoNoEspaco, destino: Vector2) -> void:
	_chegada = null
	vista = Vista.SUPERFICIE
	_hud.show()
	# O lugar diz o que exige do pouso; no espaço não há lugar e valem só os
	# limites do trem de pouso.
	_nave.especificacao = _ficha.pouso if _ficha != null else null
	_hud.avaliar_pouso(true)
	_nave.soltar()
	# Descongelar um corpo cinemático devolve a ele a velocidade do último
	# empurrão do tween. Recolocar zera as três coisas: posição, velocidade e giro.
	_nave.reposicionar(destino)


## A demarcação responde ao pouso: quem está descendo precisa saber que o contato
## valeu sem tirar o olho da nave. A nave avisa por sinal, e a cena do sistema
## repassa, porque uma região não conhece a nave.
func _ao_mudar_o_pouso(novo: Nave.Estado) -> void:
	for no: Node in get_tree().get_nodes_in_group("pontos_de_coleta"):
		if no is PontoDeColeta:
			(no as PontoDeColeta).mostrar(novo)


func _ao_escolher_regiao(ficha: FichaDeRegiao) -> void:
	chegar_em(_lugar, ficha)


func _ao_fechar_orbita() -> void:
	voltar_para_o_espaco()

