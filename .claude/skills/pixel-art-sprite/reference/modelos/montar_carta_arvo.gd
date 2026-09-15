extends SceneTree

## Monta a carta de superfície de Arvo: o tileset das três camadas e a cena com os
## TileMapLayer pintados a partir de uma grade de cantos.
##   python3 .claude/skills/pixel-art-sprite/scripts/montar_arte.py mundo/planetas/arvo
##   godot --headless --path . --import
##   godot --headless --path . --script <este arquivo>
##
## Cada canto da grade é 0 mar, 1 mata, 2 platô ou 3 deserto. Platô e deserto são
## camadas por cima da mata, transparentes fora da mancha, e por isso não podem
## encostar no mar nem um no outro: o saneamento rebaixa para mata o canto que
## encostaria. Depois de montada, a carta se edita no editor de TileMap do Godot,
## pintando com os terrenos do tileset.

const A := "res://mundo/planetas/arvo/"
const ART := A + "art/"
const MAR := 0
const MATA := 1
const PLATO := 2
const DESERTO := 3

const CANTOS: Array[String] = [
	"00000000000000000000000",
	"00011100000001110000110",
	"00111110000111111001110",
	"01112211111112211111100",
	"01122221111111221111110",
	"00112211101111111111110",
	"00011111000111333311100",
	"00111221101113333331100",
	"01112222111113333311000",
	"01111221111111333111100",
	"00111111110111111122100",
	"00011100000011111111110",
	"00000000000000000000000",
]

var _falhas: int = 0


func _initialize() -> void:
	var cantos: Array = _sanear(CANTOS)
	for linha: Array in cantos:
		print("  ", "".join(linha.map(func(v: int) -> String: return str(v))))
	var ts: TileSet = _tileset()
	var raiz := Node2D.new()
	raiz.name = "CartaDeArvo"
	raiz.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var camadas: Dictionary = {}
	for nome: String in ["Base", "Deserto", "Plato"]:
		var camada := TileMapLayer.new()
		camada.name = nome
		camada.tile_set = ts
		raiz.add_child(camada)
		camada.owner = raiz
		camadas[nome] = camada
	var largura: int = cantos[0].size() - 1
	var altura: int = cantos.size() - 1
	for ty: int in altura:
		for tx: int in largura:
			var celula := Vector2i(tx, ty)
			(camadas["Base"] as TileMapLayer).set_cell(celula, 0, Vector2i(_config(cantos, tx, ty, MATA, true), 0))
			var k_deserto: int = _config(cantos, tx, ty, DESERTO, false)
			if k_deserto > 0:
				(camadas["Deserto"] as TileMapLayer).set_cell(celula, 1, Vector2i(k_deserto - 1, 0))
			var k_plato: int = _config(cantos, tx, ty, PLATO, false)
			if k_plato > 0:
				(camadas["Plato"] as TileMapLayer).set_cell(celula, 2, Vector2i(k_plato - 1, 0))
	print("  carta de %dx%d tiles (%dx%d px)" % [largura, altura, largura * 16, altura * 16])
	_salvar(raiz, A + "arvo_carta.tscn")
	quit(_falhas)


## Os quatro cantos de um tile viram um número: TL 1, TR 2, BL 4, BR 8. É o
## mesmo número do nome dos .pix e a posição no atlas.
func _config(cantos: Array, tx: int, ty: int, alvo: int, ou_acima: bool) -> int:
	var k: int = 0
	var pesos: Array[Vector3i] = [Vector3i(0, 0, 1), Vector3i(1, 0, 2), Vector3i(0, 1, 4), Vector3i(1, 1, 8)]
	for p: Vector3i in pesos:
		var v: int = cantos[ty + p.y][tx + p.x]
		if (v >= alvo) if ou_acima else (v == alvo):
			k |= p.z
	return k


