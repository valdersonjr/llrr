extends Node
## Confere o voo contra os critérios de aceitação do conceito.
##
## A seção 4 de `docs/conceito-de-jogo.md` termina com uma lista de "sinais de
## que a pilotagem está certa". Esta ferramenta transforma cada sinal num
## cenário: posiciona a nave, aperta as teclas por código e olha o resultado.
## Não é framework de teste — é o jeito de checar a física sem depender de
## alguém segurando W na hora certa.
##
## Roda como cena, não como `--script`: um script passado em `--script` é
## compilado antes de os autoloads existirem, e aí qualquer script de jogo que
## use um deles falha a compilação — inclusive os que a ferramenta só queria
## carregar.
##
## Uso:
##   godot --headless --path . --scene res://tools/voo_check.tscn
##
## Sai com o número de falhas como código de saída.

const CENA := "res://stages/teste_pouso/teste_pouso.tscn"
const ACOES := ["empuxo", "girar_esquerda", "girar_direita",
	"lateral_esquerda", "lateral_direita"]

## Plataforma larga da fase de teste: centro em x, topo do deck em y.
const PLATAFORMA_LARGA := Vector2(112.0, 356.0)
## Trecho de terreno plano sem plataforma nenhuma.
const CHAO_NU := Vector2(24.0, 352.0)
## Vem do catálogo, não de uma lista aqui: casco novo entra na verificação
## sozinho, sem ninguém lembrar de acrescentá-lo em dois lugares.
const CATALOGO := preload("res://entities/player/cascos.tres")
## Distância do topo do deck até a origem da nave com os pés encostados.
const ALTURA_DOS_PES := 15.0

## Cão de guarda. Sem ele, qualquer erro que mate a corrotina deixa o processo
## rodando para sempre: `quit()` só é chamado no fim da sequência, e um script
## que não carrega nunca chega lá. Isso já travou a verificação três vezes.
const LIMITE_DE_QUADROS := 9000

var _quadros := 0
var _falhas := 0
var _nave: Nave
var _plataforma: PlataformaDePouso
var _camera: CameraSeguidora
var _fase: Node


func _ready() -> void:
	var fase := (load(CENA) as PackedScene).instantiate()
	# Diferido: em `_ready` a raiz ainda está montando os filhos dela.
	get_tree().root.add_child.call_deferred(fase)
	_fase = fase
	_nave = fase.get_node("UtilitarioLeve")
	if _nave == null:
		push_error("voo_check: a fase não tem a nave esperada")
		get_tree().quit(1)
		return
	_plataforma = fase.get_node("PlataformaLarga")
	_camera = fase.get_node("Camera")
	_rodar.call_deferred()


func _process(_delta: float) -> void:
	_quadros += 1
	if _quadros <= LIMITE_DE_QUADROS:
		return
	push_error("voo_check: %d quadros sem terminar — algo travou" % LIMITE_DE_QUADROS)
	print("\nvoo_check: TRAVOU depois de %d quadros" % LIMITE_DE_QUADROS)
	get_tree().quit(1)


func _rodar() -> void:
	await get_tree().physics_frame
	print("voo_check — critérios da seção 4 do conceito\n")
	await _vacuo_nao_freia()
	await _peso_reduz_aceleracao()
	await _sem_combustivel_sem_empuxo()
	await _estabilizacao_zera_o_giro()
	print("")
	await _parada_no_chao_nao_anda()
	await _pouso_limpo_na_plataforma()
	await _pouso_duro_custa_casco()
	await _impacto_de_casco_destroi()
	await _pouso_fora_da_plataforma()
	print("")
	await _porao_respeita_a_capacidade()
	await _carga_vai_e_volta_pelo_deck()
	await _camera_olha_a_frente()
	await _dano_muda_o_casco()
	print("")
	await _os_tres_cascos_pousam()
	print("")
	await _o_relogio_para_na_pausa()
	await _o_servico_devolve_a_nave_ao_trabalho()
	print("\nvoo_check: %d falha(s)" % _falhas)
	get_tree().quit(_falhas)


# --- critérios de pilotagem -------------------------------------------------

