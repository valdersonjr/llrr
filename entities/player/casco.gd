class_name Casco
extends Resource
## Dados de um casco: o que ele pesa, o que ele empurra e o que o trem de
## pouso aguenta. Os três cascos do jogo (utilitário leve, cargueiro
## resistente, interceptador) diferem por estes números, não por código.
##
## Unidades: massa em toneladas, distância em pixels, ângulo em graus.
## Empuxo é força — a aceleração é `empuxo / massa`, e é por isso que carga
## e combustível a bordo mudam como a nave voa (seção 4 do conceito).

@export var nome: String = ""

@export_group("Massa")
## Casco vazio, sem combustível nem carga.
@export var massa_seca: float = 8.0
@export var capacidade_carga: float = 6.0
@export var combustivel_maximo: float = 5.0

@export_group("Propulsão")
## Empuxo do motor principal, no eixo da nave.
@export var empuxo_principal: float = 1320.0
## Empuxo dos propulsores de manobra, translação lateral.
@export var empuxo_manobra: float = 340.0
@export var torque_manobra: float = 1900.0
## Teto de velocidade angular, em graus/s.
@export var giro_maximo: float = 120.0

@export_group("Consumo")
## Toneladas por segundo com o acelerador no máximo.
@export var consumo_principal: float = 0.22
## Toneladas por segundo por eixo de manobra ativo — inclui a estabilização.
@export var consumo_manobra: float = 0.05

@export_group("Estrutura")
@export var integridade_maxima: float = 100.0

@export_group("Trem de pouso")
## Velocidade de contato que as pernas absorvem sem dano, alinhada.
@export var pouso_velocidade_maxima: float = 30.0
## Desalinhamento tolerado entre a nave e a normal da superfície.
@export var pouso_angulo_maximo: float = 12.0
## Giro residual tolerado no contato, em graus/s.
@export var pouso_giro_maximo: float = 20.0
## Tempo parada e nivelada até o contato virar pouso de fato.
@export var pouso_tempo_estavel: float = 0.6
