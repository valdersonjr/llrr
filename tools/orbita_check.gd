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
	_exigir(_regioes_na_cena(sistema) == 0, "abre sem região nenhuma carregada")

	sistema.chegar_em(lugar, ficha)
	await _esperar_superficie(sistema)
	print("  primeira região:     %s" % ficha.nome)
	print("  ponto de chegada:    pedido (%.0f, %.0f), chegou (%.0f, %.0f)" % [
		ponto.x, ponto.y, nave.global_position.x, nave.global_position.y
	])
	_exigir(sistema.em_superficie(), "escolher uma região põe o jogador no comando dela")
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

	# A travessia só é invisível se o campo de estrelas fechar nela, e ele só
	# fecha se uma volta inteira do sistema deslocar um número redondo de
	# mosaicos. É uma conta, não um gosto: mexer no tamanho do espaço sem olhar
	# para ela reabre a costura.
	for camada: CampoDeEstrelas in sistema.get_node("Estrelas").get_children():
		var passo: Vector2 = espaco.size * camada.fator
		var mosaico: Vector2 = camada.textura.get_size()
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

	# --- o segundo lugar, em voo ---------------------------------------------
	var outro: CorpoNoEspaco = null
	for corpo: CorpoNoEspaco in sistema.corpos():
		if corpo != lugar:
			outro = corpo
	if outro != null:
		var ficha_de_la: FichaDeRegiao = outro.planeta.regioes[0]
		sistema.chegar_em(outro, ficha_de_la)
		await _esperar_superficie(sistema)
		var la: Vector2 = outro.canto_da_regiao() + ficha_de_la.onde_a_nave_aparece
		print("  em %s / %s:      chegou a (%.0f, %.0f), pedido (%.0f, %.0f)" % [
			outro.planeta.nome, ficha_de_la.nome,
			nave.global_position.x, nave.global_position.y, la.x, la.y
		])
		_exigir(nave.global_position.distance_to(la) < 2.0,
			"a chegada no segundo lugar também termina no ponto da ficha")
		_exigir(not orbita.aberta(),
			"chegar numa região tira a tela de regiões da frente")

		var asteroides: Array[Node] = []
		for no: Node in sistema.get_node("LugarAtual").find_children("*", "Asteroide", true, false):
			asteroides.append(no)
		var antes_deles: Array[Vector2] = []
		for no: Node in asteroides:
			antes_deles.append((no as Node2D).position)
		for _i: int in 120:
			await get_tree().physics_frame
		var andaram: bool = not asteroides.is_empty()
		var dentro_do_mapa: bool = true
		var limite: Rect2 = Rect2(Vector2.ZERO, Regiao.TAMANHO).grow(Asteroide.MARGEM + 2.0)
		for i: int in asteroides.size():
			var agora: Vector2 = (asteroides[i] as Node2D).position
			andaram = andaram and agora.distance_to(antes_deles[i]) > 4.0
			dentro_do_mapa = dentro_do_mapa and limite.has_point(agora)
		print("  asteroides:          %d no céu da %s" % [asteroides.size(), ficha_de_la.nome])
		_exigir(andaram, "os asteroides atravessam a região em vez de ficarem parados")
		_exigir(dentro_do_mapa, "os asteroides dão a volta em vez de sumirem para sempre")

	print("--- %s ---" % ("tudo certo" if _falhas == 0 else "%d critério(s) falhou(aram)" % _falhas))
	get_tree().quit(_falhas)


## Aperta uma ação pelo caminho de verdade, e não chamando a função direto: o fio
## entre a tecla e o que ela faz é parte do que se está conferindo.
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
