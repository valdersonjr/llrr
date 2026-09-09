extends Node2D
## Região de teste de pouso — o protótipo de voo do jogo.
##
## Existe para responder a pergunta em aberto da seção 18 do conceito ("qual
## sensação de voo o jogo quer"), que só se responde voando. Três plataformas
## de 96, 64 e 32px contra uma nave com 26px de vão entre os pés: a largura é
## a dificuldade. O Depósito Norte, o mais fácil, é o único com carga
## esperando — embarcar as 6 t e levá-las para o Pilar Sul é "aprender a
## pousar com carga" (seção 3.2), porque a mesma nave pesa 19 t no caminho de
## volta e acelera um terço menos.
##
## ESC pausa e lista os controles, R reinicia.
##
## Os textos daqui são de ferramenta de desenvolvimento, não conteúdo — por
## isso não passam por `localization/`.

## Céu em gradiente, não cor chapada: profundidade é metade do que separa
## pixel art moderna de pixel art de jogo antigo.
const CEU_TOPO := Color("070912")
const CEU_MEIO := Color("141a2e")
const CEU_BASE := Color("2a3350")
const COR_ESTRELA := Color(0.87, 0.89, 0.93)
const PEDRA_PEQUENA := preload("res://stages/teste_pouso/art/pedra_pequena.png")
const PEDRA_GRANDE := preload("res://stages/teste_pouso/art/pedra_grande.png")
const ESTRELAS := 110
const SEMENTE_DO_CEU := 20260906

## Condição física da região. A nave não decide a própria gravidade.
@export var gravidade_local: float = 40.0
## Linha da superfície, da esquerda para a direita. Terreno visível e colisão
## saem daqui — um lugar só para editar o relevo.
@export var perfil: PackedVector2Array = PackedVector2Array()
@export var tamanho_do_mundo := Vector2(768.0, 470.0)
## Cristas de fundo. Contraste baixo é o que as coloca longe — não é preguiça,
## é profundidade: sem elas o horizonte é uma linha só e a região não tem
## tamanho.
@export var serra_distante: PackedVector2Array = PackedVector2Array()
@export var serra_media: PackedVector2Array = PackedVector2Array()
## Posições em x onde cair pedra solta. O y sai do próprio perfil.
@export var pedras: PackedFloat32Array = PackedFloat32Array()

@onready var _nave: Nave = $UtilitarioLeve
@onready var _camera: CameraSeguidora = $Camera
@onready var _hud: Hud = $Hud
@onready var _pausa: Pausa = $Pausa
@onready var _colisao_terreno: CollisionPolygon2D = $Terreno/Colisao
@onready var _visual_terreno: Polygon2D = $Terreno/Visual
@onready var _crosta: Line2D = $Terreno/Crosta
@onready var _serra_distante: Polygon2D = $SerraDistante
@onready var _serra_media: Polygon2D = $SerraMedia
@onready var _pedras: Node2D = $Pedras


func _ready() -> void:
	_montar_terreno()
	_nave.gravidade = gravidade_local
	_nave.pousou.connect(_ao_pousar)
	_nave.decolou.connect(_ao_decolar)
	_nave.impacto.connect(_ao_impactar)
	_nave.destruida.connect(_ao_destruir)
	_camera.alvo = _nave
	_hud.acompanhar(_nave)
	_pausa.acompanhar(_nave)
	_pausa.pediu_reinicio.connect(_reiniciar)
	queue_redraw()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("operar_carga"):
		_operar_carga()


func _reiniciar() -> void:
	# Sem despausar antes, a cena recarregada nasceria com a árvore parada.
	get_tree().paused = false
	get_tree().reload_current_scene()


## Uma tecla só resolve embarque e desembarque: com o porão cheio a nave
## descarrega, com ele vazio embarca o que couber.
func _operar_carga() -> void:
	if _nave.estado != Nave.Estado.POUSADA:
		_hud.avisar("carga só com a nave pousada", Hud.COR_ATENCAO)
		return
	var plataforma := _nave.plataforma_sob_a_nave() as PlataformaDePouso
	if plataforma == null:
		_hud.avisar("não há plataforma sob as duas pernas", Hud.COR_ATENCAO)
		return
	var movido := plataforma.transferir(_nave)
	if is_zero_approx(movido):
		_hud.avisar("%s não tem carga esperando" % plataforma.como_se_chama(), Hud.COR_ATENCAO)
	elif movido > 0.0:
		_hud.avisar("embarcou %.1f t em %s" % [movido, plataforma.como_se_chama()], Hud.COR_BOM)
	else:
		_hud.avisar("descarregou %.1f t em %s" % [-movido, plataforma.como_se_chama()], Hud.COR_BOM)


