extends Node

## Ferramenta de dev: confere o caminho inteiro de entrar e sair de um planeta.
##
##   godot --headless --path . --scene res://tools/orbita_check.tscn
##
## O que ela protege é a promessa nova: **onde a nave aparece é escolha de quem
## desenhou o lugar**, não consequência da trajetória. Se a chegada parar em
## outro ponto, ou parar andando, o pouso começa diferente do que o projetista
## desenhou e nenhum lugar fica calibrável.
##
## Ela também guarda a volta ao mundo da região, que é a única saída pelos lados,
## o convite de entrada e a borda do sistema: o espaço é finito e dá a volta nos
## quatro lados, e uma nave que escapa disso fica perdida para sempre. Sai com código diferente de zero quando um
## critério falha, então serve em script.

const QUADROS_DE_CHEGADA: int = 240
const QUADROS_DE_SUBIDA: int = 900
const QUADROS_DE_ESPERA: int = 120

var _falhas: int = 0


func _ready() -> void:
	var sistema: Node2D = load("res://mundo/sistema/sistema.tscn").instantiate()
	add_child(sistema)
	var nave: Nave = sistema.get_node("Nave")
	var orbita: Orbita = sistema.get_node("Interface/Orbita")
	var identidade: int = nave.get_instance_id()
	for _i: int in 8:
		await get_tree().physics_frame
		if sistema.nasceu():
			break

	var lugar: CorpoNoEspaco = sistema.corpos()[0]
	var ficha: FichaDeRegiao = lugar.planeta.regioes[0]
	var ponto: Vector2 = lugar.canto_da_regiao() + ficha.onde_a_nave_aparece
	print("--- conferência de órbita: %s ---" % lugar.planeta.nome)
	print("  abre em:             (%.0f, %.0f), no espaço" % [
		nave.global_position.x, nave.global_position.y
	])
	_exigir(sistema.no_espaco(), "o jogo abre no espaço, e não dentro de um lugar")
	_exigir(nave.global_position.distance_to(sistema.nascer_em) < 2.0,
		"a nave nasce no ponto de partida que a cena do sistema define")
	_exigir(not nave.congelada() and nave.visible, "abre com a nave solta e à vista")
	# Com a câmera afastada, o desenho da nave só fica nítido se cada pixel da arte
	# cair num pixel inteiro de janela. Mexeu no zoom sem mexer na escala, borra.
	var zoom_do_espaco: float = (sistema.get_node("Camera") as CameraDoSistema).zoom_no_espaco
	_exigir(absf(nave.escala_do_desenho() * zoom_do_espaco - 0.5) < 0.001,
		"no espaço cada pixel da nave cai em meio pixel da tela base (escala %.4f, zoom %.2f)" % [
			nave.escala_do_desenho(), zoom_do_espaco
		])
	_exigir(_regioes_na_cena(sistema) == 0, "abre sem região nenhuma carregada")

	sistema.chegar_em(lugar, ficha)
	await _esperar_superficie(sistema)
	print("  primeira região:     %s" % ficha.nome)
	print("  ponto de chegada:    pedido (%.0f, %.0f), chegou (%.0f, %.0f)" % [
		ponto.x, ponto.y, nave.global_position.x, nave.global_position.y
	])
	_exigir(sistema.em_superficie(), "escolher uma região põe o jogador no comando dela")
	_exigir(is_equal_approx(nave.escala_do_desenho(), 1.0), "numa região a nave volta ao tamanho de arte")
	_exigir(nave.global_position.distance_to(ponto) < 2.0,
		"a chegada termina no ponto de aparecimento que a ficha da região definiu")
	_exigir(nave.velocidade() < 0.2, "a chegada termina parada, e não andando")

	# --- a volta ao mundo ----------------------------------------------------
	var area: Rect2 = lugar.area_da_regiao()
	nave.reposicionar(Vector2(area.position.x + 8.0, area.position.y + 60.0))
	# Girando e caindo: é assim que se prova que a volta continua o voo em vez de
	# recomeçá-lo. Ângulo e giro são justamente o que um recomeço zeraria.
	nave.angular_velocity = 1.2
	for _i: int in 8:
		await get_tree().physics_frame
	var giro_antes: float = nave.giro_por_segundo()
	var angulo_antes: float = nave.inclinacao_em_graus()
	var lateral_antes: float = Escala.para_metros(nave.linear_velocity.x)
	nave.deslocar(Vector2(-16.0, 0.0))
	# O servidor de física só publica a posição nova no passo seguinte, e a volta
	# é medida num terceiro. Esperar um quadro só leria a nave ainda fora.
	for _i: int in 6:
		await get_tree().physics_frame
		if nave.global_position.x > area.get_center().x:
			break
	print("  volta ao mundo:      voltou em x=%.0f (região de %.0f a %.0f)" % [
		nave.global_position.x, area.position.x, area.end.x
	])
	print("  no instante da volta: %.2f m/s de lado e %.0f °/s antes, %.2f e %.0f depois" % [
		lateral_antes, giro_antes, Escala.para_metros(nave.linear_velocity.x),
		nave.giro_por_segundo()
	])
	_exigir(nave.global_position.x > area.end.x - 80.0,
		"saindo pela esquerda, a nave reaparece na direita")
	_exigir(absf(Escala.para_metros(nave.linear_velocity.x) - lateral_antes) < 0.2,
		"dar a volta não mexe na velocidade")
	_exigir(absf(nave.giro_por_segundo() - giro_antes) < 4.0
			and absf(nave.inclinacao_em_graus() - angulo_antes) < 12.0,
		"dar a volta não mexe no ângulo nem no giro")

	# --- subir devolve a tela de regiões -------------------------------------
	nave.reposicionar(Vector2(area.get_center().x, area.position.y + 40.0), Vector2(0.0, -200.0))
	var subiu: bool = false
	for _i: int in QUADROS_DE_SUBIDA:
		await get_tree().physics_frame
		if orbita.aberta():
			subiu = true
			break
	print("  ao subir:            vista %d, região na cena: %s" % [
		sistema.vista, "sim" if _regioes_na_cena(sistema) > 0 else "não"
	])
	_exigir(subiu, "ganhar altitude devolve a tela de regiões")
	_exigir(nave.congelada(), "na tela de regiões a nave fica parada")
	_exigir(not nave.visible, "na tela de regiões a nave sai da tela")
	_exigir(_regioes_na_cena(sistema) == 0, "a região sai da cena quando a tela de regiões abre")

	# --- escolher a região de novo -------------------------------------------
	sistema.chegar_em(lugar, ficha)
	await _esperar_superficie(sistema)
	_exigir(nave.global_position.distance_to(ponto) < 2.0,
		"escolher a região de novo devolve a nave ao mesmo ponto")

	# --- voltar ao espaço ----------------------------------------------------
	sistema.voltar_para_a_orbita()
	await get_tree().physics_frame
	# Pelo botão, e não pela função: quem entrou de mouse sai de mouse, e é o fio
	# entre os dois que pode arrebentar sem ninguém perceber.
	var sair: Button = orbita.get_node("Selecao/Sair")
	sair.pressed.emit()
	for _i: int in QUADROS_DE_ESPERA:
		await get_tree().physics_frame
		if sistema.no_espaco():
			break
	print("  no espaço:           nave em (%.0f, %.0f), corpo em (%.0f, %.0f)" % [
		nave.global_position.x, nave.global_position.y,
		lugar.global_position.x, lugar.global_position.y
	])
	_exigir(sistema.no_espaco(), "o botão de sair devolve a nave ao espaço")
	_exigir(not nave.congelada(), "no espaço a nave volta a voar")
	_exigir(sistema.corpo_ao_alcance() == lugar,
		"parada perto do corpo, a nave recebe o convite de entrada")

	# --- o espaço dá a volta -------------------------------------------------
	var espaco: Rect2 = sistema.espaco
	var fora: Vector2 = Vector2(espaco.end.x + 30.0, espaco.get_center().y)
	nave.reposicionar(fora)
	for _i: int in 8:
		await get_tree().physics_frame
		if nave.global_position.x < espaco.get_center().x:
			break
	print("  borda do sistema:    saiu em x=%.0f, voltou em x=%.0f (de %.0f a %.0f)" % [
		fora.x, nave.global_position.x, espaco.position.x, espaco.end.x
	])
	_exigir(nave.global_position.x < espaco.position.x + 200.0,
		"saindo pela direita do sistema, a nave reaparece na esquerda")

	var acima: Vector2 = Vector2(espaco.get_center().x, espaco.position.y - 30.0)
	nave.reposicionar(acima)
	for _i: int in 8:
		await get_tree().physics_frame
		if nave.global_position.y > espaco.get_center().y:
			break
	_exigir(nave.global_position.y > espaco.end.y - 200.0,
		"saindo por cima do sistema, a nave reaparece embaixo")

	# Voando de verdade através da borda, a câmera não pode deslizar pelo sistema: a
	# distância entre ela e a nave, com a volta do espaço tirada, fica a mesma de um
	# passo para o outro. É isso que o jogador lê como continuidade.
	var camera: Camera2D = sistema.get_node("Camera")
	nave.reposicionar(Vector2(espaco.end.x - 1200.0, espaco.get_center().y + 300.0), Vector2(600.0, 0.0))
	for _i: int in 90:
		await get_tree().physics_frame
	var anterior: Vector2 = _sem_volta(camera.get_screen_center_position() - nave.global_position, espaco.size)
	var maior_tranco: float = 0.0
	var atravessou: bool = false
	for _i: int in 60:
		await get_tree().physics_frame
		var agora: Vector2 = _sem_volta(camera.get_screen_center_position() - nave.global_position, espaco.size)
		maior_tranco = maxf(maior_tranco, agora.distance_to(anterior))
		anterior = agora
		atravessou = atravessou or nave.global_position.x < espaco.get_center().x
	print("  voo pela borda:      atravessou %s, maior tranco da câmera %.1f px" % [
		"sim" if atravessou else "não", maior_tranco
	])
	_exigir(atravessou and maior_tranco < 20.0,
		"voando pela borda do sistema, a câmera acompanha a nave sem deslizar pelo espaço")

	# A travessia só é invisível se o campo de estrelas fechar nela, e ele só
	# fecha se uma volta inteira do sistema deslocar um número redondo de
	# mosaicos. É uma conta, não um gosto: mexer no tamanho do espaço sem olhar
	# para ela reabre a costura.
	for camada: CampoDeEstrelas in sistema.get_node("Estrelas").get_children():
		var passo: Vector2 = espaco.size * camada.fator
		var mosaico: Vector2 = camada.mosaico()
		var inteiro: bool = (
			is_zero_approx(fposmod(passo.x, mosaico.x))
			and is_zero_approx(fposmod(passo.y, mosaico.y))
		)
		print("  estrelas %-8s   a volta anda %s, no mosaico de %s" % [
			camada.name, passo, mosaico
		])
		_exigir(inteiro, "o campo de estrelas %s fecha na borda do sistema" % camada.name)

	# --- o mapa --------------------------------------------------------------
	var mapa: Mapa = sistema.get_node("Interface/Mapa")
	nave.reposicionar(espaco.get_center(), Vector2(180.0, 0.0))
	_apertar("mapa")
	await get_tree().physics_frame
	await get_tree().process_frame
	var marcador_antes: Vector2 = mapa.ponto_da_nave()
	var onde_antes: Vector2 = nave.global_position
	for _i: int in 60:
		await get_tree().physics_frame
	print("  mapa:                aberto: %s, marcador de (%.1f, %.1f) para (%.1f, %.1f)" % [
		"sim" if mapa.aberto() else "não",
		marcador_antes.x, marcador_antes.y, mapa.ponto_da_nave().x, mapa.ponto_da_nave().y
	])
	_exigir(mapa.aberto(), "a tecla M abre o mapa do sistema")
	_exigir(nave.global_position.distance_to(onde_antes) > 100.0,
		"com o mapa aberto a nave continua voando")
	_exigir(mapa.ponto_da_nave().distance_to(marcador_antes) > 1.0,
		"o marcador da nave anda no mapa junto com ela")
	_apertar("mapa")
	await get_tree().physics_frame
	await get_tree().process_frame
	_exigir(not mapa.aberto(), "a mesma tecla fecha o mapa")

	# --- a tecla de entrada --------------------------------------------------
	nave.reposicionar(lugar.global_position + Vector2(0.0, -lugar.raio() - 120.0))
	for _i: int in 8:
		await get_tree().physics_frame
		if sistema.nasceu():
			break
	_apertar("entrar")
	await get_tree().physics_frame
	await get_tree().process_frame
	_exigir(orbita.aberta(), "a tecla de entrada abre a tela de regiões")
	var marcadores: Array = orbita.get_node("Selecao/Carta/Marcadores").get_children().filter(
		func(no: Node) -> bool: return not no.is_queued_for_deletion()
	)
	_exigir(marcadores.size() == lugar.planeta.regioes.size(),
		"a tela de regiões põe um marcador por região na carta")
	_exigir(nave.get_instance_id() == identidade,
		"a mesma instância da nave atravessou tudo, sem ser recriada")

	# --- os lugares do sistema -----------------------------------------------
	# Leitura de ficha, sem carregar terreno: é o mesmo que a tela de regiões faz.
	for corpo: CorpoNoEspaco in sistema.corpos():
		var mapa_do_lugar: Rect2 = corpo.area_da_regiao()
		var nomes: PackedStringArray = PackedStringArray()
		var inteiro: bool = not corpo.planeta.regioes.is_empty()
		for ficha_do_lugar: FichaDeRegiao in corpo.planeta.regioes:
			nomes.append(ficha_do_lugar.nome)
			var ponto_de_chegada: Vector2 = mapa_do_lugar.position + ficha_do_lugar.onde_a_nave_aparece
			inteiro = (
				inteiro
				and ficha_do_lugar.cena != null
				and not ficha_do_lugar.nome.is_empty()
				and mapa_do_lugar.has_point(ponto_de_chegada)
			)
		print("  %-6s tem %d região(ões): %s" % [
			corpo.planeta.nome, corpo.planeta.regioes.size(), ", ".join(nomes)
		])
		_exigir(inteiro, "as regiões de %s têm nome, cena e ponto de chegada dentro do mapa" % corpo.planeta.nome)
		var carta: Rect2 = _retangulo_da_carta(corpo.planeta)
		var na_carta: bool = carta.has_area()
		for ficha_do_lugar: FichaDeRegiao in corpo.planeta.regioes:
			na_carta = na_carta and carta.has_point(Vector2(ficha_do_lugar.ponto_na_carta))
		print("  %-6s carta de %s px" % [corpo.planeta.nome, carta.size])
		# O corpo é pixel art em pixel de tela: a escala da arte desfaz o zoom da
		# câmera no espaço. Mexeu num sem mexer no outro, o planeta borra.
		var zoom: float = (sistema.get_node("Camera") as CameraDoSistema).zoom_no_espaco
		_exigir(absf(corpo.escala_da_arte() * zoom - 1.0) < 0.001,
			"%s é desenhado em pixel de tela no espaço (escala da arte %.4f, zoom %.2f)" % [
				corpo.planeta.nome, corpo.escala_da_arte(), zoom
			])
		_exigir(na_carta, "%s tem carta de superfície e o marcador de cada região cai dentro dela" % corpo.planeta.nome)

	# --- cada região de cada lugar, em voo ------------------------------------
	# Percorre todas, e não só a primeira de cada corpo: presumir quantas existem
	# é como esta conferência quebrou quando entrou o terceiro planeta, e de novo
	# quando um planeta ganhou a segunda região.
	for corpo: CorpoNoEspaco in sistema.corpos():
		for ficha_de_la: FichaDeRegiao in corpo.planeta.regioes:
			if corpo == lugar and ficha_de_la == ficha:
				continue
			sistema.chegar_em(corpo, ficha_de_la)
			await _esperar_superficie(sistema)
			var la: Vector2 = corpo.canto_da_regiao() + ficha_de_la.onde_a_nave_aparece
			print("  %s / %s: chegou a (%.0f, %.0f), pedido (%.0f, %.0f)" % [
				corpo.planeta.nome, ficha_de_la.nome,
				nave.global_position.x, nave.global_position.y, la.x, la.y
			])
			_exigir(nave.global_position.distance_to(la) < 2.0,
				"a chegada em %s termina no ponto da ficha" % ficha_de_la.nome)
			_exigir(not orbita.aberta(),
				"chegar em %s tira a tela de regiões da frente" % ficha_de_la.nome)

	print("--- %s ---" % ("tudo certo" if _falhas == 0 else "%d critério(s) falhou(aram)" % _falhas))
	get_tree().quit(_falhas)


