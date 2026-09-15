class_name ApresentacaoDaNave
extends Node2D

## Tudo que a nave mostra, e nada do que ela simula.
##
## Existe separado porque casco, chama e luz de motor não têm relação nenhuma
## com inércia, massa ou avaliação de pouso: só precisam saber quanto empuxo
## está saindo. Enquanto isso morava em `nave.gd`, o código de física carregava
## três referências de nó de desenho no meio das forças.
##
## O fluxo é de mão única: a nave manda, esta classe desenha. Ela não conhece
## `Nave` e não lê o pai, então trocar a aparência não toca na simulação.

## Abaixo disto o motor está em marcha lenta e a chama não acende.
const EMPUXO_MINIMO_VISIVEL: float = 0.05

## Altura da chama com o motor em marcha lenta, como fração do desenho cheio.
@export var chama_minima: float = 0.45
## Quanto o motor ilumina o que está em volta, no empuxo máximo.
@export var energia_da_luz: float = 1.7

## A chama é uma tira de quadros de pixel art que pisca enquanto o motor empurra.
## A ordem volta ao quadro médio entre o curto e o longo, para tremer em vez de
## pulsar.
const SEQUENCIA_DA_CHAMA: Array[int] = [0, 1, 0, 2]
const MS_POR_QUADRO_DA_CHAMA: int = 70

## Contra o fundo do espaço o contorno escuro do casco some, porque é a mesma cor
## do vazio, e a nave parece apagada. No espaço ela ganha um anel de 1 px em volta
## da silhueta, nesta cor da paleta. O anel sai do alfa da arte, como a colisão:
## trocar o casco leva o anel junto.
const COR_DO_ANEL_DE_ESPACO: Color = Color("7f708a")  # neutros_frios:1

@onready var _anel_de_espaco: Sprite2D = $AnelDeEspaco
@onready var _casco: Sprite2D = $Casco
@onready var _chama: Sprite2D = $Chama
@onready var _luz_do_motor: PointLight2D = $Chama/Luz


func _ready() -> void:
	apagar()


## A arte do casco vem da ficha do modelo, então quem veste a nave é quem leu a
## ficha. Esta classe não escolhe textura.
func vestir(arte: Texture2D) -> void:
	_casco.texture = arte
	_anel_de_espaco.texture = anel_de(arte)


## No espaço a câmera fica afastada, e o desenho encolheria para 0,9 pixel de
## janela por pixel de arte: a amostragem come e duplica pixels, e o anel de 1 px
## sai quebrado. Por isso, no espaço, a apresentação troca de escala para cada
## pixel da arte cair num número inteiro de pixels de janela, e acende o anel.
## Numa região volta ao tamanho de arte, onde o céu claro já separa o casco.
func modo_de_espaco(ligado: bool, escala: float) -> void:
	_anel_de_espaco.visible = ligado
	scale = Vector2.ONE * (escala if ligado else 1.0)


## A silhueta da arte engordada 1 px nos quatro lados, numa cor só. Fica atrás do
## casco, então só a borda aparece. É estática para a tela de título, que mostra o
## foguete no espaço sem ter uma nave, usar o mesmo anel.
static func anel_de(arte: Texture2D, cor: Color = COR_DO_ANEL_DE_ESPACO) -> Texture2D:
	var origem: Image = arte.get_image()
	var anel := Image.create(origem.get_width() + 2, origem.get_height() + 2, false, Image.FORMAT_RGBA8)
	var vizinhos: Array[Vector2i] = [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for y: int in origem.get_height():
		for x: int in origem.get_width():
			if origem.get_pixel(x, y).a < 0.5:
				continue
			for passo: Vector2i in vizinhos:
				anel.set_pixel(x + 1 + passo.x, y + 1 + passo.y, cor)
	return ImageTexture.create_from_image(anel)


## `empuxo` é 0 a 1: a nave decide quanto o motor está empurrando, esta classe
## só desenha o que ela decidiu.
func atualizar(empuxo: float) -> void:
	var acesa: bool = empuxo > EMPUXO_MINIMO_VISIVEL
	_chama.visible = acesa
	# O motor é emissivo: ele ilumina o terreno e o próprio casco, não só
	# desenha uma chama. É o que faz o pouso ler à noite.
	_luz_do_motor.energy = energia_da_luz * empuxo if acesa else 0.0
	if acesa:
		# A linha de cima da chama fica presa na boca do bocal; o empuxo estica
		# só para baixo.
		_chama.scale.y = lerpf(chama_minima, 1.0, empuxo)
		var passo: int = floori(Time.get_ticks_msec() / float(MS_POR_QUADRO_DA_CHAMA))
		_chama.frame = SEQUENCIA_DA_CHAMA[passo % SEQUENCIA_DA_CHAMA.size()]


func apagar() -> void:
	atualizar(0.0)