func _sanear(origem: Array[String]) -> Array:
	var g: Array = []
	for linha: String in origem:
		var numeros: Array[int] = []
		for ch: String in linha:
			numeros.append(int(ch))
		g.append(numeros)
	var mudou: bool = true
	while mudou:
		mudou = false
		for y: int in g.size():
			for x: int in g[y].size():
				var v: int = g[y][x]
				if v < PLATO:
					continue
				for dy: int in [-1, 0, 1]:
					for dx: int in [-1, 0, 1]:
						var yy: int = y + dy
						var xx: int = x + dx
						if yy < 0 or yy >= g.size() or xx < 0 or xx >= g[y].size():
							continue
						var w: int = g[yy][xx]
						if g[y][x] == v and (w == MAR or (w >= PLATO and w != v)):
							g[y][x] = MATA
							mudou = true
							print("  saneado: canto (%d, %d) virou mata" % [x, y])
	return g


func _tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var partes: Array = [["carta.png", 16], ["deserto.png", 15], ["plato.png", 15]]
	for i: int in partes.size():
		var fonte := TileSetAtlasSource.new()
		fonte.texture = load(ART + partes[i][0])
		fonte.texture_region_size = Vector2i(16, 16)
		ts.add_source(fonte, i)
		for x: int in partes[i][1]:
			fonte.create_tile(Vector2i(x, 0))
	_terrenos(ts)
	var erro: int = ResourceSaver.save(ts, A + "arvo_carta_tileset.tres", ResourceSaver.FLAG_CHANGE_PATH)
	if erro != OK:
		push_error("não salvei o tileset (erro %d)" % erro)
		_falhas += 1
	else:
		print("ok  ", A + "arvo_carta_tileset.tres")
		# Recarregado do disco, a cena guarda uma referência ao arquivo em vez de
		# uma cópia embutida do tileset.
		ts = load(A + "arvo_carta_tileset.tres")
	return ts


## Terrenos de cantos, para a carta se editar no Godot pintando em vez de escolher
## tile: a base casa mar com mata, e deserto e platô casam com o vazio.
func _terrenos(ts: TileSet) -> void:
	ts.add_terrain_set()
	ts.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	ts.add_terrain(0)
	ts.set_terrain_name(0, 0, "mar")
	ts.set_terrain_color(0, 0, Color("0b5e65"))
	ts.add_terrain(0)
	ts.set_terrain_name(0, 1, "mata")
	ts.set_terrain_color(0, 1, Color("239063"))
	var extras: Array = [[1, "deserto", "cd683d"], [2, "plato", "91db69"]]
	for extra: Array in extras:
		ts.add_terrain_set()
		ts.set_terrain_set_mode(extra[0], TileSet.TERRAIN_MODE_MATCH_CORNERS)
		ts.add_terrain(extra[0])
		ts.set_terrain_name(extra[0], 0, extra[1])
		ts.set_terrain_color(extra[0], 0, Color(extra[2]))
	var vizinhos: Array[int] = [
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	]
	for i: int in 3:
		var fonte := ts.get_source(i) as TileSetAtlasSource
		for x: int in fonte.get_tiles_count():
			var k: int = x if i == 0 else x + 1
			var dado: TileData = fonte.get_tile_data(Vector2i(x, 0), 0)
			dado.terrain_set = i
			var bits: Array[int] = [k & 1, (k >> 1) & 1, (k >> 2) & 1, (k >> 3) & 1]
			if i == 0:
				dado.terrain = 1 if bits.count(1) >= 2 else 0
				for b: int in 4:
					dado.set_terrain_peering_bit(vizinhos[b], bits[b])
			else:
				dado.terrain = 0
				for b: int in 4:
					dado.set_terrain_peering_bit(vizinhos[b], 0 if bits[b] == 1 else -1)


func _salvar(raiz: Node, caminho: String) -> void:
	var pacote := PackedScene.new()
	var erro: int = pacote.pack(raiz)
	if erro == OK:
		erro = ResourceSaver.save(pacote, caminho)
	if erro != OK:
		push_error("não salvei %s (erro %d)" % [caminho, erro])
		_falhas += 1
	else:
		print("ok  ", caminho)
	raiz.free()
