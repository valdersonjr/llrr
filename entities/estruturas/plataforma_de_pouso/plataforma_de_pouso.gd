@tool
class_name PlataformaDePouso
extends StaticBody2D
## Plataforma de pouso montada por repetição de um segmento de 32px.
##
## A largura é o que comunica dificuldade, então ela é parâmetro da cena e
## não arte nova: `segmentos` estica o sprite, a colisão e nada mais.
##
## A origem do nó é o centro da superfície do deck — posicionar a plataforma
## é dizer onde a nave vai encostar.

const LARGURA_SEGMENTO := 32
const ALTURA_TEXTURA := 16
## Linhas do sprite ocupadas pela laje; acima delas ficam as luzes de guia.
const TOPO_DO_DECK := 2
const ESPESSURA_DO_DECK := 4

## Como o lugar aparece nas mensagens. Vazio usa o nome do nó.
@export var nome: String = ""
## Toneladas paradas no deck esperando quem leve.
@export var carga_disponivel: float = 0.0
## Se esta plataforma repara e reabastece. Nem toda plataforma é porto — a
## seção 7 prevê plataformas soltas no meio do nada.
@export var oferece_servico: bool = false

@export_range(1, 8) var segmentos: int = 2:
	set(valor):
		segmentos = valor
		_remontar()

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _colisao: CollisionShape2D = $Colisao


func _ready() -> void:
	add_to_group(Nave.GRUPO_PLATAFORMA)
	_remontar()


func largura() -> float:
	return float(segmentos * LARGURA_SEGMENTO)


func como_se_chama() -> String:
	return nome if not nome.is_empty() else String(name)


## Repara o casco e enche o tanque, cobrando tempo de campanha. É a "saída da
## espiral de pobreza" da seção 5: sempre existe um caminho verificável de
## volta ao trabalho, e ele não pode depender de o jogador ter crédito.
##
## O custo em créditos fica pendente — a seção 12 ainda não existe em código, e
## inventar economia aqui seria decidir no lugar de quem escreve o conceito. A
## duração vem do relógio, que é quem sabe o que "demorado" significa.
##
## Devolve o que foi restaurado, ou um dicionário vazio se não havia o que fazer.
func servir(nave: Nave) -> Dictionary:
	if not oferece_servico:
		return {}
	var casco_faltando := nave.casco.integridade_maxima - nave.integridade
	var tanque_faltando := nave.casco.combustivel_maximo - nave.combustivel
	if casco_faltando <= 0.01 and tanque_faltando <= 0.01:
		return {}
	var fracao := casco_faltando / nave.casco.integridade_maxima
	var horas := Relogio.duracao_de_servico(fracao, tanque_faltando)
	Relogio.avancar(horas)
	nave.reparar()
	nave.abastecer()
	return {"casco": casco_faltando, "combustivel": tanque_faltando, "duracao": horas}


## Uma operação só, sem menu: com o porão cheio a nave descarrega tudo aqui,
## com ele vazio embarca o que couber. Devolve as toneladas movidas, positivo
## quando entraram na nave.
func transferir(nave: Nave) -> float:
	if nave.carga > 0.0:
		var saiu := nave.descarregar()
		carga_disponivel += saiu
		return -saiu
	var embarcou := nave.carregar(carga_disponivel)
	carga_disponivel -= embarcou
	return embarcou


func _remontar() -> void:
	if not is_node_ready():
		return
	var l := largura()
	_sprite.region_rect = Rect2(0.0, 0.0, l, ALTURA_TEXTURA)
	_sprite.offset = Vector2(-l * 0.5, -TOPO_DO_DECK)
	var forma := _colisao.shape as RectangleShape2D
	forma.size = Vector2(l, ESPESSURA_DO_DECK)
	_colisao.position = Vector2(0.0, ESPESSURA_DO_DECK * 0.5)