func _vacuo_nao_freia() -> void:
	await _preparar(Vector2(250, 60))
	_nave.velocity = Vector2(40, -25)
	var antes := _nave.velocity
	await _passos(90)
	var deriva := antes.distance_to(_nave.velocity)
	_conferir("desligar os motores no vácuo não freia", deriva < 0.01,
		"%.1f p/s por 1,5 s, Δv = %.4f" % [antes.length(), deriva])


func _peso_reduz_aceleracao() -> void:
	var vazia := await _medir_aceleracao(0.0)
	var carregada := await _medir_aceleracao(_nave.casco.capacidade_carga)
	_conferir("peso extra reduz a aceleração", carregada < vazia * 0.95,
		"vazia %.0f p/s², com %.0f t de carga %.0f p/s²" % [
			vazia, _nave.casco.capacidade_carga, carregada])


func _sem_combustivel_sem_empuxo() -> void:
	await _preparar(Vector2(250, 120))
	_nave.combustivel = 0.0
	var antes := _nave.velocity
	Input.action_press("empuxo", 1.0)
	await _passos(60)
	Input.action_release("empuxo")
	var deriva := antes.distance_to(_nave.velocity)
	_conferir("combustível zero limita o empuxo", deriva < 0.01,
		"acelerador no máximo por 1 s, Δv = %.4f" % deriva)


func _estabilizacao_zera_o_giro() -> void:
	await _preparar(Vector2(250, 120))
	_nave.giro = 60.0
	var combustivel := _nave.combustivel
	await _passos(90)
	var gasto := combustivel - _nave.combustivel
	_conferir("a estabilização zera o giro sozinha", absf(_nave.giro) < 0.5,
		"60 °/s -> %.2f °/s" % _nave.giro)
	_conferir("e cobra combustível por isso", gasto > 0.0, "gastou %.3f t" % gasto)


# --- pouso como estado ------------------------------------------------------

func _parada_no_chao_nao_anda() -> void:
	await _pousar_de(PLATAFORMA_LARGA, 2.0, 90)
	var posicao := _nave.global_position
	await _passos(120)
	var deriva := posicao.distance_to(_nave.global_position)
	_conferir("parada no chão, a nave não se move sozinha", deriva < 0.5,
		"deriva de %.3f px em 2 s" % deriva)


func _pouso_limpo_na_plataforma() -> void:
	await _pousar_de(PLATAFORMA_LARGA, 8.0, 150)
	var inteira := _nave.intacta()
	_conferir("pouso limpo não custa casco", inteira,
		"casco em %.0f%%" % (_nave.integridade_fracao() * 100.0))
	_conferir("contato estável vira POUSADA", _nave.estado == Nave.Estado.POUSADA,
		"estado = %s" % _texto_estado())
	_conferir("reconhece a plataforma sob as duas pernas",
		_nave.plataforma_sob_a_nave() != null, "plataforma = %s" % _nave.plataforma_sob_a_nave())


func _pouso_duro_custa_casco() -> void:
	await _pousar_de(PLATAFORMA_LARGA, 60.0, 150)
	var perdeu := (1.0 - _nave.integridade_fracao()) * 100.0
	_conferir("pouso duro custa casco mas é sobrevivível",
		perdeu > 0.0 and _nave.integridade > 0.0,
		"caiu de 60 px, perdeu %.0f%% do casco" % perdeu)


func _impacto_de_casco_destroi() -> void:
	await _pousar_de(PLATAFORMA_LARGA, 60.0, 150, PI)
	_conferir("de cabeça para baixo, a mesma queda destrói",
		_nave.estado == Nave.Estado.DESTRUIDA,
		"estado = %s, casco em %.0f%%" % [_texto_estado(), _nave.integridade])


func _pouso_fora_da_plataforma() -> void:
	await _pousar_de(CHAO_NU, 8.0, 150)
	_conferir("pousar no chão nu é pouso, mas não é plataforma",
		_nave.estado == Nave.Estado.POUSADA and _nave.plataforma_sob_a_nave() == null,
		"estado = %s, plataforma = %s" % [_texto_estado(), _nave.plataforma_sob_a_nave()])


