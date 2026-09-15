extends SceneTree

## Modelo: montou o Outpost de Arvo (tileset, saloon, personagens, sinal, região, ficha).
## Para um lugar novo, copie, troque caminhos, peças e posições, e rode:
##   godot --headless --path . --script .claude/skills/pixel-art-sprite/reference/modelos/<copia>.gd

## Monta, uma vez, as cenas do Outpost de Arvo a partir dos PNG da skill.
##   godot --headless --path <llrr> --script construir_outpost.gd

const R := "res://mundo/planetas/arvo/regioes/outpost/"
const ART := R + "art/"
const CHAO := 288

var _falhas: int = 0


func _initialize() -> void:
	var tileset: TileSet = _tileset()
	_salvar(_sinal(), "res://entities/estruturas/sinal_de_pouso/sinal_de_pouso.tscn")
	_salvar(_saloon(), "res://entities/estruturas/saloon/saloon.tscn")
	var parado_xerife: Texture2D = load("res://entities/cenario/xerife/art/xerife_parado.png")
	var anda_xerife: Texture2D = load("res://entities/cenario/xerife/art/xerife_anda.png")
	_salvar(_personagem("Xerife", {
		"parado": [parado_xerife, 4, [[0, 3.0], [1, 1.0], [2, 1.0], [0, 2.0], [3, 1.0]], 5.0],
		"anda": [anda_xerife, 6, [[0, 1.0], [1, 1.0], [2, 1.0], [3, 1.0], [4, 1.0], [5, 1.0]], 8.0],
	}, "parado"), "res://entities/cenario/xerife/xerife.tscn")
	_salvar(_personagem("DonoDoSaloon", {
		"parado": [load("res://entities/cenario/dono_do_saloon/art/dono_do_saloon_parado.png"), 4,
			[[0, 3.0], [1, 1.0], [2, 1.0], [0, 2.0], [3, 1.0]], 5.0],
	}, "parado"), "res://entities/cenario/dono_do_saloon/dono_do_saloon.tscn")
	_salvar(_personagem("Cowboy", {
		"sentado": [load("res://entities/cenario/cowboy/art/cowboy_sentado.png"), 2, [[0, 1.0], [1, 1.0]], 0.8],
	}, "sentado"), "res://entities/cenario/cowboy/cowboy.tscn")
	_salvar(_arbusto_seco(), "res://entities/cenario/arbusto_seco/arbusto_seco.tscn")
	_salvar(_regiao(tileset), R + "outpost_regiao.tscn")
	_ficha()
	print("--- %s ---" % ("tudo montado" if _falhas == 0 else "%d falha(s)" % _falhas))
	quit(_falhas)


# ------------------------------------------------------------------ ajudantes

func _por(pai: Node, filho: Node, dono: Node) -> Node:
	pai.add_child(filho)
	filho.owner = dono
	return filho


