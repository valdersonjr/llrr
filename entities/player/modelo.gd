class_name Modelo
extends Resource
## Dados de um modelo de nave: o que ele pesa, o que ele empurra e o que o trem de
## pouso aguenta. Os três modelos do jogo (utilitário leve, cargueiro
## resistente, interceptador) diferem por estes números, não por código.
##
## Unidades: massa em toneladas, distância em pixels, ângulo em graus.
## Empuxo é força — a aceleração é `empuxo / massa`, e é por isso que a carga
## a bordo muda como a nave voa (seção 4 do conceito).

@export var nome: String = ""

@export_group("Massa")
## Nave vazia, sem carga.
@export_range(1.0, 60.0, 0.5, "or_greater", "suffix:t") var massa_seca: float = 8.0
## Quanto o porão leva. Carga pesa: entra direto na massa.
@export_range(0.0, 80.0, 0.5, "or_greater", "suffix:t") var capacidade_carga: float = 6.0

@export_group("Propulsão")
## Empuxo do motor principal, no eixo da nave.
@export_range(100.0, 12000.0, 10.0, "or_greater") var empuxo_principal: float = 1320.0
## Empuxo dos propulsores de manobra, translação lateral.
@export_range(20.0, 3000.0, 10.0, "or_greater") var empuxo_manobra: float = 340.0
@export_range(100.0, 12000.0, 10.0, "or_greater") var torque_manobra: float = 1900.0
## Teto de velocidade angular, em graus/s.
@export_range(20.0, 360.0, 5.0, "suffix:°/s") var giro_maximo: float = 120.0

@export_group("Trem de pouso")
## Velocidade de contato que conta como pouso limpo, alinhada.
@export_range(5.0, 120.0, 1.0, "suffix:px/s") var pouso_velocidade_maxima: float = 30.0
## Desalinhamento tolerado entre a nave e a normal da superfície.
@export_range(1.0, 45.0, 1.0, "suffix:°") var pouso_angulo_maximo: float = 12.0
## Giro residual tolerado no contato, em graus/s.
@export_range(1.0, 90.0, 1.0, "suffix:°/s") var pouso_giro_maximo: float = 20.0
## Tempo parada e nivelada até o contato virar pouso de fato.
@export_range(0.0, 3.0, 0.05, "suffix:s") var pouso_tempo_estavel: float = 0.6


## Aceleração com o porão vazio, em px/s². É o primeiro número que o jogador
## sente, e o que decide se a nave sobe da plataforma.
func aceleracao_leve() -> float:
	return empuxo_principal / massa_seca


## A mesma coisa com o porão cheio. Se cair abaixo da gravidade da região, o
## modelo simplesmente não decola carregado — é aqui que se vê o preço.
func aceleracao_carregada() -> float:
	return empuxo_principal / (massa_seca + capacidade_carga)
