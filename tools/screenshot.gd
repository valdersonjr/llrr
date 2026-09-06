extends SceneTree
## Sobe uma cena, espera alguns quadros e salva um PNG da tela.
##
## Existe para o agente conferir visualmente o que programou, do mesmo jeito
## que confere um sprite. Não é código de jogo e não vai para o build.
##
## Uso:
##   godot --path . --script res://tools/screenshot.gd -- \
##       --scene res://stages/<fase>/<fase>.tscn --out shot.png [--frames 60]

var _cena: String = ""
var _saida: String = "shot.png"
var _quadros: int = 60
var _contador: int = 0
var _erro: bool = false


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var i: int = 0
	while i < args.size():
		match args[i]:
			"--scene":
				i += 1
				if i < args.size():
					_cena = args[i]
			"--out":
				i += 1
				if i < args.size():
					_saida = args[i]
			"--frames":
				i += 1
				if i < args.size():
					_quadros = int(args[i])
		i += 1

	if _cena.is_empty():
		push_error("screenshot: faltou --scene")
		_erro = true
		quit(1)
		return

	if not ResourceLoader.exists(_cena):
		push_error("screenshot: cena não encontrada: %s" % _cena)
		_erro = true
		quit(1)
		return

	var packed: PackedScene = load(_cena)
	if packed == null:
		push_error("screenshot: falha ao carregar %s" % _cena)
		_erro = true
		quit(1)
		return

	root.add_child(packed.instantiate())
	print("screenshot: cena %s, %d quadros" % [_cena, _quadros])


func _process(_delta: float) -> bool:
	if _erro:
		return true

	_contador += 1
	if _contador < _quadros:
		return false

	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("screenshot: não consegui capturar a tela")
		quit(1)
		return true

	var abs_path: String = ProjectSettings.globalize_path(_saida) if _saida.begins_with("res://") else _saida
	var err: int = img.save_png(abs_path)
	if err != OK:
		push_error("screenshot: falha ao salvar %s (erro %d)" % [abs_path, err])
		quit(1)
		return true

	print("screenshot: salvo em %s (%dx%d)" % [abs_path, img.get_width(), img.get_height()])
	quit(0)
	return true
