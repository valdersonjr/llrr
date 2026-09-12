extends Node

## Ferramenta de dev: sobe uma cena, espera ela assentar e salva um PNG.
## Não entra no build. Existe porque conferir enquadramento e leitura de longe
## pedindo para alguém abrir o editor não escala.
##
##   godot --path . --scene res://tools/foto.tscn -- \
##       --cena res://mundo/sistema/sistema.tscn --saida foto.png [--quadros 150]
##
## `--olhar x,y` planta uma câmera própria na posição pedida, para fotografar uma
## região sozinha, sem nave. `--zoom` acompanha. `--soltar x,y` recoloca a nave,
## quando a cena tem uma, para fotografar um pouso sem pilotar até ele.

var _cena: String = ""
var _saida: String = "foto.png"
var _quadros: int = 150
var _olhar: Vector2 = Vector2.INF
var _soltar: Vector2 = Vector2.INF
var _zoom: float = 1.0


func _ready() -> void:
	_ler_argumentos()
	if _cena.is_empty():
		push_error("foto: falta --cena res://<caminho>.tscn")
		get_tree().quit(1)
		return

	var embalada: PackedScene = load(_cena)
	if embalada == null:
		push_error("foto: não consegui carregar " + _cena)
		get_tree().quit(1)
		return
	add_child(embalada.instantiate())

	if _soltar != Vector2.INF:
		var nave: Node = get_node_or_null("%Nave")
		if nave == null:
			nave = find_child("Nave", true, false)
		if nave is Nave:
			# Dois passos de física antes de soltar, não um. A fronteira de um
			# corpo só reporta a nave depois da primeira varredura, e soltar
			# antes disso a tira de dentro sem que a troca de vista chegue a ser
			# avisada: a cena ficaria na superfície com a nave no espaço.
			await get_tree().physics_frame
			await get_tree().physics_frame
			(nave as Nave).reposicionar(_soltar)

	if _olhar != Vector2.INF:
		var camera := Camera2D.new()
		camera.position = _olhar
		camera.zoom = Vector2(_zoom, _zoom)
		add_child(camera)
		camera.make_current()

	await _esperar(_quadros)
	await RenderingServer.frame_post_draw

	var imagem: Image = get_viewport().get_texture().get_image()
	var erro: int = imagem.save_png(_saida)
	if erro == OK:
		print("foto: %s  %dx%d" % [_saida, imagem.get_width(), imagem.get_height()])
	else:
		push_error("foto: falhei ao gravar " + _saida)
	get_tree().quit(0 if erro == OK else 1)


func _esperar(quadros: int) -> void:
	for _i: int in quadros:
		await get_tree().physics_frame


func _ler_argumentos() -> void:
	var argumentos: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = 0
	while i < argumentos.size():
		var chave: String = argumentos[i]
		var valor: String = argumentos[i + 1] if i + 1 < argumentos.size() else ""
		match chave:
			"--cena": _cena = valor
			"--saida": _saida = valor
			"--quadros": _quadros = valor.to_int()
			"--zoom": _zoom = valor.to_float()
			"--soltar":
				var p_s: PackedStringArray = valor.split(",")
				if p_s.size() == 2:
					_soltar = Vector2(p_s[0].to_float(), p_s[1].to_float())
			"--olhar":
				var partes: PackedStringArray = valor.split(",")
				if partes.size() == 2:
					_olhar = Vector2(partes[0].to_float(), partes[1].to_float())
		i += 2
