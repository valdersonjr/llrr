extends Node

## Ferramenta de dev: confere a primeira tela do jogo.
##
##   godot --headless --path . --scene res://tools/menu_check.tscn
##
## O menu é a única porta de entrada, e o defeito mais caro dele é silencioso:
## um botão que não leva a lugar nenhum, ou um destino que deixou de existir
## depois de alguém mover uma cena. Nada disso aparece em compilação, só em quem
## abriu o jogo e clicou.
##
## Ela também cobra o que separa menu de protótipo de menu de jogo: opção sob o
## foco assim que a tela abre, todas alcançáveis pelo teclado, a música tocando
## em laço, a cena do título contando o laço dela, as opções guardando o que o
## jogador escolhe e os créditos abrindo.

var _falhas: int = 0


func _ready() -> void:
	var menu: Menu = load("res://ui/menu/menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame

	var opcoes: Array[Node] = menu.get_node("Painel/Opcoes").get_children()
	var nomes: PackedStringArray = PackedStringArray()
	for opcao: Node in opcoes:
		nomes.append((opcao as Button).text)

	print("--- conferência de menu ---")
	print("  opções:              %s" % ", ".join(nomes))
	_exigir(opcoes.size() >= 2, "o menu tem opções")

	var com_foco: Control = menu.get_viewport().gui_get_focus_owner()
	print("  foco ao abrir:       %s" % ("nenhum" if com_foco == null else com_foco.name))
	_exigir(com_foco == opcoes[0], "a primeira opção já está sob o foco quando a tela abre")

	var todas_ligadas: bool = true
	var todas_no_teclado: bool = true
	for opcao: Node in opcoes:
		var botao := opcao as Button
		todas_ligadas = todas_ligadas and botao.pressed.get_connections().size() > 0
		todas_no_teclado = todas_no_teclado and botao.focus_mode == Control.FOCUS_ALL
	_exigir(todas_ligadas, "nenhuma opção do menu leva a lugar nenhum")
	_exigir(todas_no_teclado, "todas as opções são alcançáveis pelo teclado")

	var musica: AudioStreamPlayer = menu.musica()
	var em_laco: bool = musica.stream != null and musica.stream.get("loop") == true
	print("  música:              %s, autoplay %s, laço %s, barramento %s" % [
		"nenhuma" if musica.stream == null else musica.stream.resource_path.get_file(),
		"sim" if musica.autoplay else "não", "sim" if em_laco else "não", musica.bus
	])
	_exigir(musica.stream != null, "o menu tem música")
	_exigir(musica.autoplay, "a música começa sozinha ao abrir a tela")
	_exigir(em_laco, "a música do menu toca em laço, e não uma vez só")
	_exigir(musica.playing, "a música está tocando quando a tela está de pé")
	_exigir(musica.bus == &"Musica", "a música do menu passa pelo barramento de música, que o volume controla")

	print("  jogar abre:          %s" % Menu.JOGO)
	_exigir(ResourceLoader.exists(Menu.JOGO), "a cena que o menu abre existe")
	var jogo: PackedScene = load(Menu.JOGO)
	_exigir(jogo != null and jogo.can_instantiate(), "a cena que o menu abre carrega e monta")

	# --- a cena do título -----------------------------------------------------
	var cena: CenaDoTitulo = menu.get_node("Cena")
	print("  nave no laço:        %.0f px acima em 1 s, %.0f em 8 s, %.0f em 16 s" % [
		cena.altura_da_nave(1.0), cena.altura_da_nave(8.0), cena.altura_da_nave(16.0)
	])
	_exigir(cena.altura_da_nave(1.0) > cena.altura_da_nave(3.0) and is_zero_approx(cena.altura_da_nave(8.0))
			and cena.altura_da_nave(16.0) > 0.0,
		"na tela de título a nave desce, fica pousada e sobe de novo")
	_exigir(cena.chama_acesa(1.0) and not cena.chama_acesa(8.0) and cena.chama_acesa(15.0),
		"a chama acende na descida e na subida, e apaga com a nave pousada")
	var corpos: PackedStringArray = Menu.corpos_de_planeta()
	print("  vitrine:             %s" % ", ".join(corpos))
	_exigir(corpos.size() > 0 and menu.get_node("Vitrine").get_child_count() == 1,
		"a vitrine mostra um dos planetas que o jogo tem")

	# --- opções ---------------------------------------------------------------
	menu.abrir_configuracoes()
	await get_tree().process_frame
	var configuracoes: TelaDeConfiguracoes = menu.get_node("Configuracoes")
	_exigir(configuracoes.visible and not menu.get_node("Painel").visible,
		"OPÇÕES abre a tela de configurações no lugar do menu")
	configuracoes.fechar()
	await get_tree().process_frame
	_exigir(not configuracoes.visible
			and menu.get_viewport().gui_get_focus_owner() == menu.get_node("Painel/Opcoes/Configuracoes"),
		"fechar as configurações devolve o foco ao botão de opções")

	# --- créditos -------------------------------------------------------------
	menu.abrir_creditos()
	await get_tree().process_frame
	var creditos: TelaDeCreditos = menu.get_node("Creditos")
	_exigir(creditos.visible and "EM BREVE" in creditos.texto(), "os créditos abrem")
	creditos.fechar()
	await get_tree().process_frame

	# --- as opções ficam guardadas ---------------------------------------------
	# Num arquivo de conferência, para não mexer nas opções de quem joga.
	var manager: Node = get_node("/root/ConfiguracoesManager")
	var arquivo_do_jogador: String = manager.arquivo
	manager.arquivo = "user://configuracoes_conferencia.cfg"
	manager.atuais.volume_da_musica = 0.3
	manager.aplicar()
	manager.salvar()
	manager.atuais.volume_da_musica = 1.0
	manager.carregar()
	var barramento: int = AudioServer.get_bus_index("Musica")
	print("  volume guardado:     música %.1f, barramento a %.1f dB" % [
		manager.atuais.volume_da_musica, AudioServer.get_bus_volume_db(barramento) if barramento >= 0 else 0.0
	])
	_exigir(is_equal_approx(manager.atuais.volume_da_musica, 0.3), "o volume da música guardado volta igual ao carregar")
	_exigir(barramento >= 0 and absf(AudioServer.get_bus_volume_db(barramento) - linear_to_db(0.3)) < 0.01,
		"o volume da música vale no barramento de música")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.arquivo))
	manager.arquivo = arquivo_do_jogador
	manager.carregar()
	manager.aplicar()

	print("--- %s ---" % ("tudo certo" if _falhas == 0 else "%d critério(s) falhou(aram)" % _falhas))
	get_tree().quit(_falhas)


func _exigir(condicao: bool, descricao: String) -> void:
	print("  [%s] %s" % ["ok" if condicao else "FALHOU", descricao])
	if not condicao:
		_falhas += 1