# --- carga -------------------------------------------------------------------

func _porao_respeita_a_capacidade() -> void:
	await _preparar(Vector2(250, 120))
	var capacidade := _nave.casco.capacidade_carga
	var coube := _nave.carregar(capacidade + 10.0)
	_conferir("o porão não aceita mais do que cabe",
		is_equal_approx(coube, capacidade) and is_equal_approx(_nave.carga, capacidade),
		"pediu %.0f t, embarcou %.1f t" % [capacidade + 10.0, coube])


func _carga_vai_e_volta_pelo_deck() -> void:
	await _pousar_de(PLATAFORMA_LARGA, 2.0, 90)
	var no_deck := _plataforma.carga_disponivel
	var massa_vazia := _nave.massa()
	var embarcou := _plataforma.transferir(_nave)
	_conferir("embarcar tira do deck e põe no porão",
		embarcou > 0.0 and is_equal_approx(_plataforma.carga_disponivel, no_deck - embarcou),
		"%.1f t, deck de %.1f para %.1f t" % [embarcou, no_deck, _plataforma.carga_disponivel])
	_conferir("carga embarcada pesa", _nave.massa() > massa_vazia,
		"%.1f t -> %.1f t" % [massa_vazia, _nave.massa()])
	var devolvido := _plataforma.transferir(_nave)
	_conferir("descarregar devolve tudo ao deck",
		is_equal_approx(-devolvido, embarcou)
			and is_equal_approx(_plataforma.carga_disponivel, no_deck)
			and is_zero_approx(_nave.carga),
		"deck de volta em %.1f t, porão em %.1f t" % [_plataforma.carga_disponivel, _nave.carga])


func _camera_olha_a_frente() -> void:
	await _preparar(Vector2(250, 120))
	_nave.velocity = Vector2(90, 0)
	await _passos(30)
	var adiante := _camera.global_position.x - _nave.global_position.x
	_conferir("a câmera olha à frente do movimento",
		adiante > 4.0 and adiante <= _camera.antecipacao_maxima + 0.01,
		"%.1f px à frente, teto de %.0f px" % [adiante, _camera.antecipacao_maxima])


## O casco tem que MOSTRAR o dano: a seção 2 do conceito pede consequência
## legível, e integridade só na barra não é consequência legível.
func _dano_muda_o_casco() -> void:
	await _preparar(Vector2(250, 120))
	var corpo: Sprite2D = _nave.get_node("Corpo")
	var maximo := _nave.casco.integridade_maxima
	var vistos: Array[Texture2D] = []
	var estados: Array[int] = []
	for fracao in [1.0, 0.4, 0.1]:
		_nave.integridade = maximo * fracao
		estados.append(_nave.estado_de_dano())
		vistos.append(corpo.texture)
	_conferir("integridade percorre os três estados de casco", estados == [0, 1, 2],
		"100%% -> %d, 40%% -> %d, 10%% -> %d" % estados)
	_conferir("e cada estado troca a textura de fato",
		vistos[0] != vistos[1] and vistos[1] != vistos[2],
		"três texturas distintas" if vistos[0] != vistos[2] else "textura não mudou")
	_nave.integridade = maximo


## Cada casco tem sua própria colisão, seus próprios pés e sua própria
## tolerância. Um pousar não diz nada sobre os outros dois.
func _os_tres_cascos_pousam() -> void:
	for i in CATALOGO.quantidade():
		var nave := CATALOGO.criar(i)
		_fase.add_child(nave)
		await _passos(2)
		nave.gravidade = 40.0
		nave.global_position = Vector2(PLATAFORMA_LARGA.x,
			PLATAFORMA_LARGA.y - nave.altura_dos_pes - 6.0)
		nave.velocity = Vector2.ZERO
		nave.giro = 0.0
		nave.estado = Nave.Estado.VOANDO
		await _passos(150)
		var inteiro := nave.intacta()
		_conferir("%s pousa limpo e reconhece a plataforma" % nave.casco.nome,
			nave.estado == Nave.Estado.POUSADA
				and nave.plataforma_sob_a_nave() != null and inteiro,
			"casco em %.0f%%, aceleração %.0f p/s²" % [
				nave.integridade_fracao() * 100.0, nave.aceleracao_disponivel()])
		nave.queue_free()
		await _passos(3)


