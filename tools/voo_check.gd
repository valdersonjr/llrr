extends Node

## Ferramenta de dev: conferência dos critérios de voo e pouso, sem abrir janela.
##
##   godot --headless --path . --scene res://tools/voo_check.tscn
##
## Ela mede a gravidade do planeta em queda livre, solta a nave sobre o deque e
## diz o que aconteceu. Existe porque `--check-only` não carrega autoload nem roda
## física: a única verificação real de pilotagem é subir o jogo. Sai com código
## diferente de zero quando um critério falha, então serve em script.

## Todos os pontos abaixo são **coordenada de região**, não de mundo: a região
## nasce onde o corpo dela está no sistema, e o canto é somado na hora de usar.
## Ar aberto no meio do vale, e dentro do campo gravitacional da região.
const ALTURA_DE_MEDICAO: Vector2 = Vector2(330.0, 100.0)
## Soltura e partida são medidas a partir do ponto de coleta da região, e não em
## coordenada fixa: assim a conferência vale para qualquer região que seja a
## primeira do planeta, e não para um desenho de terreno em particular.
const SOLTURA_ACIMA_DO_PONTO: Vector2 = Vector2(20.0, -78.0)
const QUADROS_DE_MEDICAO: int = 12
const QUADROS_DE_POUSO: int = 420
## Ponto de partida do pouso controlado, acima do ponto de coleta, no ar livre.
const PARTIDA_ACIMA_DO_PONTO: Vector2 = Vector2(20.0, -80.0)
## Velocidade de descida que o piloto automático da conferência persegue, em m/s.
const DESCIDA_ALVO: float = 1.4
const QUADROS_DE_DESCIDA: int = 1500

var _visto: PackedStringArray = PackedStringArray()
var _falhas: int = 0
var _canto: Vector2 = Vector2.ZERO
var _ponto: Vector2 = Vector2.ZERO


func _ready() -> void:
	var sistema: Node2D = load("res://mundo/sistema/sistema.tscn").instantiate()
	add_child(sistema)
	var nave: Nave = sistema.get_node("Nave")
	# O jogo abre no espaço, à deriva. Quem mede pilotagem precisa de chão, então
	# a ferramenta desce ela mesma no primeiro lugar do sistema e espera a chegada
	# por piloto automático terminar: durante ela a nave está congelada.
	# O nascimento no espaço é adiado um quadro pelo próprio sistema: mandar a
	# nave para um lugar antes disso seria disputar o comando com ele.
	for _i: int in 8:
		await get_tree().physics_frame
		if sistema.nasceu():
			break
	var lugar: CorpoNoEspaco = sistema.corpos()[0]
	var planeta: Planeta = lugar.planeta
	sistema.chegar_em(lugar, planeta.regioes[0])
	for _i: int in 240:
		await get_tree().physics_frame
		if sistema.em_superficie():
			break
	_canto = lugar.canto_da_regiao()
	var pontos: Array[Node] = get_tree().get_nodes_in_group("pontos_de_coleta")
	if pontos.is_empty():
		push_error("voo_check: a região %s não tem ponto de coleta" % planeta.regioes[0].nome)
		get_tree().quit(1)
		return
	_ponto = (pontos[0] as Node2D).global_position

	var formas: int = 0
	for filho: Node in nave.get_children():
		if filho is CollisionPolygon2D:
			formas += 1
	print("--- conferência de voo: %s ---" % planeta.nome)
	print("  casco:               %d forma(s) de colisão tirada(s) do alfa" % formas)
	var medida: float = await _medir_gravidade(nave)
	print("  gravidade na ficha:  %.2f m/s²" % planeta.gravidade)
	print("  gravidade medida:    %.2f m/s²" % medida)
	var erro: float = absf(medida - planeta.gravidade) / planeta.gravidade
	_exigir(erro < 0.10, "a queda livre reproduz a gravidade da ficha, com %.0f%% de erro" % (erro * 100.0))

	nave.pouso_mudou.connect(func(novo: Nave.Estado) -> void:
		_visto.append(Nave.Estado.keys()[novo])
	)
	nave.reposicionar(_ponto + SOLTURA_ACIMA_DO_PONTO)
	var pico: float = 0.0
	for _i: int in QUADROS_DE_POUSO:
		await get_tree().physics_frame
		pico = maxf(pico, nave.velocidade())

	print("  caminho de estados:  %s" % ", ".join(_visto))
	print("  queda livre tocou a: %.1f m/s (limite do trem: %.1f)" % [
		nave.velocidade_do_toque, nave.modelo.velocidade_maxima_de_toque
	])
	print("  em repouso:          %.2f m/s, %.2f °/s" % [nave.velocidade(), nave.giro_por_segundo()])
	print("  estado final:        %s" % Nave.Estado.keys()[nave.estado])

	_exigir(nave.estado == Nave.Estado.POUSADA, "solta em queda curta, a nave assenta")
	_exigir(nave.velocidade() < 0.2, "parada no chão, a nave não anda sozinha")
	_exigir(_visto.has("TOCANDO"), "o contato passa por TOCANDO antes de valer")
	_exigir(nave.velocidade_do_toque > nave.modelo.velocidade_maxima_de_toque,
		"em queda livre o toque passa do limite do trem")
	_exigir(nave.inclinacao_em_graus() < nave.modelo.inclinacao_em_graus,
		"com o centro de massa embaixo, a nave assenta em pé e não tomba")

	var descida: Dictionary = await _pouso_controlado(nave)
	print("  descida freada:      toque a %.2f m/s em %d quadros (limite do trem: %.1f)" % [
		descida["toque"], descida["quadros"], nave.modelo.velocidade_maxima_de_toque
	])
	_exigir(descida["pousou"], "freando na descida, a nave chega a POUSADA")
	_exigir(descida["toque"] <= nave.modelo.velocidade_maxima_de_toque,
		"o empuxo disponível permite tocar dentro do limite do trem de pouso")

	print("--- %s ---" % ("tudo certo" if _falhas == 0 else "%d critério(s) falhou(aram)" % _falhas))
	get_tree().quit(_falhas)


