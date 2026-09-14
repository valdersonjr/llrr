extends Node

## Ferramenta de dev: confere se cada peça de cenário está de fato apoiada no chão.
##
##   godot --headless --path . --scene res://tools/cenario_check.tscn -- \
##       --regiao res://mundo/planetas/arvo/regioes/outpost/outpost_regiao.tscn
##
## Ela desce um raio a partir da base de cada sprite e diz quem está flutuando e
## quem está enterrado. Nasceu de um bug de verdade: uma pedra plantada dentro de
## um platô, com a base no nível do vale, que a olho nu parecia colada na parede.
##
## Sprite que é solto de propósito — fundo, copa cortada pelo quadro, primeiro
## plano — entra no grupo `solto` e é pulado.

const FOLGA: float = 3.0
const ALCANCE: float = 400.0
const TERRENO: int = 1

var _falhas: int = 0


func _ready() -> void:
	var caminho: String = _argumento("--regiao")
	if caminho.is_empty():
		push_error("cenario_check: falta --regiao res://<caminho>.tscn")
		get_tree().quit(1)
		return

	var regiao: Node2D = load(caminho).instantiate()
	add_child(regiao)
	# A colisão do TileMapLayer só existe no espaço depois de alguns passos.
	# Conferir cedo demais faz a ferramenta acusar a região inteira.
	for _i: int in 4:
		await get_tree().physics_frame

	print("--- conferência de cenário: %s ---" % caminho.get_file())
	var espaco: PhysicsDirectSpaceState2D = regiao.get_world_2d().direct_space_state
	# O que importa é a distância de cada peça até o chão do relevo. Se um dia
	# entrar obstáculo sólido, os corpos dele vão nesta lista, para uma peça não
	# ser conferida contra outra.
	var ignorar: Array[RID] = []

	for no: Node in _sprites(regiao):
		if no.is_in_group("solto"):
			continue
		_conferir(no as Sprite2D, espaco, ignorar)

	print("--- %s ---" % ("tudo no lugar" if _falhas == 0 else "%d peça(s) fora do lugar" % _falhas))
	get_tree().quit(_falhas)


func _conferir(sp: Sprite2D, espaco: PhysicsDirectSpaceState2D, ignorar: Array[RID]) -> void:
	# Folha de animação: o que vale é o quadro, não a folha inteira.
	var tamanho: Vector2 = sp.texture.get_size() / Vector2(maxi(sp.hframes, 1), maxi(sp.vframes, 1))
	var canto: Vector2 = sp.global_position + sp.offset
	if sp.centered:
		canto -= tamanho * 0.5 * sp.global_scale
	var base: Vector2 = canto + Vector2(tamanho.x * 0.5, tamanho.y) * sp.global_scale

	# PhysicsPointQueryParameters2D não tem create() estático, ao contrário do de raio
	var ponto := PhysicsPointQueryParameters2D.new()
	ponto.position = base - Vector2(0.0, 4.0)
	ponto.collision_mask = TERRENO
	ponto.collide_with_areas = false
	ponto.exclude = ignorar
	var dentro: Array[Dictionary] = espaco.intersect_point(ponto)
	if not dentro.is_empty():
		_dizer(false, "%s está enterrado no terreno" % sp.name)
		return

	var raio := PhysicsRayQueryParameters2D.create(
		base - Vector2(0.0, 6.0), base + Vector2(0.0, ALCANCE), TERRENO
	)
	raio.exclude = ignorar
	var achou: Dictionary = espaco.intersect_ray(raio)
	if achou.is_empty():
		_dizer(false, "%s não tem chão nenhum embaixo" % sp.name)
		return
	var vao: float = (achou["position"] as Vector2).y - base.y
	_dizer(absf(vao) <= FOLGA, "%s apoiado, vão de %.0f px" % [sp.name, vao])


func _sprites(raiz: Node) -> Array[Node]:
	var saida: Array[Node] = []
	for no: Node in _todos(raiz):
		if no is Sprite2D and (no as Sprite2D).texture != null:
			saida.append(no)
	return saida


func _todos(raiz: Node) -> Array[Node]:
	var saida: Array[Node] = [raiz]
	for filho: Node in raiz.get_children():
		saida.append_array(_todos(filho))
	return saida


func _dizer(certo: bool, texto: String) -> void:
	print("  [%s] %s" % ["ok" if certo else "FORA", texto])
	if not certo:
		_falhas += 1


func _argumento(chave: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in args.size():
		if args[i] == chave and i + 1 < args.size():
			return args[i + 1]
	return ""
