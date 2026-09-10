extends Node
## Sobe uma cena, espera alguns quadros e salva um PNG da tela.
##
## Existe para o agente conferir visualmente o que programou, do mesmo jeito
## que confere um sprite. Não é código de jogo e não vai para o build.
##
## Uso:
##   godot --path . --scene res://tools/screenshot.tscn -- \
##       --scene res://stages/<fase>/<fase>.tscn --out shot.png [--frames 60] \
##       [--acao pausa]
##
## Roda como cena, não como `--script`: script passado em `--script` é
## compilado antes de os autoloads existirem, e a fase que ele carrega usa um.
##
## `--acao` dispara uma ação de input na metade dos quadros, antes de
## capturar. É o jeito de fotografar o que só existe depois de uma tecla —
## menu de pausa, tela aberta, propulsor ligado.

var _cena: String = ""
var _saida: String = "shot.png"
var _acao: String = ""
var _quadros: int = 60
var _contador: int = 0
var _erro: bool = false


func _ready() -> void:
	# Sem isto, `--acao pausa` trava: a cena pausa a árvore, este nó para de
	# processar junto e o contador de quadros nunca chega ao fim.
	process_mode = Node.PROCESS_MODE_ALWAYS
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
			"--acao":
				i += 1
				if i < args.size():
					_acao = args[i]
		i += 1

	if _cena.is_empty():
		push_error("screenshot: faltou --scene")
		_erro = true
		get_tree().quit(1)
		return

	if not ResourceLoader.exists(_cena):
		push_error("screenshot: cena não encontrada: %s" % _cena)
		_erro = true
		get_tree().quit(1)
		return

	var packed: PackedScene = load(_cena)
	if packed == null:
		push_error("screenshot: falha ao carregar %s" % _cena)
		_erro = true
		get_tree().quit(1)
		return

	# Diferido: em `_ready` a raiz ainda está montando os filhos dela.
	get_tree().root.add_child.call_deferred(packed.instantiate())
	print("screenshot: cena %s, %d quadros" % [_cena, _quadros])


func _process(_delta: float) -> void:
	if _erro:
		return

	_contador += 1
	if not _acao.is_empty() and _contador == int(_quadros / 2.0):
		var evento := InputEventAction.new()
		evento.action = _acao
		evento.pressed = true
		Input.parse_input_event(evento)
		print("screenshot: disparou a ação %s" % _acao)
	if _contador < _quadros:
		return

	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		push_error("screenshot: não consegui capturar a tela")
		get_tree().quit(1)
		return

	var abs_path: String = ProjectSettings.globalize_path(_saida) if _saida.begins_with("res://") else _saida
	var err: int = img.save_png(abs_path)
	if err != OK:
		push_error("screenshot: falha ao salvar %s (erro %d)" % [abs_path, err])
		get_tree().quit(1)
		return

	print("screenshot: salvo em %s (%dx%d)" % [abs_path, img.get_width(), img.get_height()])
	get_tree().quit(0)