## Desce até o deque freando, pelo mesmo caminho de entrada que o jogador usa: a
## ação `empuxo` do mapa de entrada. Se este critério falha, o empuxo da ficha não
## dá conta da gravidade do planeta e o pouso é impossível, não difícil.
func _pouso_controlado(nave: Nave) -> Dictionary:
	nave.reposicionar(_ponto + PARTIDA_ACIMA_DO_PONTO)
	# Esperar a nave largar o estado do teste anterior. Sem isto o laço abaixo
	# encerra na primeira volta ainda POUSADA e o critério passa sem voar nada.
	for _espera: int in 30:
		await get_tree().physics_frame
		if nave.estado == Nave.Estado.VOANDO:
			break
	if nave.estado != Nave.Estado.VOANDO:
		# Mesmas três chaves do retorno de baixo: quem chama imprime todas elas.
		return {"pousou": false, "toque": INF, "quadros": 0}

	var pousou: bool = false
	var gastos: int = 0
	for _i: int in QUADROS_DE_DESCIDA:
		gastos += 1
		if nave.estado == Nave.Estado.VOANDO:
			if Escala.para_metros(nave.linear_velocity.y) > DESCIDA_ALVO:
				Input.action_press("empuxo", 1.0)
			else:
				Input.action_release("empuxo")
		else:
			Input.action_release("empuxo")
		await get_tree().physics_frame
		if nave.estado == Nave.Estado.POUSADA:
			pousou = true
			break
	Input.action_release("empuxo")
	return {"pousou": pousou, "toque": nave.velocidade_do_toque, "quadros": gastos}


## Mede a aceleração numa janela curta, logo no começo da queda, onde a velocidade
## ainda é baixa e o arrasto do ar quase não conta.
func _medir_gravidade(nave: Nave) -> float:
	nave.reposicionar(_canto + ALTURA_DE_MEDICAO)
	await get_tree().physics_frame
	var antes: float = nave.velocidade()
	for _i: int in QUADROS_DE_MEDICAO:
		await get_tree().physics_frame
	var depois: float = nave.velocidade()
	var segundos: float = float(QUADROS_DE_MEDICAO) / float(Engine.physics_ticks_per_second)
	return (depois - antes) / segundos


func _exigir(condicao: bool, descricao: String) -> void:
	print("  [%s] %s" % ["ok" if condicao else "FALHOU", descricao])
	if not condicao:
		_falhas += 1