## Aperta uma ação pelo caminho de verdade, e não chamando a função direto: o fio
## entre a tecla e o que ela faz é parte do que se está conferindo.
## Uma diferença de posição com a volta do espaço tirada: a menor, nos dois eixos.
func _sem_volta(diferenca: Vector2, tamanho: Vector2) -> Vector2:
	return Vector2(
		wrapf(diferenca.x, -tamanho.x * 0.5, tamanho.x * 0.5),
		wrapf(diferenca.y, -tamanho.y * 0.5, tamanho.y * 0.5)
	)


func _apertar(acao: String) -> void:
	var tecla := InputEventAction.new()
	tecla.action = acao
	tecla.pressed = true
	Input.parse_input_event(tecla)


func _esperar_superficie(sistema: Node2D) -> void:
	for _i: int in QUADROS_DE_CHEGADA:
		await get_tree().physics_frame
		if sistema.em_superficie():
			return


## O tamanho da carta sai dos tiles pintados, e não de um número guardado à parte:
## é o desenho que diz até onde a carta vai.
func _retangulo_da_carta(planeta: Planeta) -> Rect2:
	if planeta.carta == null:
		return Rect2()
	var carta: Node = planeta.carta.instantiate()
	var area := Rect2()
	for camada: Node in carta.get_children():
		if camada is TileMapLayer:
			var tile: Vector2i = (camada as TileMapLayer).tile_set.tile_size
			var usado: Rect2i = (camada as TileMapLayer).get_used_rect()
			var em_pixels := Rect2(Vector2(usado.position * tile), Vector2(usado.size * tile))
			area = em_pixels if not area.has_area() else area.merge(em_pixels)
	carta.free()
	return area


func _regioes_na_cena(sistema: Node2D) -> int:
	var quantas: int = 0
	for filho: Node in sistema.get_node("LugarAtual").get_children():
		if filho is Regiao:
			quantas += 1
	return quantas


func _exigir(condicao: bool, descricao: String) -> void:
	print("  [%s] %s" % ["ok" if condicao else "FALHOU", descricao])
	if not condicao:
		_falhas += 1
