class_name Relevo
extends RefCounted
## Constrói o relevo visível de uma superfície a partir do perfil dela.
##
## Existe porque terreno chapado com um contorno em volta é o que separa
## cenário de protótipo de cenário acabado. Uma superfície se lê em três
## escalas: a silhueta, que você reconhece de olhos semicerrados; a forma
## média, que dá volume; e o grão, que é textura. Faltando a do meio, a
## massa vira mancha — e forma média é justamente o que este arquivo gera.
##
## Tudo aqui deriva do mesmo `perfil` que já define o visual e a colisão da
## fase, então o relevo acompanha sozinho qualquer edição do relevo. Nenhuma
## função guarda estado: são todas estáticas, e a fase é dona dos nós.
##
## A fase que usa isto está em `stages/`; a receita de montagem, com a ordem
## das camadas, está em `stages/CLAUDE.md`.

## De onde a luz vem. `top-left` em todo o projeto — ver a skill de pixel art.
const DIRECAO_DA_LUZ := Vector2(-1.0, -1.0)
## Abaixo disto uma face está virada para longe do sol.
const LUZ_RASANTE := 0.35


## Quanto de sol cada ponto do perfil recebe, de 0 a 1.
##
## É esta função que impede a crosta de virar contorno: uma faixa clara de
## brilho igual dando a volta na silhueta não é iluminação, é traço. A face
## virada para cima e para a esquerda tem que receber banda larga e clara, e
## a virada para a direita quase nada.
static func iluminacao(perfil: PackedVector2Array) -> PackedFloat32Array:
	var luz := DIRECAO_DA_LUZ.normalized()
	var valores := PackedFloat32Array()
	for i in perfil.size():
		var antes := perfil[maxi(i - 1, 0)]
		var depois := perfil[mini(i + 1, perfil.size() - 1)]
		var tangente := depois - antes
		if tangente.is_zero_approx():
			valores.append(0.5)
			continue
		# A normal aponta para fora da massa, ou seja para cima.
		var normal := Vector2(tangente.y, -tangente.x).normalized()
		valores.append(clampf(normal.dot(luz), 0.0, 1.0))
	return valores


## Comprimento acumulado ao longo do perfil, normalizado de 0 a 1. É o eixo
## que `Gradient` e `Curve` usam para se casar com um `Line2D`.
static func percurso(perfil: PackedVector2Array) -> PackedFloat32Array:
	var acumulado := PackedFloat32Array([0.0])
	var total := 0.0
	for i in range(1, perfil.size()):
		total += perfil[i].distance_to(perfil[i - 1])
		acumulado.append(total)
	if total <= 0.0:
		return acumulado
	for i in acumulado.size():
		acumulado[i] = acumulado[i] / total
	return acumulado


## Gradiente que tinge um `Line2D` conforme a face pega ou não o sol.
static func gradiente_de_luz(perfil: PackedVector2Array, sombra: Color,
		luz: Color) -> Gradient:
	var valores := iluminacao(perfil)
	var eixo := percurso(perfil)
	var g := Gradient.new()
	var cores := PackedColorArray()
	for v in valores:
		cores.append(sombra.lerp(luz, v))
	g.offsets = eixo
	g.colors = cores
	return g


## Curva de largura pela mesma luz: face iluminada mostra banda larga, face
## em sombra mostra um fio. Largura constante volta a ler como contorno.
static func largura_por_luz(perfil: PackedVector2Array, minima: float,
		maxima: float) -> Curve:
	var valores := iluminacao(perfil)
	var eixo := percurso(perfil)
	var c := Curve.new()
	c.min_value = 0.0
	c.max_value = maxf(maxima, 1.0)
	for i in valores.size():
		c.add_point(Vector2(eixo[i], lerpf(minima, maxima, valores[i])))
	return c


## O mesmo perfil afundado `distancia` px para dentro da massa, medido pela
## normal e não na vertical — assim a linha acompanha encosta inclinada em
## vez de escorregar dela.
static func afundar(perfil: PackedVector2Array, distancia: float,
		tremor: float = 0.0, semente: int = 0) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var fora := PackedVector2Array()
	for i in perfil.size():
		var antes := perfil[maxi(i - 1, 0)]
		var depois := perfil[mini(i + 1, perfil.size() - 1)]
		var tangente := depois - antes
		var normal := Vector2(0.0, -1.0)
		if not tangente.is_zero_approx():
			normal = Vector2(tangente.y, -tangente.x).normalized()
		var d := distancia + (rng.randf_range(-tremor, tremor) if tremor > 0.0 else 0.0)
		fora.append((perfil[i] - normal * d).round())
	return fora


## Banda escura logo abaixo da crosta. Sem ela a superfície iluminada encosta
## direto na massa e o chão fica sem espessura.
##
## Modulada pela mesma luz da crosta: sombra é o que uma face iluminada
## projeta, então onde não há crosta acesa não há o que ocluir. Banda de
## opacidade igual em toda a volta é contorno preto, exatamente o defeito
## que a crosta iluminada existe para não ter.
static func oclusao(perfil: PackedVector2Array, cor: Color, espessura: float,
		profundidade: float) -> Line2D:
	var linha := Line2D.new()
	linha.name = "Oclusao"
	linha.points = afundar(perfil, profundidade)
	linha.width = espessura
	linha.gradient = gradiente_de_luz(perfil, Color(cor, cor.a * 0.15), cor)
	linha.width_curve = largura_por_luz(perfil, 0.4, 1.0)
	linha.joint_mode = Line2D.LINE_JOINT_ROUND
	linha.begin_cap_mode = Line2D.LINE_CAP_BOX
	linha.end_cap_mode = Line2D.LINE_CAP_BOX
	return linha


