class_name CameraDoSistema
extends Camera2D

## A câmera das duas vistas, que são a mesma câmera a distâncias diferentes.
##
## Na superfície ela segue a nave dentro dos limites do lugar: como uma região é
## uma tela, esses limites são quase uma linha, e o efeito é a câmera ficar
## estacionada no terreno e subir só o tanto que a chegada pede. No espaço ela
## segue a nave livre, afastada, e antecipa um pouco para onde ela vai.
##
## **A troca entre as duas não é cronometrada, é medida.** `enquadrar()` recebe,
## por quadro, o quanto a nave está fora de um lugar, e a câmera só interpola.
## Isso é o que faz a aproximação terminar exatamente na fronteira, em vez de
## terminar num prazo: com tween de tempo fixo, descer devagar fazia a câmera
## chegar cedo demais e ficar um bom trecho perto, olhando para estrelas, com o
## planeta já fora do quadro.
##
## A seção 6 do conceito pede movimento contínuo de câmera e proíbe tela de
## carregamento anunciada. É este arquivo que cumpre as duas coisas.

## Quanto do quadro cabe na tela em cada vista. Na superfície, 1 desenha a região
## inteira nos 640 por 360 da tela base. No espaço, o número é calibração de voo,
## e o limite de baixo não é gosto: a seção 6 exige que a nave continue legível.
## Com 0.45 ela tem 13 pixels de tela, e o corpo de um planeta tem 288.
@export var zoom_na_superficie: float = 1.0
@export var zoom_no_espaco: float = 0.45

## Acima disto, o que a nave andou num quadro não foi voo: foi a borda do sistema
## dando a volta com ela. Rumo nenhum se deduz de um salto desses.
const SALTO_DE_BORDA: float = 1000.0

## Antecipação no espaço: quantos segundos de velocidade a câmera olha à frente,
## e o quanto no máximo. Com moderação, como manda a seção 6.
@export var antecipacao: float = 0.45
@export var antecipacao_maxima: float = 300.0

## Quanto a câmera corre atrás do alvo, por segundo, na mesma conta da suavização
## do `Camera2D`. A suavização é feita aqui, e não pela do motor: na borda do
## sistema o alvo pula o tamanho do espaço, e só com o ponto suavizado nas mãos dá
## para pular junto sem perder o atraso que a câmera já tinha. Com a do motor, pular
## zerava esse atraso e a imagem dava um tranco no instante da travessia.
@export var suavizacao: float = 8.0

var _seguido: Node2D = null
var _limites: Rect2 = Rect2()
var _fora: float = 1.0
var _a_frente: Vector2 = Vector2.ZERO
var _ultimo_ponto: Vector2 = Vector2.INF
## O ponto que a câmera mostra, correndo atrás do alvo. `INF` quer dizer "sem
## história": o próximo quadro nasce já no alvo.
var _suave: Vector2 = Vector2.INF
var _alvo_anterior: Vector2 = Vector2.INF


## A nave que a câmera segue. Quem monta a cena diz qual é: a câmera não procura
## sozinha.
func seguir(no: Node2D) -> void:
	_seguido = no


## `limites` é onde o centro do quadro pode ficar quando se está no lugar, e
## `fora` vai de 0, dentro dele, a 1, no espaço aberto.
func enquadrar(limites: Rect2, fora: float) -> void:
	_limites = limites
	_fora = clampf(fora, 0.0, 1.0)


## Aplica o enquadramento sem suavização, para quem abre a cena já numa vista.
## Sem isto a câmera nasce onde a cena a deixou e chega deslizando.
func assentar() -> void:
	_a_frente = Vector2.ZERO
	_ultimo_ponto = Vector2.INF
	_suave = Vector2.INF
	_alvo_anterior = Vector2.INF
	_aplicar(0.0)


func _process(delta: float) -> void:
	_medir_o_rumo(delta)
	_aplicar(delta)


## A câmera deduz para onde a nave vai olhando o quanto ela andou, em vez de ler
## a velocidade dela. Assim a antecipação não depende de a nave ser corpo rígido,
## que o `entities/nave/CLAUDE.md` declara ser escolha de protótipo.
func _medir_o_rumo(delta: float) -> void:
	if _seguido == null or delta <= 0.0:
		return
	var agora: Vector2 = _seguido.global_position
	if _ultimo_ponto == Vector2.INF:
		_ultimo_ponto = agora
	var passo: Vector2 = agora - _ultimo_ponto
	_ultimo_ponto = agora
	# O servidor de física publica a posição nova um passo depois de ela ser
	# escrita, então a travessia da borda chega aqui como um salto. Ignorar o
	# quadro mantém a antecipação intacta, que é o que faz a costura sumir.
	if passo.length() > SALTO_DE_BORDA:
		return
	var velocidade: Vector2 = passo / delta
	var pedido: Vector2 = (velocidade * antecipacao).limit_length(antecipacao_maxima)
	# Suavizar: sem isto um toque de propulsor sacode a câmera inteira.
	_a_frente = _a_frente.lerp(pedido, clampf(delta * 3.0, 0.0, 1.0))


func _aplicar(delta: float) -> void:
	var escala: float = lerpf(zoom_na_superficie, zoom_no_espaco, _fora)
	zoom = Vector2(escala, escala)
	if _seguido == null:
		return
	# Perto: a nave manda, mas só dentro do que o lugar deixa ver. Longe: a nave
	# manda inteira, com um pouco de antecipação.
	var perto: Vector2 = _seguido.global_position.clamp(_limites.position, _limites.end)
	var longe: Vector2 = _seguido.global_position + _a_frente
	var alvo: Vector2 = perto.lerp(longe, _fora)
	if _suave == Vector2.INF:
		_suave = alvo
	elif _alvo_anterior != Vector2.INF and alvo.distance_to(_alvo_anterior) > SALTO_DE_BORDA:
		# A nave cruzou a borda do sistema e o alvo pulou o tamanho do espaço. O
		# ponto suavizado anda o mesmo salto, e o atraso que a câmera tinha continua
		# igual: do lado de cá da borda, nada mudou na imagem. O salto é lido aqui,
		# no quadro em que aparece, porque o servidor de física só publica a posição
		# nova da nave um passo depois da volta.
		_suave += alvo - _alvo_anterior
	_alvo_anterior = alvo
	_suave = _suave.lerp(alvo, clampf(suavizacao * delta, 0.0, 1.0))
	global_position = _suave
