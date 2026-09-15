class_name Configuracoes
extends Resource

## As opções do jogador: volumes e tela. Este recurso descreve os valores; quem
## aplica e guarda é o `ConfiguracoesManager`.

@export_range(0.0, 1.0, 0.1) var volume_geral: float = 1.0
@export_range(0.0, 1.0, 0.1) var volume_da_musica: float = 0.8
@export_range(0.0, 1.0, 0.1) var volume_dos_efeitos: float = 1.0
@export var tela_cheia: bool = false
## Quantas vezes a tela base de 640x360 é ampliada na janela. Sempre inteiro, pelo
## mesmo motivo de toda a pixel art: escala quebrada borra. Em tela cheia vale a
## maior escala inteira que cabe no monitor, e este número não é usado.
@export_range(2, 4) var escala: int = 2
