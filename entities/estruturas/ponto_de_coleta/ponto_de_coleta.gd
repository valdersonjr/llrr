@tool
class_name PontoDeColeta
extends StaticBody2D

## O lugar demarcado onde pousar vale. Encostar no terreno não é pousar: é este
## corpo, no grupo `pontos_de_coleta`, que a nave consulta.
##
## **Ele nem sempre é uma plataforma.** A seção 10 do conceito é explícita: a
## demarcação é conteúdo autoral, feito para cada situação, e uma boca de mina,
## um anel de balizas ou um pátio de carga servem tão bem quanto um deque. Por
## isso aqui não há arte fixa: a cena diz a largura e as texturas, e esta classe
## monta as balizas, a marca no chão e a colisão em cima disso.
##
## As duas regras que o conceito cobra de qualquer demarcação estão no desenho:
##
## - **legível de longe**, por silhueta e por luz própria, e não por marcador de
##   interface colado na tela;
## - **dizer mais que "aqui"**: a distância entre as balizas é o tamanho do lugar
##   de pouso, então olhar já informa quanta margem existe.
##
## A luz também responde ao estado do pouso, porque a cor sozinha nunca basta e
## porque o jogador precisa saber que o contato valeu sem tirar o olho da nave.

## Avisa quem desenha o lugar (um sinal luminoso, uma baliza animada) que o
## estado do pouso mudou, sem que ele precise conhecer a nave.
signal estado_mudou(estado: Nave.Estado)

## O último estado mostrado. Quem se conecta depois do `_ready` lê daqui.
var estado_atual: Nave.Estado = Nave.Estado.VOANDO

## Quanto chão conta como lugar de pouso, em pixels. É o botão de dificuldade
## que a seção 10 chama de tamanho do lugar de pouso: a nave tem 26 pixels de
## largura, então 68 perdoa e 34 aperta.
@export var largura: float = 68.0:
	set(valor):
		largura = valor
		if is_node_ready():
			montar()

## A espessura do deque. Fina de propósito: o que sustenta a nave é o chão que
## já existe, e a demarcação marca, não constrói.
@export var espessura: float = 8.0

@export_group("Arte")
## A baliza da esquerda. A da direita é a mesma, espelhada, salvo se houver uma
## própria: duas pedras diferentes leem como lugar, duas iguais leem como cerca.
@export var baliza: Texture2D:
	set(valor):
		baliza = valor
		if is_node_ready():
			montar()
@export var baliza_direita: Texture2D
## Riscado no chão entre as balizas, repetido ao longo da largura.
@export var marca_no_chao: Texture2D
@export var luz: Texture2D

@export_group("Luz por estado")
@export var cor_esperando: Color = Color(0.58, 0.88, 0.95)
@export var cor_no_contato: Color = Color(1.0, 0.82, 0.45)
@export var cor_pousada: Color = Color(0.55, 0.95, 0.6)
@export var forca_da_luz: float = 1.3


func _ready() -> void:
	montar()
	mostrar(Nave.Estado.VOANDO)


## Reconstrói tudo a partir dos dados. Roda também no editor, para quem arrasta a
## largura ver o lugar de pouso mudar de tamanho na hora.
func montar() -> void:
	for velho: Node in get_children():
		velho.free()

	var meio: float = largura * 0.5
	_montar_colisao(meio)
	if marca_no_chao != null:
		_montar_marca(meio)
	if baliza != null:
		_montar_baliza(baliza, -meio, false, "Esquerda")
		_montar_baliza(
			baliza_direita if baliza_direita != null else baliza,
			meio, baliza_direita == null, "Direita"
		)


## A cor das balizas conta o que a nave está fazendo: esperando, encostada, ou
## pousada de verdade. Quem sabe o estado é a cena do sistema, que chama aqui.
func mostrar(estado: Nave.Estado) -> void:
	estado_atual = estado
	estado_mudou.emit(estado)
	var cor: Color = cor_esperando
	var forca: float = forca_da_luz
	match estado:
		Nave.Estado.TOCANDO:
			cor = cor_no_contato
			forca = forca_da_luz * 1.25
		Nave.Estado.POUSADA:
			cor = cor_pousada
			forca = forca_da_luz * 1.1
	for no: Node in get_children():
		if no is PointLight2D:
			var lampada := no as PointLight2D
			lampada.color = cor
			lampada.energy = forca


func _montar_colisao(meio: float) -> void:
	var forma := CollisionShape2D.new()
	forma.name = "Deque"
	var caixa := RectangleShape2D.new()
	caixa.size = Vector2(largura, espessura)
	forma.shape = caixa
	forma.position = Vector2(0.0, -espessura * 0.5)
	_guardar(forma)


func _montar_marca(meio: float) -> void:
	var risco := Sprite2D.new()
	risco.name = "MarcaNoChao"
	risco.texture = marca_no_chao
	risco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	risco.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	risco.region_enabled = true
	risco.region_rect = Rect2(0.0, 0.0, largura, marca_no_chao.get_height())
	risco.position = Vector2(0.0, -2.0)
	_guardar(risco)


## A baliza fica **fora** da largura, encostada nela. Se ela invadir o lugar de
## pouso, a distância entre as duas deixa de ser a informação que o jogador lê, e
## a demarcação passa a mentir sobre quanta margem existe.
func _montar_baliza(arte: Texture2D, x: float, espelhar: bool, lado: String) -> void:
	var largura_da_pedra: float = arte.get_width()
	var canto: float = x - largura_da_pedra if x < 0.0 else x
	var pedra := Sprite2D.new()
	# Nome de verdade, e não o automático: é assim que as peças aparecem no
	# relatório do `cenario_check`, e "@Sprite2D@5" não diz nada a ninguém.
	pedra.name = "Baliza" + lado
	pedra.texture = arte
	pedra.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pedra.flip_h = espelhar
	pedra.centered = false
	pedra.position = Vector2(canto, -arte.get_height())
	_guardar(pedra)

	if luz == null:
		return
	var lampada := PointLight2D.new()
	lampada.name = "Luz" + lado
	lampada.texture = luz
	lampada.texture_scale = 0.42
	lampada.position = Vector2(canto + largura_da_pedra * 0.5, -arte.get_height() * 0.5)
	_guardar(lampada)


func _guardar(no: Node) -> void:
	add_child(no)
	if Engine.is_editor_hint():
		no.owner = get_tree().edited_scene_root