# --- relógio e serviço de porto -----------------------------------------------

## Seção 8: o relógio de campanha só avança com o jogo aberto, e a seção 6
## promete que inspecionar a situação pausado não é punido.
func _o_relogio_para_na_pausa() -> void:
	await _preparar(Vector2(250, 120))
	var antes := Relogio.segundos
	await _passos(30)
	var correndo := Relogio.segundos - antes
	get_tree().paused = true
	var pausado_em := Relogio.segundos
	await _passos(30)
	var na_pausa := Relogio.segundos - pausado_em
	get_tree().paused = false
	_conferir("o relógio corre em voo", correndo > 0.0, "%.0f s de campanha" % correndo)
	_conferir("e para na pausa", is_zero_approx(na_pausa), "%.4f s de campanha" % na_pausa)


## Seção 5: sempre existe um caminho verificável de volta ao trabalho. Sem
## isso, dano vira beco sem saída e o jogador só tem reiniciar.
func _o_servico_devolve_a_nave_ao_trabalho() -> void:
	await _pousar_de(PLATAFORMA_LARGA, 2.0, 90)
	_nave.integridade = _nave.casco.integridade_maxima * 0.3
	_nave.combustivel = _nave.casco.combustivel_maximo * 0.2
	var relogio_antes := Relogio.segundos
	var feito: Dictionary = _plataforma.servir(_nave)
	_conferir("o serviço repara e abastece",
		not feito.is_empty() and _nave.intacta()
			and is_equal_approx(_nave.combustivel, _nave.casco.combustivel_maximo),
		"casco em %.0f%%, tanque em %.1f t" % [
			_nave.integridade_fracao() * 100.0, _nave.combustivel])
	_conferir("e cobra tempo de campanha por isso",
		Relogio.segundos - relogio_antes > 0.0,
		"%.1f h" % ((Relogio.segundos - relogio_antes) / 3600.0))
	_conferir("plataforma sem oficina não presta serviço",
		(_fase.get_node("PlataformaEstreita") as PlataformaDePouso).servir(_nave).is_empty(),
		"o Pilar Sul recusa")


# --- utilidades -------------------------------------------------------------

func _medir_aceleracao(carga: float) -> float:
	await _preparar(Vector2(250, 120))
	_nave.carga = carga
	var antes := _nave.velocity
	Input.action_press("empuxo", 1.0)
	await _passos(30)
	Input.action_release("empuxo")
	var segundos := 30.0 / Engine.physics_ticks_per_second
	return antes.distance_to(_nave.velocity) / segundos


## Solta a nave a `altura` pixels acima de `alvo` e espera assentar.
func _pousar_de(alvo: Vector2, altura: float, quadros: int, rotacao := 0.0) -> void:
	await _preparar(Vector2(alvo.x, alvo.y - ALTURA_DOS_PES - altura), 40.0, rotacao)
	await _passos(quadros)


func _preparar(posicao: Vector2, gravidade := 0.0, rotacao := 0.0) -> void:
	for acao in ACOES:
		Input.action_release(acao)
	_nave.global_position = posicao
	_nave.rotation = rotacao
	_nave.velocity = Vector2.ZERO
	_nave.giro = 0.0
	_nave.gravidade = gravidade
	_nave.carga = 0.0
	_nave.combustivel = _nave.casco.combustivel_maximo
	_nave.integridade = _nave.casco.integridade_maxima
	_nave.estado = Nave.Estado.VOANDO
	await _passos(2)


func _passos(quantidade: int) -> void:
	for _i in quantidade:
		await get_tree().physics_frame


func _texto_estado() -> String:
	return ["VOANDO", "TOCANDO", "POUSADA", "DESTRUIDA"][_nave.estado]


func _conferir(criterio: String, passou: bool, detalhe: String) -> void:
	if not passou:
		_falhas += 1
	print("  %s  %s — %s" % ["ok   " if passou else "FALHA", criterio, detalhe])
