class_name FichaDeRegiao
extends Resource

## Uma região de superfície de um lugar: o nome que o jogador lê, a cena do
## terreno e o ponto onde a nave aparece.
##
## Um planeta tem várias. A seção 7 do conceito põe "várias regiões por planeta"
## na coluna de expansão, e é isto aqui: o corpo deixa de ser um mapa e passa a
## ser um lugar com mapas dentro.
##
## A ficha existe para a tela de regiões poder listar tudo **sem carregar cena
## nenhuma**. Nome, assunto e posição no disco são dados leves; a cena do terreno
## só é instanciada quando o jogador escolhe descer.
##
## Ela é irmã de `Planeta`: descreve, não guarda estado de partida. O que o
## jogador fez numa região vive no autoload de campanha e vai para o save.

@export var nome: String = ""
## Uma linha, do jeito que aparece na tela de regiões. Não é o assunto do
## planeta: é o que separa esta região das outras do mesmo corpo.
@export_multiline var assunto: String = ""

@export_group("Conteúdo")
## A superfície onde se pousa. Abre sozinha por `--scene` para testar o pouso sem
## precisar voar até aqui.
@export var cena: PackedScene

@export_group("Chegada")
## Onde a nave termina a chegada, em coordenada da região. É este o ponto que o
## piloto automático persegue, e é a razão de a entrada ser escolhida e não
## consequência de trajetória: quem decide onde a nave aparece é quem desenha o
## lugar.
@export var onde_a_nave_aparece: Vector2 = Vector2(110.0, 56.0)
## De onde ela vem, em coordenada da região. O trecho entre este ponto e o de
## cima é a chegada que se vê.
@export var de_onde_a_nave_vem: Vector2 = Vector2(110.0, -80.0)

@export_group("Leitura de longe")
## Onde o marcador desta região fica sobre o disco do corpo, de -1 a 1 nos dois
## eixos. É só leitura: não existe geografia por trás, e duas regiões próximas no
## disco não são vizinhas de nada.
@export var ponto_no_corpo: Vector2 = Vector2.ZERO