func _sprite(nome: String, textura: Texture2D, posicao: Vector2, solto: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = nome
	s.texture = textura
	s.centered = false
	s.position = posicao
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if solto:
		s.add_to_group("solto", true)
	return s


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


func _instancia(caminho: String, nome: String) -> Node:
	var no: Node = (load(caminho) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	no.name = nome
	return no


# ------------------------------------------------------------------ peças

func _tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = load(ART + "tiles.png")
	fonte.texture_region_size = Vector2i(16, 16)
	ts.add_source(fonte, 0)
	var quadrado := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	for x: int in 4:
		fonte.create_tile(Vector2i(x, 0))
		var dado: TileData = fonte.get_tile_data(Vector2i(x, 0), 0)
		dado.add_collision_polygon(0)
		dado.set_collision_polygon_points(0, 0, quadrado)
	var erro: int = ResourceSaver.save(ts, R + "outpost_tileset.tres", ResourceSaver.FLAG_CHANGE_PATH)
	if erro != OK:
		push_error("não salvei o tileset")
		_falhas += 1
	else:
		print("ok  ", R + "outpost_tileset.tres")
	return ts


func _sinal() -> Node:
	var raiz := Node2D.new()
	raiz.name = "SinalDePouso"
	raiz.set_script(load("res://entities/estruturas/sinal_de_pouso/sinal_de_pouso.gd"))
	var s := Sprite2D.new()
	s.name = "Sprite"
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.add_to_group("solto", true)
	_por(raiz, s, raiz)
	var luz := PointLight2D.new()
	luz.name = "Luz"
	luz.position = Vector2(4, 3)
	luz.texture = load("res://assets/luz_redonda.png")
	luz.texture_scale = 0.22
	luz.energy = 1.1
	_por(raiz, luz, raiz)
	return raiz


func _saloon() -> Node:
	var raiz := Node2D.new()
	raiz.name = "Saloon"
	var a := "res://entities/estruturas/saloon/art/"
	for j: int in 4:
		for i: int in 4:
			_por(raiz, _sprite("Parede%d%d" % [j, i], load(a + "parede_tabuas.png"), Vector2(16 + i * 32, j * 16 - 70), true), raiz)
	_por(raiz, _sprite("Placa", load(a + "placa.png"), Vector2(65, -68), true), raiz)
	_por(raiz, _sprite("JanelaEsquerda", load(a + "janela.png"), Vector2(28, -48), true), raiz)
	_por(raiz, _sprite("JanelaDireita", load(a + "janela.png"), Vector2(116, -48), true), raiz)
	_por(raiz, _sprite("Porta", load(a + "porta.png"), Vector2(68, -40), true), raiz)
	_por(raiz, _sprite("Barril", load(a + "barril.png"), Vector2(132, -24), true), raiz)
	_por(raiz, _sprite("Banco", load(a + "banco.png"), Vector2(98, -18), true), raiz)
	for i: int in 4:
		_por(raiz, _sprite("Poste%d" % i, load(a + "varanda_poste.png"), Vector2([8, 56, 96, 146][i], -56), true), raiz)
	for i: int in 5:
		_por(raiz, _sprite("Beiral%d" % i, load(a + "varanda_telhado.png"), Vector2(i * 32, -58), true), raiz)
	for i: int in 5:
		_por(raiz, _sprite("Calcada%d" % i, load(a + "varanda_piso.png"), Vector2(i * 32, -8), false), raiz)
	return raiz


func _personagem(nome: String, animacoes: Dictionary, inicial: String) -> Node:
	var raiz := Node2D.new()
	raiz.name = nome
	var quadros := SpriteFrames.new()
	quadros.remove_animation(&"default")
	for anim: String in animacoes:
		var spec: Array = animacoes[anim]
		var folha: Texture2D = spec[0]
		var largura: int = folha.get_width() / int(spec[1])
		quadros.add_animation(anim)
		quadros.set_animation_speed(anim, spec[3])
		quadros.set_animation_loop(anim, true)
		for par: Array in spec[2]:
			var recorte := AtlasTexture.new()
			recorte.atlas = folha
			recorte.region = Rect2(int(par[0]) * largura, 0, largura, folha.get_height())
			quadros.add_frame(anim, recorte, par[1])
	var inicio: Array = animacoes[inicial]
	var folha_inicial: Texture2D = inicio[0]
	var w: int = folha_inicial.get_width() / int(inicio[1])
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = quadros
	sprite.animation = inicial
	sprite.autoplay = inicial
	sprite.centered = false
	sprite.offset = Vector2(-w / 2, -folha_inicial.get_height())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_por(raiz, sprite, raiz)
	return raiz


func _arbusto_seco() -> Node:
	var seq: Array = []
	for k: int in 8:
		seq.append([k, 1.0])
	var raiz: Node = _personagem("ArbustoSeco", {
		"rolando": [load("res://entities/cenario/arbusto_seco/art/arbusto_seco_rolando.png"), 8, seq, 12.0],
	}, "rolando")
	raiz.set_script(load("res://entities/cenario/arbusto_seco/arbusto_seco.gd"))
	var sombra: Sprite2D = _sprite("Sombra", load("res://entities/cenario/arbusto_seco/art/sombra.png"), Vector2(-6, -2), false)
	_por(raiz, sombra, raiz)
	raiz.move_child(sombra, 0)
	return raiz


func _poligono(pai: Node, dono: Node, nome: String, cor: String, topo: float, z: int) -> void:
	var p := Polygon2D.new()
	p.name = nome
	p.color = Color(cor)
	p.z_index = z
	p.polygon = PackedVector2Array([Vector2(-60, topo), Vector2(700, topo), Vector2(700, 368), Vector2(-60, 368)])
	_por(pai, p, dono)


func _faixa(pai: Node, dono: Node, nome: String, textura: String, y: float) -> void:
	var s := _sprite(nome, load(textura), Vector2(0, y), true)
	s.z_index = -7
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, 640, 32)
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_por(pai, s, dono)


func _regiao(tileset: TileSet) -> Node:
	var raiz := Node2D.new()
	raiz.name = "OutpostRegiao"
	raiz.set_script(load("res://mundo/regiao.gd"))
	raiz.set("luz_propria", true)
	raiz.set("cor_ambiente_propria", Color.WHITE)
	raiz.set("cor_do_ceu_propria", Color("4d9be6"))

	var ambiente := CanvasModulate.new()
	ambiente.name = "Ambiente"
	ambiente.color = Color.WHITE
	_por(raiz, ambiente, raiz)

	var fundo := Node2D.new()
	fundo.name = "Fundo"
	fundo.z_index = -10
	_por(raiz, fundo, raiz)
	_poligono(fundo, raiz, "Ceu", "4d9be6", -560, -10)
	_poligono(fundo, raiz, "CeuClaro", "8fd3ff", 142, -9)
	_poligono(fundo, raiz, "Nevoa", "c7dcd0", 232, -8)
	_faixa(fundo, raiz, "TransicaoMedia", ART + "ceu_transicao_media.png", 126)
	_faixa(fundo, raiz, "TransicaoHorizonte", ART + "ceu_transicao_horizonte.png", 200)

	var nuvens := Node2D.new()
	nuvens.name = "Nuvens"
	nuvens.z_index = -6
	_por(fundo, nuvens, raiz)
	for item: Array in [["GrandeA", "nuvem_grande_a", 40, 34], ["GrandeB", "nuvem_grande_b", 96, 40], ["GrandeB2", "nuvem_grande_b", 380, 20],
			["Media", "nuvem_media", 250, 104], ["Pequena", "nuvem_pequena", 530, 128], ["Media2", "nuvem_media", 560, 66],
			["Faixa", "nuvem_faixa", 150, 180], ["Faixa2", "nuvem_faixa", 430, 190], ["Pequena2", "nuvem_pequena", 330, 160]]:
		_por(nuvens, _sprite("Nuvem" + item[0], load(ART + item[1] + ".png"), Vector2(item[2], item[3]), true), raiz)

	var longe := Node2D.new()
	longe.name = "MontanhasLonge"
	longe.z_index = -5
	_por(fundo, longe, raiz)
	var i: int = 0
	for item: Array in [["a", -20], ["b", 40], ["a", 120], ["b", 190], ["a", 290], ["b", 350], ["a", 430], ["b", 500], ["a", 580]]:
		var t: Texture2D = load(ART + "montanha_longe_%s.png" % item[0])
		_por(longe, _sprite("Longe%d" % i, t, Vector2(item[1], 250 - t.get_height()), true), raiz)
		i += 1

	var medias := Node2D.new()
	medias.name = "MontanhasMedias"
	medias.z_index = -4
	_por(fundo, medias, raiz)
	i = 0
	for item: Array in [["a", 80], ["b", 200], ["a", 360], ["b", 560]]:
		var t: Texture2D = load(ART + "montanha_media_%s.png" % item[0])
		_por(medias, _sprite("Media%d" % i, t, Vector2(item[1], CHAO + 4 - t.get_height()), true), raiz)
		i += 1

	var mesa := Node2D.new()
	mesa.name = "Mesa"
	mesa.z_index = -3
	_por(fundo, mesa, raiz)
	_por(mesa, _sprite("MesaEsquerda", load(ART + "mesa_esquerda.png"), Vector2(460, CHAO - 62), true), raiz)
	_por(mesa, _sprite("MesaDireita", load(ART + "mesa_direita.png"), Vector2(524, CHAO - 62), true), raiz)

	var cenario := Node2D.new()
	cenario.name = "Cenario"
	cenario.z_index = -6
	_por(raiz, cenario, raiz)
	var saloon: Node2D = _instancia("res://entities/estruturas/saloon/saloon.tscn", "Saloon")
	saloon.position = Vector2(12, CHAO)
	_por(cenario, saloon, raiz)
	for item: Array in [["SaguaroA", "cacto_saguaro_a", 250], ["SaguaroB", "cacto_saguaro_b", 440],
			["CactoPequeno", "cacto_pequeno", 210], ["CactoPequeno2", "cacto_pequeno", 425], ["CactoPequeno3", "cacto_pequeno", 612]]:
		var t: Texture2D = load(ART + item[1] + ".png")
		_por(cenario, _sprite(item[0], t, Vector2(item[2], CHAO - t.get_height()), false), raiz)

	var relevo := TileMapLayer.new()
	relevo.name = "Relevo"
	relevo.z_index = -3
	relevo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	relevo.tile_set = tileset
	var topos: Array[int] = [2, 2, 3, 2, 2, 2, 3, 2, 2, 3, 2, 2, 2]
	for x: int in 40:
		relevo.set_cell(Vector2i(x, 18), 0, Vector2i(topos[x % topos.size()], 0))
		for y: int in range(19, 23):
			relevo.set_cell(Vector2i(x, y), 0, Vector2i((x * 3 + y) % 2, 0))
	_por(raiz, relevo, raiz)

	var deque := Node2D.new()
	deque.name = "Deque"
	deque.z_index = -2
	_por(raiz, deque, raiz)
	_por(deque, _sprite("PontaEsquerda", load(ART + "pouso_ponta_esquerda.png"), Vector2(300, CHAO - 48), false), raiz)
	_por(deque, _sprite("Meio", load(ART + "pouso_meio.png"), Vector2(316, CHAO - 32), false), raiz)
	_por(deque, _sprite("Meio2", load(ART + "pouso_meio.png"), Vector2(348, CHAO - 32), false), raiz)
	_por(deque, _sprite("PontaDireita", load(ART + "pouso_ponta_direita.png"), Vector2(380, CHAO - 48), false), raiz)

	var ponto: Node2D = _instancia("res://entities/estruturas/ponto_de_coleta/ponto_de_coleta.tscn", "PontoDeColeta")
	ponto.position = Vector2(348, CHAO - 32)
	ponto.z_index = 1
	ponto.set("largura", 72.0)
	ponto.set("espessura", 4.0)
	_por(raiz, ponto, raiz)

	for lado: Array in [["SinalEsquerdo", 301], ["SinalDireito", 386]]:
		var sinal: Node2D = _instancia("res://entities/estruturas/sinal_de_pouso/sinal_de_pouso.tscn", lado[0])
		sinal.position = Vector2(lado[1], CHAO - 56)
		sinal.set("ponto_de_coleta", NodePath("../PontoDeColeta"))
		sinal.set("folha", load(ART + "pouso_sinal.png"))
		_por(raiz, sinal, raiz)

	var personagens := Node2D.new()
	personagens.name = "Personagens"
	personagens.z_index = -1
	_por(raiz, personagens, raiz)
	for item: Array in [["DonoDoSaloon", "res://entities/cenario/dono_do_saloon/dono_do_saloon.tscn", Vector2(68, CHAO - 8)],
			["Cowboy", "res://entities/cenario/cowboy/cowboy.tscn", Vector2(117, CHAO - 8)],
			["Xerife", "res://entities/cenario/xerife/xerife.tscn", Vector2(190, CHAO)]]:
		var p: Node2D = _instancia(item[1], item[0])
		p.position = item[2]
		_por(personagens, p, raiz)

	var arbusto: Node2D = _instancia("res://entities/cenario/arbusto_seco/arbusto_seco.tscn", "ArbustoSeco")
	arbusto.position = Vector2(90, CHAO)
	_por(raiz, arbusto, raiz)

	var campo := Area2D.new()
	campo.name = "CampoGravitacional"
	campo.collision_layer = 0
	campo.collision_mask = 2
	campo.gravity_space_override = Area2D.SPACE_OVERRIDE_REPLACE
	campo.gravity_direction = Vector2(0, 1)
	campo.gravity = 49.03
	campo.linear_damp_space_override = Area2D.SPACE_OVERRIDE_REPLACE
	campo.linear_damp = 0.25
	_por(raiz, campo, raiz)
	var forma := CollisionShape2D.new()
	forma.name = "Forma"
	forma.position = Vector2(320, 180)
	var caixa := RectangleShape2D.new()
	caixa.size = Vector2(760, 560)
	forma.shape = caixa
	_por(campo, forma, raiz)
	return raiz


func _ficha() -> void:
	var ficha := FichaDeRegiao.new()
	ficha.nome = "Outpost"
	ficha.assunto = "Posto de fronteira no deserto: saloon, xerife e um deque sobre palafitas onde se pega e entrega contrato."
	ficha.cena = load(R + "outpost_regiao.tscn")
	ficha.onde_a_nave_aparece = Vector2(348, 150)
	ficha.de_onde_a_nave_vem = Vector2(348, -110)
	# O deque sobre palafitas é estreito: aperta mais a deriva que a descida.
	var pouso := EspecificacaoDePouso.new()
	pouso.vertical_maxima = 2.5
	pouso.horizontal_maxima = 1.0
	pouso.inclinacao_maxima = 8.0
	pouso.giro_maximo = 10.0
	ficha.pouso = pouso
	ficha.ponto_na_carta = Vector2i(236, 121)
	var erro: int = ResourceSaver.save(ficha, R + "outpost.tres", ResourceSaver.FLAG_CHANGE_PATH)
	if erro != OK:
		push_error("não salvei a ficha")
		_falhas += 1
		return
	print("ok  ", R + "outpost.tres")
	var arvo: Planeta = load("res://mundo/planetas/arvo/arvo.tres")
	var ja_tem: bool = false
	for r: Resource in arvo.regioes:
		if r != null and r.resource_path == R + "outpost.tres":
			ja_tem = true
	if not ja_tem:
		arvo.regioes.append(load(R + "outpost.tres"))
	erro = ResourceSaver.save(arvo, "res://mundo/planetas/arvo/arvo.tres")
	if erro != OK:
		push_error("não salvei arvo.tres")
		_falhas += 1
	else:
		print("ok  res://mundo/planetas/arvo/arvo.tres (%d regiões)" % arvo.regioes.size())
