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
## Cristas de fundo. Contraste baixo é o que as coloca longe, e o parallax
## confirma: o que está longe desliza menos. Elas passam da largura do mundo
## de propósito — deslizando, a borda do polígono entraria em quadro.
@export var serra_distante: PackedVector2Array = PackedVector2Array()
@export var serra_media: PackedVector2Array = PackedVector2Array()
## Posições em x onde cair pedra solta. O y sai do próprio perfil.
@export var pedras: PackedFloat32Array = PackedFloat32Array()
## Cascos disponíveis para troca. Ferramenta de protótipo: sentir os três
## papéis é o que responde a pergunta da seção 18, e ninguém sente um casco
## lendo a tabela dele.
@export var cascos: Array[PackedScene] = []

@onready var _nave: Nave = $UtilitarioLeve
@onready var _camera: CameraSeguidora = $Camera
@onready var _hud: Hud = $Hud
@onready var _pausa: Pausa = $Pausa
@onready var _colisao_terreno: CollisionPolygon2D = $Terreno/Colisao
@onready var _visual_terreno: Polygon2D = $Terreno/Visual
@onready var _detalhe_terreno: Polygon2D = $Terreno/Detalhe
@onready var _crosta: Line2D = $Terreno/Crosta
@onready var _serra_distante: Polygon2D = $FundoSerraDistante/SerraDistante
@onready var _serra_media: Polygon2D = $FundoSerraMedia/SerraMedia
@onready var _pedras: Node2D = $Pedras

var _indice_do_casco: int = 0


func _ready() -> void:
	_montar_terreno()
	_ligar_nave()
	_pausa.pediu_reinicio.connect(_reiniciar)
	queue_redraw()


func _ligar_nave() -> void:
	_nave.gravidade = gravidade_local
	_nave.pousou.connect(_ao_pousar)
	_nave.decolou.connect(_ao_decolar)
	_nave.impacto.connect(_ao_impactar)
	_nave.destruida.connect(_ao_destruir)
	_camera.alvo = _nave
	_hud.acompanhar(_nave)
	_pausa.acompanhar(_nave)


## Troca o casco no lugar, guardando só a posição. Estado de voo não passa
## junto de propósito: cada casco tem tanque, casco e porão próprios, e herdar
## os do anterior seria mentira sobre o que se está pilotando.
func _trocar_casco() -> void:
	if cascos.size() < 2:
		return
	_indice_do_casco = (_indice_do_casco + 1) % cascos.size()
	var nova: Nave = cascos[_indice_do_casco].instantiate()
	nova.position = Vector2(_nave.global_position.x,
		_nave.global_position.y - 24.0)
	_nave.queue_free()
	add_child(nova)
	_nave = nova
	_ligar_nave()
	_hud.avisar("CASCO: %s" % nova.casco.nome.to_upper(), Hud.COR_APAGADO)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("operar_carga"):
		_operar_carga()
	elif evento.is_action_pressed("trocar_casco"):
		_trocar_casco()
	elif evento.is_action_pressed("servico"):
		_pedir_servico()


func _reiniciar() -> void:
	# Sem despausar antes, a cena recarregada nasceria com a árvore parada.
	get_tree().paused = false
	get_tree().reload_current_scene()


func _pedir_servico() -> void:
	var plataforma := _plataforma_sob_a_nave_pousada()
	if plataforma == null:
		return
	if not plataforma.oferece_servico:
		_hud.avisar("%s NÃO TEM OFICINA" % plataforma.como_se_chama(), Hud.COR_ATENCAO)
		return
	var feito := plataforma.servir(_nave)
	if feito.is_empty():
		_hud.avisar("NADA A REPARAR NEM ABASTECER", Hud.COR_APAGADO)
		return
	_hud.avisar("SERVIÇO: +%d%% ESTRUTURA, +%.1f T — %d H" % [
		roundi(feito["casco"] / _nave.casco.integridade_maxima * 100.0),
		feito["combustivel"], roundi(feito["duracao"] / 3600.0)], Hud.COR_BOM)


## A plataforma sob a nave, se ela estiver pousada. Devolve null e avisa o
## jogador quando não estiver — as duas operações de deck exigem o mesmo.
func _plataforma_sob_a_nave_pousada() -> PlataformaDePouso:
	if _nave.estado != Nave.Estado.POUSADA:
		_hud.avisar("SÓ COM A NAVE POUSADA", Hud.COR_ATENCAO)
		return null
	var plataforma := _nave.plataforma_sob_a_nave() as PlataformaDePouso
	if plataforma == null:
		_hud.avisar("NÃO HÁ PLATAFORMA SOB AS DUAS PERNAS", Hud.COR_ATENCAO)
	return plataforma


## Uma tecla só resolve embarque e desembarque: com o porão cheio a nave
## descarrega, com ele vazio embarca o que couber.
func _operar_carga() -> void:
	var plataforma := _plataforma_sob_a_nave_pousada()
	if plataforma == null:
		return
	var movido := plataforma.transferir(_nave)
	if is_zero_approx(movido):
		_hud.avisar("%s NÃO TEM CARGA ESPERANDO" % plataforma.como_se_chama(), Hud.COR_ATENCAO)
	elif movido > 0.0:
		_hud.avisar("EMBARCOU %.1f T EM %s" % [movido, plataforma.como_se_chama()], Hud.COR_BOM)
	else:
		_hud.avisar("DESCARREGOU %.1f T EM %s" % [-movido, plataforma.como_se_chama()], Hud.COR_BOM)


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
	# A mesma rocha numa escala maior e translúcida por cima: em área grande a
	# grade de 32px do ladrilho aparece, e duas frequências sobrepostas a
	# desmancham sem precisar de textura nova.
	_detalhe_terreno.polygon = poligono
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
		_hud.avisar("POUSADA FORA DA PLATAFORMA", Hud.COR_ATENCAO)
		return
	var plat := plataforma as PlataformaDePouso
	_hud.avisar("POUSADA EM %s — %d PX DE DECK" % [plat.como_se_chama(), roundi(plat.largura())],
		Hud.COR_BOM)


func _ao_decolar() -> void:
	_hud.avisar("DECOLOU", Hud.COR_APAGADO)


func _ao_impactar(dano: float, velocidade: float, desalinhamento: float) -> void:
	_camera.sacudir(dano * 0.09)
	_hud.avisar("IMPACTO: -%d%% ESTRUTURA, %d P/S A %d° DA SUPERFÍCIE" % [
		roundi(dano), roundi(velocidade), roundi(desalinhamento)], Hud.COR_ALERTA)


func _ao_destruir() -> void:
	_hud.avisar("NAVE DESTRUÍDA — R REINICIA", Hud.COR_ALERTA)
