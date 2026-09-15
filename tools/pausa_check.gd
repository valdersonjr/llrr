extends Node

## Ferramenta de dev: confere a pausa dentro do jogo.
##
##   godot --headless --path . --scene res://tools/pausa_check.tscn
##
## A pausa é a tela que mais quebra sem ninguém ver: ela precisa parar o jogo e
## continuar respondendo, abrir só quando não há outra tela na frente, perguntar
## antes de jogar o voo fora e devolver o jogo andando de onde parou. Sai com
## código diferente de zero quando um critério falha, então serve em script.

var _falhas: int = 0


func _ready() -> void:
	var sistema: Node2D = load("res://mundo/sistema/sistema.tscn").instantiate()
	add_child(sistema)
	for _i: int in 8:
		await get_tree().physics_frame
		if sistema.nasceu():
			break
	var pausa: TelaDePausa = sistema.get_node("Interface/Pausa")
	var mapa: Mapa = sistema.get_node("Interface/Mapa")
	var nave: Nave = sistema.get_node("Nave")
	print("--- conferência de pausa ---")

	nave.reposicionar(nave.global_position, Vector2(120.0, 0.0))
	await _quadros(2)
	_apertar("pausa")
	await _quadros(3)
	_exigir(pausa.aberta() and get_tree().paused, "a tecla de pausa abre a pausa e para o jogo")
	var parada: Vector2 = nave.global_position
	await _quadros(20)
	print("  nave pausada:        andou %.2f px em 20 quadros" % nave.global_position.distance_to(parada))
	_exigir(nave.global_position.distance_to(parada) < 0.5, "com o jogo pausado a nave não anda")
	var foco: Control = get_viewport().gui_get_focus_owner()
	_exigir(foco != null and foco.name == "Continuar", "a pausa abre com CONTINUAR sob o foco")

	(pausa.get_node("Painel/Conteudo/Opcoes/Menu") as Button).pressed.emit()
	await _quadros(2)
	_exigir((pausa.get_node("Painel/Conteudo/Confirmacao") as Control).visible, "voltar ao menu pergunta antes")
	foco = get_viewport().gui_get_focus_owner()
	_exigir(foco != null and foco.name == "Nao", "a pergunta abre com NÃO sob o foco")
	_apertar("ui_cancel")
	await _quadros(2)
	_exigir(pausa.aberta() and (pausa.get_node("Painel/Conteudo/Opcoes") as Control).visible,
		"cancelar a pergunta volta às opções da pausa, sem sair do jogo")

	(pausa.get_node("Painel/Conteudo/Opcoes/Configuracoes") as Button).pressed.emit()
	await _quadros(2)
	var configuracoes: TelaDeConfiguracoes = pausa.get_node("Configuracoes")
	_exigir(configuracoes.visible, "OPÇÕES abre as configurações por cima da pausa")
	_apertar("ui_cancel")
	await _quadros(2)
	_exigir(not configuracoes.visible and pausa.aberta(), "fechar as configurações volta para a pausa")

	_apertar("pausa")
	await _quadros(3)
	_exigir(not pausa.aberta() and not get_tree().paused, "a mesma tecla retoma o jogo")
	await _quadros(10)
	_exigir(nave.global_position.distance_to(parada) > 1.0, "retomado, o voo continua de onde parou")

	_apertar("mapa")
	await _quadros(3)
	_apertar("pausa")
	await _quadros(3)
	_exigir(mapa.aberto() and not pausa.aberta(), "com o mapa aberto a pausa não abre por cima dele")

	get_tree().paused = false
	print("--- %s ---" % ("tudo certo" if _falhas == 0 else "%d critério(s) falhou(aram)" % _falhas))
	get_tree().quit(_falhas)


## Espera quadros de processo e de física juntos. A tecla só chega no quadro de
## processo seguinte, e vários passos de física podem rodar antes dele: esperar só
## física confere antes de a tecla ter sido lida.
func _quadros(quantos: int) -> void:
	for _i: int in quantos:
		await get_tree().process_frame
		await get_tree().physics_frame


## Aperta e solta uma ação pelo caminho de verdade, e não chamando a função direto:
## o fio entre a tecla e o que ela faz é parte do que se está conferindo.
func _apertar(acao: String) -> void:
	for apertada: bool in [true, false]:
		var tecla := InputEventAction.new()
		tecla.action = acao
		tecla.pressed = apertada
		Input.parse_input_event(tecla)


func _exigir(condicao: bool, descricao: String) -> void:
	print("  [%s] %s" % ["ok" if condicao else "FALHOU", descricao])
	if not condicao:
		_falhas += 1
