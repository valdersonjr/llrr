extends SceneTree

## Monta o corpo de Arvo visto do espaço: o tileset das peças de 48 e a cena
## `arvo_corpo.tscn` com as peças centradas num `TileMapLayer`.
##   python3 .claude/skills/pixel-art-sprite/scripts/montar_arte.py mundo/planetas/arvo
##   godot --headless --path . --import
##   godot --headless --path . --script .claude/skills/pixel-art-sprite/reference/modelos/montar_corpo_arvo.gd
##
## O corpo é pixel art em pixel de tela. A câmera do espaço fica em
## `zoom_no_espaco`, então `Arte` recebe escala `1 / zoom_no_espaco`: cada pixel do
## desenho ocupa exatamente um pixel da tela.

const A := "res://mundo/planetas/arvo/"
const FONTE := A + "art/fonte/corpo/"
const PECA: int = 48
const LADO: int = 6

var _falhas: int = 0


func _initialize() -> void:
	# A tira `corpo.png` segue a ordem dos números dos .pix, e o número diz a casa
	# da peça na grade: linha vezes LADO mais coluna.
	var numeros: Array[int] = []
	for arquivo: String in DirAccess.get_files_at(FONTE):
		if arquivo.ends_with(".pix"):
			numeros.append(int(arquivo.get_slice("_", 0)))
	numeros.sort()
	print("  %d peças" % numeros.size())

	var camera := CameraDoSistema.new()
	var zoom: float = camera.zoom_no_espaco
	camera.free()

	var ts := TileSet.new()
	ts.tile_size = Vector2i(PECA, PECA)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = load(A + "art/corpo.png")
	fonte.texture_region_size = Vector2i(PECA, PECA)
	ts.add_source(fonte, 0)
	for i: int in numeros.size():
		fonte.create_tile(Vector2i(i, 0))
	var erro: int = ResourceSaver.save(ts, A + "arvo_corpo_tileset.tres", ResourceSaver.FLAG_CHANGE_PATH)
	if erro != OK:
		push_error("não salvei o tileset (erro %d)" % erro)
		_falhas += 1
	else:
		# Recarregado do disco, a cena guarda uma referência ao arquivo em vez de
		# uma cópia embutida do tileset.
		ts = load(A + "arvo_corpo_tileset.tres")

	var raiz := Node2D.new()
	raiz.name = "ArvoCorpo"
	raiz.add_to_group("planetas", true)
	raiz.set_script(load("res://mundo/corpo_no_espaco.gd"))
	raiz.set("planeta", load(A + "arvo.tres"))

	var arte := Node2D.new()
	arte.name = "Arte"
	arte.z_index = -50
	arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arte.scale = Vector2.ONE / zoom
	raiz.add_child(arte)
	arte.owner = raiz

	var pecas := TileMapLayer.new()
	pecas.name = "Pecas"
	pecas.tile_set = ts
	pecas.position = -Vector2(PECA * LADO, PECA * LADO) * 0.5
	for i: int in numeros.size():
		var k: int = numeros[i]
		pecas.set_cell(Vector2i(k % LADO, floori(k / float(LADO))), 0, Vector2i(i, 0))
	arte.add_child(pecas)
	pecas.owner = raiz

	var pacote := PackedScene.new()
	erro = pacote.pack(raiz)
	if erro == OK:
		erro = ResourceSaver.save(pacote, A + "arvo_corpo.tscn")
	if erro != OK:
		push_error("não salvei a cena (erro %d)" % erro)
		_falhas += 1
	else:
		print("ok  %sarvo_corpo.tscn  escala %.4f (zoom %.2f)" % [A, arte.scale.x, zoom])
	raiz.free()
	quit(_falhas)