## O céu é desenhado pelo próprio nó da fase: `_draw()` do pai roda antes dos
## filhos, então fica atrás de tudo sem precisar de nó nem de z-index.
func _draw() -> void:
	var l := tamanho_do_mundo.x
	var h := tamanho_do_mundo.y
	var meio := h * 0.55
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(l, 0), Vector2(l, meio), Vector2(0, meio)]),
		PackedColorArray([CEU_TOPO, CEU_TOPO, CEU_MEIO, CEU_MEIO]))
	draw_polygon(
		PackedVector2Array([Vector2(0, meio), Vector2(l, meio), Vector2(l, h), Vector2(0, h)]),
		PackedColorArray([CEU_MEIO, CEU_MEIO, CEU_BASE, CEU_BASE]))
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE_DO_CEU
	for _i in ESTRELAS:
		var p := Vector2(rng.randf() * tamanho_do_mundo.x, rng.randf() * tamanho_do_mundo.y * 0.7)
		var brilho := rng.randf_range(0.3, 1.0)
		draw_rect(Rect2(p.floor(), Vector2.ONE), Color(COR_ESTRELA, brilho))


func _montar_terreno() -> void:
	if perfil.size() < 2:
		push_error("teste_pouso: perfil do terreno vazio")
		return
	var poligono := _com_base(perfil)
	_colisao_terreno.polygon = poligono
	_visual_terreno.polygon = poligono
	# A crosta é uma Line2D com textura em TILE, não uma borda de 1px: assim ela
	# acompanha a inclinação e o chão passa a ter uma face que o sol pega.
	_crosta.points = perfil
	_serra_distante.polygon = _com_base(serra_distante)
	_serra_media.polygon = _com_base(serra_media)
	_espalhar_pedras()


func _com_base(linha: PackedVector2Array) -> PackedVector2Array:
	if linha.size() < 2:
		return PackedVector2Array()
	var poligono := linha.duplicate()
	poligono.append(Vector2(linha[-1].x, tamanho_do_mundo.y))
	poligono.append(Vector2(linha[0].x, tamanho_do_mundo.y))
	return poligono


## Pedra solta assentada no perfil. Sem elas o terreno é uma rampa sem escala:
## não dá para saber se a nave é grande ou o morro é pequeno.
func _espalhar_pedras() -> void:
	for i in pedras.size():
		var x := pedras[i]
		var sprite := Sprite2D.new()
		sprite.texture = PEDRA_GRANDE if i % 3 == 0 else PEDRA_PEQUENA
		sprite.centered = false
		sprite.offset = Vector2(-sprite.texture.get_width() * 0.5,
			-sprite.texture.get_height())
		sprite.flip_h = i % 2 == 0
		sprite.position = Vector2(roundf(x), roundf(altura_do_terreno(x)))
		_pedras.add_child(sprite)


## Altura da superfície em x, interpolada no perfil.
func altura_do_terreno(x: float) -> float:
	for i in perfil.size() - 1:
		var a := perfil[i]
		var b := perfil[i + 1]
		if x >= a.x and x <= b.x:
			return lerpf(a.y, b.y, (x - a.x) / maxf(1.0, b.x - a.x))
	return perfil[perfil.size() - 1].y


func _ao_pousar(plataforma: Node) -> void:
	if plataforma == null:
		_hud.avisar("pousada fora da plataforma", Hud.COR_ATENCAO)
		return
	var plat := plataforma as PlataformaDePouso
	_hud.avisar("pousada em %s — %d px de deck" % [plat.como_se_chama(), roundi(plat.largura())],
		Hud.COR_BOM)


func _ao_decolar() -> void:
	_hud.avisar("decolou", Hud.COR_APAGADO)


func _ao_impactar(dano: float, velocidade: float, desalinhamento: float) -> void:
	_camera.sacudir(dano * 0.09)
	_hud.avisar("impacto: -%d%% casco, %d p/s a %d° da superfície" % [
		roundi(dano), roundi(velocidade), roundi(desalinhamento)], Hud.COR_ALERTA)


func _ao_destruir() -> void:
	_hud.avisar("nave destruída — R reinicia", Hud.COR_ALERTA)
