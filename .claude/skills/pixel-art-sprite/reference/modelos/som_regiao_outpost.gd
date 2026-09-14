extends SceneTree

## Modelo: pôs entrada e música em laço numa região e conferiu o encadeamento.

## Põe a música do Outpost na cena da região e confere o encadeamento.
##   godot --headless --path <llrr> --script som_outpost.gd

const CENA := "res://mundo/planetas/arvo/regioes/outpost/outpost_regiao.tscn"
const SOM := "res://mundo/planetas/arvo/regioes/outpost/sound/"


func _initialize() -> void:
	var raiz: Node = (load(CENA) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var velho: Node = raiz.get_node_or_null("Som")
	if velho != null:
		raiz.remove_child(velho)
		velho.free()

	var som := Node.new()
	som.name = "Som"
	raiz.add_child(som)
	som.owner = raiz

	var entrada := AudioStreamPlayer.new()
	entrada.name = "Entrada"
	entrada.stream = load(SOM + "entrada.mp3")
	entrada.volume_db = -8.0
	entrada.autoplay = true
	som.add_child(entrada)
	entrada.owner = raiz

	var musica := AudioStreamPlayer.new()
	musica.name = "Musica"
	musica.stream = load(SOM + "musica.mp3")
	musica.volume_db = -8.0
	som.add_child(musica)
	musica.owner = raiz

	entrada.finished.connect(musica.play, CONNECT_PERSIST)

	var pacote := PackedScene.new()
	var erro: int = pacote.pack(raiz)
	if erro == OK:
		erro = ResourceSaver.save(pacote, CENA)
	raiz.free()
	if erro != OK:
		push_error("não salvei a cena (erro %d)" % erro)
		quit(1)
		return
	print("ok  música posta em ", CENA)
	await _conferir()


func _conferir() -> void:
	var regiao: Node = (ResourceLoader.load(CENA, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	root.add_child(regiao)
	for _i: int in 3:
		await process_frame
	var entrada: AudioStreamPlayer = regiao.get_node("Som/Entrada")
	var musica: AudioStreamPlayer = regiao.get_node("Som/Musica")
	var falhas: int = 0
	falhas += _exigir(entrada.playing, "a entrada começa sozinha ao entrar na região")
	falhas += _exigir(entrada.stream.get("loop") == false, "a entrada toca uma vez só")
	falhas += _exigir(not musica.playing, "a música do lugar espera a entrada acabar")
	falhas += _exigir(musica.stream.get("loop") == true, "a música do lugar toca em laço")
	entrada.stop()
	entrada.finished.emit()
	await process_frame
	falhas += _exigir(musica.playing, "quando a entrada acaba, a música começa")
	regiao.free()
	print("--- %s ---" % ("tudo certo" if falhas == 0 else "%d falha(s)" % falhas))
	quit(falhas)


func _exigir(condicao: bool, frase: String) -> int:
	print("  [%s] %s" % ["ok" if condicao else "FALHA", frase])
	return 0 if condicao else 1
