class_name CorpoNoEspaco
extends Node2D

## Como um lugar se vê na vista de espaço, e a porta de entrada dele.
##
## O corpo é o irmão de `Regiao`: um descreve o lugar visto de longe, o outro
## visto de dentro. A diferença é que o corpo **conhece** a ficha do planeta,
## porque ele é colocado à mão no sistema e precisa dizer que lugar é aquele. A
## região continua sem conhecer a ficha, para abrir sozinha por `--scene`.
##
## ## Entrar não é voar para dentro
##
## Chegar perto acende o destaque e o convite; a tecla abre a tela de regiões, e
## é lá que se escolhe onde descer. A nave não atravessa fronteira nenhuma: ela
## para onde está e depois aparece no ponto que a ficha da região definiu.
##
## Já foi diferente: a primeira versão entrava descendo sobre o corpo, sem nada
## ser recolocado. Aquilo entregava inércia contínua e tirava do projetista o
## controle de onde a nave aparece, que é o que um lugar desenhado à mão precisa.
## Trocamos uma promessa pela outra de propósito.

## Quanto a nave sobe acima do terreno antes de a região devolver a tela de
## regiões. Não é zero para a saída não disparar num pulinho, e não é muito para
## a nave não sumir da tela enquanto sai.
const MARGEM_DE_SAIDA: float = 40.0

## A que distância do corpo o convite de entrada acende, medido da borda dele.
const ALCANCE_DE_ENTRADA: float = 300.0

@export var planeta: Planeta

var _destacado: bool = false

@onready var _arte: Sprite2D = $Arte


func _ready() -> void:
	assert(planeta != null, "Um CorpoNoEspaco precisa da ficha do lugar em `planeta`.")
	assert(_arte.texture != null, "Um CorpoNoEspaco precisa do desenho do corpo em Arte.")


## O raio do corpo sai do próprio desenho: quem troca a arte troca o tamanho do
## planeta, e o alcance do convite acompanha sem ninguém mexer em número nenhum.
func raio() -> float:
	return _arte.texture.get_size().x * 0.5


## O desenho do corpo, para a tela de regiões mostrar o mesmo planeta que a nave
## está vendo pela janela.
func textura() -> Texture2D:
	return _arte.texture


## A nave está perto o bastante para o convite de entrada acender.
func ao_alcance(ponto: Vector2) -> bool:
	return global_position.distance_to(ponto) <= raio() + ALCANCE_DE_ENTRADA


## O canto de onde uma região deste corpo nasce, centrada nele. Espaço e
## superfície continuam no mesmo sistema de coordenadas, o que mantém a câmera
## simples e as ferramentas de conferência apontando para lugares de verdade.
func canto_da_regiao() -> Vector2:
	return global_position - Regiao.TAMANHO * 0.5


func area_da_regiao() -> Rect2:
	return Rect2(canto_da_regiao(), Regiao.TAMANHO)


## Onde o centro do quadro pode ficar enquanto se está numa região deste corpo.
## Como uma região é uma tela, isto é quase uma linha: a câmera fica parada no
## terreno e sobe só a margem de saída, para a nave não sumir enquanto ganha
## altitude para voltar à tela de regiões.
func limites_da_camera() -> Rect2:
	var centro: Vector2 = global_position
	return Rect2(
		Vector2(centro.x, centro.y - MARGEM_DE_SAIDA), Vector2(0.0, MARGEM_DE_SAIDA)
	)


## Subiu o bastante para deixar a região. Para os lados não se sai, dá-se a volta;
## para baixo está o chão.
func subiu_demais(ponto: Vector2) -> bool:
	return ponto.y < area_da_regiao().position.y - MARGEM_DE_SAIDA


## O corpo some enquanto se está dentro dele: quem mostra o lugar de perto é a
## região, e as duas ocupam o mesmo ponto no mundo. Como a troca acontece atrás da
## tela de regiões, isto não precisa desvanecer: ninguém vê o instante.
func aparecer(visivel: bool) -> void:
	_arte.visible = visivel


## O destaque é o que diz "dá para entrar aqui". Ele é desenhado no mundo, e não
## na interface, para acender em volta do corpo certo sem ninguém converter
## coordenada de tela.
func destacar(aceso: bool) -> void:
	if _destacado == aceso:
		return
	_destacado = aceso
	queue_redraw()


func _draw() -> void:
	if not _destacado:
		return
	var cor: Color = planeta.cor_de_identidade.lightened(0.45)
	cor.a = 0.9
	var distancia: float = raio() + 26.0
	# Quatro cantos em vez de um anel fechado: lê como mira, não como órbita.
	for canto: int in 4:
		var comeco: float = PI * 0.25 + canto * PI * 0.5 - 0.34
		draw_arc(Vector2.ZERO, distancia, comeco, comeco + 0.68, 12, cor, 4.0)
