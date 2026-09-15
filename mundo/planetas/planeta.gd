class_name Planeta
extends Resource

## A ficha de um planeta. Ver a seção 7 do conceito: condições físicas, o recurso
## que ele oferece, e um assunto próprio que não se repete em nenhum outro corpo.
##
## Não existe lista de biomas permitidos. Floresta, gelo, refinaria abandonada ou
## um planeta inteiro de doce são igualmente legítimos: o que o planeta precisa
## provar é que pousar nele não é igual a pousar nos outros.

@export var nome: String = ""
@export_multiline var assunto: String = ""

@export_group("Física")
## Aceleração da gravidade na superfície, em metros por segundo ao quadrado.
## Terra 9.81, Marte 3.72, Lua 1.62. É o primeiro botão de dificuldade de um
## planeta, e o número é de verdade: quem converte para pixel é `Escala`.
@export var gravidade: float = Escala.G_TERRA
## Arrasto do ar, como fração da velocidade perdida por segundo. Zero em corpo
## sem atmosfera, onde desligar o motor não freia nada.
@export var arrasto_do_ar: float = 0.0

@export_group("Conteúdo")
@export var recurso: RecursoMineral
## As regiões de superfície deste corpo, na ordem em que a tela de regiões as
## mostra. Um planeta é um lugar com mapas dentro, não um mapa: a ficha de cada
## região diz o nome dela e onde a nave aparece.
@export var regioes: Array[FichaDeRegiao] = []

@export_group("Luz")
## A cor com que o corpo tinge tudo que está nele. É o que a seção 14 chama de
## preenchimento de ambiente: a sombra recebe a cor do lugar, e escurecer a mesma
## matiz produz rampa morta. Emissivos somam luz por cima disso.
@export var cor_ambiente: Color = Color(0.7, 0.76, 0.78)
## O céu é desenhado pela região, e não é a cor de fundo da janela, justamente
## para receber o ambiente junto com o resto. Céu que não escurece com a cena
## denuncia que a luz é falsa.
@export var cor_do_ceu: Color = Color(0.58, 0.89, 0.89)

@export_group("Leitura de longe")
## Como o corpo se vê na vista de espaço. Cor e silhueta precisam separar este
## planeta de qualquer outro sem depender de rótulo.
@export var cor_de_identidade: Color = Color.WHITE
## A carta de superfície: o planeta visto de cima, na tela de regiões. É uma cena
## com as camadas de tile (mar e mata, deserto, platô) no tamanho que o desenho
## pedir; a ficha de cada região diz onde fica o marcador dela.
@export var carta: PackedScene
## Como o corpo aparece no mapa do sistema, desenhado já na escala do mapa: o
## diâmetro em pixels é o do corpo no espaço reduzido na mesma proporção do mapa.
## Pixel art não se encolhe, então a miniatura é um desenho, e não o corpo reduzido.
@export var miniatura: Texture2D
