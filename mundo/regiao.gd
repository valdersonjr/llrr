class_name Regiao
extends Node2D

## A superfície visitável de um lugar: terreno, cenário e o ponto de coleta.
## Toda região usa esta forma de cena, inclusive a de outpost.
##
## Uma região não conhece a nave e não conhece a ficha do planeta. Quem entra num
## lugar é que aplica as condições dele, com `aplicar()`. Isso mantém a região
## abrindo sozinha por `--scene` e evita que a ficha do planeta e a cena da região
## apontem uma para a outra.

## Uma região é uma tela. O número mora aqui, com quem é dono dele, e quem
## precisa dele pergunta: o corpo no espaço para plantar a região, e o que vive
## dentro dela para dar a volta nas bordas.
const TAMANHO: Vector2 = Vector2(640.0, 360.0)

## Um outpost pode destoar da luz do planeta: é trabalho humano no meio do
## lugar, e o conceito deixa a ambientação dele contrastar com o resto. Com
## `luz_propria` ligada, a região usa as cores dela em vez das da ficha.
@export var luz_propria: bool = false
@export var cor_ambiente_propria: Color = Color.WHITE
@export var cor_do_ceu_propria: Color = Color.WHITE

var _ambiente_do_lugar: Color = Color.WHITE

@onready var _campo: Area2D = $CampoGravitacional
@onready var _ambiente: CanvasModulate = $Ambiente
@onready var _ceu: Polygon2D = $Fundo/Ceu


func aplicar(planeta: Planeta) -> void:
	_campo.gravity = Escala.para_pixels(planeta.gravidade)
	_campo.linear_damp = planeta.arrasto_do_ar
	var ambiente: Color = cor_ambiente_propria if luz_propria else planeta.cor_ambiente
	_ambiente_do_lugar = ambiente
	_ambiente.color = ambiente
	_ceu.color = cor_do_ceu_propria if luz_propria else planeta.cor_do_ceu


## A região chega desvanecendo, junto com a aproximação da câmera: é a atmosfera
## entrando, não uma tela de carregamento. A luz do lugar chega no mesmo tempo,
## partindo do branco, para o ambiente não pular de uma cor para a outra.
##
## Quem abre a região sozinha por `--scene` não chama nada disso, e é por isso
## que `aplicar()` já deixa tudo no valor final.
func revelar(segundos: float) -> void:
	modulate.a = 0.0
	_ambiente.color = Color.WHITE
	var entrada: Tween = create_tween().set_parallel(true)
	entrada.tween_property(self, "modulate:a", 1.0, segundos)
	entrada.tween_property(_ambiente, "color", _ambiente_do_lugar, segundos)


## O caminho de volta. Devolve o tween para quem chamou decidir quando descartar
## a região: ela precisa continuar na cena até acabar de sumir.
func esconder(segundos: float) -> Tween:
	var saida: Tween = create_tween().set_parallel(true)
	saida.tween_property(self, "modulate:a", 0.0, segundos)
	saida.tween_property(_ambiente, "color", Color.WHITE, segundos)
	return saida
