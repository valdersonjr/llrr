class_name ModeloDeNave
extends Resource

## O chassi da nave: slots, silhueta, limite de carga e os números de voo.
## Os três modelos são fichas diferentes lidas pela mesma `nave.tscn`, nunca
## cenas separadas. Ver entities/nave/CLAUDE.md.

@export var nome: String = ""
@export_multiline var papel: String = ""

@export_group("Massa e propulsão")
## Massa vazia, em quilos.
@export var massa: float = 1800.0
## Quantos g o propulsor principal produz com o porão vazio. Abaixo de 1 a nave
## não sai do chão da Terra. Entre 2 e 3 o pouso perdoa erro sem virar foguete.
@export var empuxo_em_g: float = 2.4
## O mesmo, para os propulsores de manobra que empurram de lado.
@export var empuxo_lateral_em_g: float = 0.55
## Autoridade do controle de manobra, em graus por segundo ao quadrado.
@export var aceleracao_angular: float = 240.0
## Quanto giro a estabilização anula por segundo, em graus por segundo.
## Acessibilidade, não item de loja: não custa nada ao jogador.
@export var autoridade_de_estabilizacao: float = 110.0
## Teto de giro, em graus por segundo. Impede que segurar a tecla vire pião.
@export var giro_maximo: float = 150.0

@export_group("Porão")
## Carga máxima, em quilos.
@export var capacidade_de_carga: float = 2400.0

@export_group("Limites de pouso")
## O que o trem de pouso aguenta na hora do toque, em metros por segundo.
## Referência: o módulo lunar da Apollo era projetado para cerca de 3 m/s.
@export var velocidade_maxima_de_toque: float = 3.2
## Inclinação máxima no toque, em graus.
@export var inclinacao_em_graus: float = 12.0
## Giro máximo no toque, em graus por segundo.
@export var giro_por_segundo: float = 16.0

@export_group("Casco")
## A arte do casco. A colisão sai do alfa dela, então silhueta e desenho não têm
## como discordar, e trocar o casco de um modelo é trocar um arquivo.
@export var arte: Texture2D
## Quanto a colisão pode se afastar do contorno, em pixels. Alto demais perde a
## perna; baixo demais cria lasca fina, que corpo rígido não resolve bem.
@export var tolerancia_da_colisao: float = 3.0
