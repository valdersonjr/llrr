extends Node
## Relógio de campanha. Autoload.
##
## Seção 8 do conceito: existe um relógio de campanha, e ele **só avança com o
## jogo aberto**. Nada acontece enquanto o jogo está fechado — não há progresso
## em tempo real, não há colheita esperando. Por isso ele é um contador simples
## que soma delta, e não uma diferença contra o relógio do sistema.
##
## Ele também para em menu e em pausa, porque a mesma seção 6 promete que
## inspecionar a situação com o jogo pausado não é punido. `PROCESS_MODE_PAUSABLE`
## resolve isso sozinho.

signal avancou(segundos: float)
signal virou_o_dia(dia: int)

## Quantos segundos de campanha passam por segundo real durante voo. Hipótese
## de trabalho, como as quantidades do conceito: ajuste jogando, não no papel.
const SEGUNDOS_POR_SEGUNDO_REAL := 30.0
const SEGUNDOS_POR_DIA := 86400.0

var segundos: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(delta: float) -> void:
	avancar(delta * SEGUNDOS_POR_SEGUNDO_REAL)


## Salta o relógio à frente. É o que serviço de porto e cruzeiro usam: a
## duração é cobrada de uma vez, não esperada em tempo real.
func avancar(quanto: float) -> void:
	if quanto <= 0.0:
		return
	var antes := dia()
	segundos += quanto
	avancou.emit(quanto)
	if dia() != antes:
		virou_o_dia.emit(dia())


func dia() -> int:
	return int(segundos / SEGUNDOS_POR_DIA) + 1


## "D1 06:20" — dia e hora do relógio de campanha.
func como_texto() -> String:
	var do_dia := fmod(segundos, SEGUNDOS_POR_DIA)
	return "D%d %02d:%02d" % [dia(), int(do_dia / 3600.0), int(fmod(do_dia / 60.0, 60.0))]


## Quanto tempo de campanha um serviço de porto leva, dado o que ele restaura.
## Encapsulado aqui porque é o relógio quem sabe o que "demorado" significa.
func duracao_de_servico(fracao_de_casco: float, toneladas: float) -> float:
	return fracao_de_casco * 6.0 * 3600.0 + toneladas * 900.0