## Estratos: bandas de sedimento atravessando a massa, recortadas contra o
## polígono do terreno.
##
## Elas são **horizontais**, não paralelas à superfície. Camada de sedimento
## assenta na horizontal e a encosta corta ela em ângulo — é justamente esse
## corte que dá volume. Banda acompanhando o perfil vira espaguete assim que
## o relevo tem uma encosta íngreme, porque duas bandas vizinhas se cruzam.
##
## O recorte é o que garante que nada escape para o céu: `intersect_polygons`
## devolve só o pedaço que cai dentro da massa.
static func estratos(terreno: PackedVector2Array, alturas: Array, espessura: float,
		cor: Color, cor_do_topo: Color, largura: Vector2, semente: int) -> Node2D:
	var raiz := Node2D.new()
	raiz.name = "Estratos"
	if terreno.size() < 3:
		return raiz
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for altura in alturas:
		var grossura := espessura * rng.randf_range(0.55, 1.45)
		var banda := _banda(altura, grossura, largura, rng)
		_recortar(raiz, banda, terreno, cor)
		# O topo da banda é a face que o sol pega. Sem esse fio a banda é só
		# uma mancha mais clara, não um degrau.
		_recortar(raiz, _banda(altura, 1.0, largura, RandomNumberGenerator.new()),
			terreno, cor_do_topo)
	return raiz


## Uma faixa horizontal de borda ondulada, para a banda não ler como régua.
static func _banda(altura: float, espessura: float, largura: Vector2,
		rng: RandomNumberGenerator) -> PackedVector2Array:
	var topo := PackedVector2Array()
	var base := PackedVector2Array()
	var x := largura.x
	while x <= largura.y:
		var d := rng.randf_range(-2.5, 2.5)
		topo.append(Vector2(x, altura + d))
		base.append(Vector2(x, altura + espessura + d))
		x += 26.0
	base.reverse()
	return topo + base


## Guarda no `pai` cada pedaço de `forma` que cai dentro de `recorte`.
static func _recortar(pai: Node2D, forma: PackedVector2Array,
		recorte: PackedVector2Array, cor: Color) -> void:
	for pedaco in Geometry2D.intersect_polygons(forma, recorte):
		if pedaco.size() < 3:
			continue
		var p := Polygon2D.new()
		p.polygon = pedaco
		p.color = cor
		pai.add_child(p)


## Fraturas verticais cortando os estratos. Rocha quebra em plano, e o plano
## de quebra é o que amarra as bandas — sem ele os estratos ficam soltos, como
## listras pintadas.
##
## Também recortadas contra a massa, pelo mesmo motivo.
static func fraturas(terreno: PackedVector2Array, quantidade: int, faixa: Vector2,
		comprimento: Vector2, sombra: Color, luz: Color, semente: int) -> Node2D:
	var raiz := Node2D.new()
	raiz.name = "Fraturas"
	if terreno.size() < 3:
		return raiz
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var limites := _limites(terreno)
	for _i in quantidade:
		var x := rng.randf_range(limites.position.x, limites.end.x)
		var topo := rng.randf_range(faixa.x, faixa.y)
		var alto := rng.randf_range(comprimento.x, comprimento.y)
		var inclinacao := rng.randf_range(-5.0, 5.0)
		var fenda := PackedVector2Array([
			Vector2(x, topo), Vector2(x + 1.0, topo),
			Vector2(x + 1.0 + inclinacao, topo + alto), Vector2(x + inclinacao, topo + alto)])
		_recortar(raiz, fenda, terreno, sombra)
		# O lábio do lado do sol pega luz; o outro lado some na sombra.
		var labio := PackedVector2Array([
			Vector2(x - 1.0, topo), Vector2(x, topo),
			Vector2(x + inclinacao, topo + alto), Vector2(x - 1.0 + inclinacao, topo + alto)])
		_recortar(raiz, labio, terreno, luz)
	return raiz


static func _limites(poligono: PackedVector2Array) -> Rect2:
	var r := Rect2(poligono[0], Vector2.ZERO)
	for p in poligono:
		r = r.expand(p)
	return r


## Fio de luz na crista de uma silhueta de fundo. Polígono chapado não tem
## relevo; um pixel mais claro na aresta virada para o sol já tem.
static func aresta_iluminada(linha: PackedVector2Array, cor_da_silhueta: Color,
		cor_da_luz: Color) -> Line2D:
	var fio := Line2D.new()
	fio.name = "ArestaIluminada"
	fio.points = linha
	fio.width = 1.0
	fio.gradient = gradiente_de_luz(linha, cor_da_silhueta, cor_da_luz)
	fio.joint_mode = Line2D.LINE_JOINT_ROUND
	return fio
