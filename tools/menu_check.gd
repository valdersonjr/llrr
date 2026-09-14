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
## foco assim que a tela abre, todas alcançáveis pelo teclado, e a música tocando
## em laço. A música é só do menu, e "só do menu" é fácil de quebrar sem ninguém
## perceber: basta alguém mover o nó para uma cena que não morre na troca.

var _falhas: int = 0


func _ready() -> void:
	var menu: Menu = load("res://ui/menu/menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame

	var opcoes: Array[Node] = menu.get_node("Opcoes").get_children()
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
	print("  música:              %s, autoplay %s, laço %s" % [
		"nenhuma" if musica.stream == null else musica.stream.resource_path.get_file(),
		"sim" if musica.autoplay else "não", "sim" if em_laco else "não"
	])
	_exigir(musica.stream != null, "o menu tem música")
	_exigir(musica.autoplay, "a música começa sozinha ao abrir a tela")
	_exigir(em_laco, "a música do menu toca em laço, e não uma vez só")
	_exigir(musica.playing, "a música está tocando quando a tela está de pé")

	print("  jogar abre:          %s" % Menu.JOGO)
	_exigir(ResourceLoader.exists(Menu.JOGO), "a cena que o menu abre existe")
	var jogo: PackedScene = load(Menu.JOGO)
	_exigir(jogo != null and jogo.can_instantiate(), "a cena que o menu abre carrega e monta")

	print("--- %s ---" % ("tudo certo" if _falhas == 0 else "%d critério(s) falhou(aram)" % _falhas))
	get_tree().quit(_falhas)


func _exigir(condicao: bool, descricao: String) -> void:
	print("  [%s] %s" % ["ok" if condicao else "FALHOU", descricao])
	if not condicao:
		_falhas += 1
