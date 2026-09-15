extends Node

## Aplica e guarda as opções do jogador. É autoload (`ConfiguracoesManager`)
## porque a opção vale do primeiro quadro ao último, no menu e no jogo.
##
## O arquivo é um `ConfigFile` em `user://`, e não um `.tres`: carregar um recurso
## escrito fora do jogo executaria o script que viesse dentro dele. O formato dos
## valores continua sendo o recurso `Configuracoes`.

const ARQUIVO_PADRAO: String = "user://configuracoes.cfg"
const BASE: Vector2i = Vector2i(640, 360)

## Onde as opções são guardadas. Só a conferência troca, para não sobrescrever as
## opções de quem joga.
var arquivo: String = ARQUIVO_PADRAO
var atuais: Configuracoes = Configuracoes.new()


func _ready() -> void:
	carregar()
	aplicar()


func carregar() -> void:
	atuais = Configuracoes.new()
	var cfg := ConfigFile.new()
	if cfg.load(arquivo) != OK:
		return
	atuais.volume_geral = clampf(float(cfg.get_value("audio", "geral", atuais.volume_geral)), 0.0, 1.0)
	atuais.volume_da_musica = clampf(float(cfg.get_value("audio", "musica", atuais.volume_da_musica)), 0.0, 1.0)
	atuais.volume_dos_efeitos = clampf(float(cfg.get_value("audio", "efeitos", atuais.volume_dos_efeitos)), 0.0, 1.0)
	atuais.tela_cheia = bool(cfg.get_value("tela", "cheia", atuais.tela_cheia))
	atuais.escala = clampi(int(cfg.get_value("tela", "escala", atuais.escala)), 2, 4)


func salvar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "geral", atuais.volume_geral)
	cfg.set_value("audio", "musica", atuais.volume_da_musica)
	cfg.set_value("audio", "efeitos", atuais.volume_dos_efeitos)
	cfg.set_value("tela", "cheia", atuais.tela_cheia)
	cfg.set_value("tela", "escala", atuais.escala)
	var erro: int = cfg.save(arquivo)
	if erro != OK:
		push_warning("não guardei as opções em %s (erro %d)" % [arquivo, erro])


func aplicar() -> void:
	_volume("Master", atuais.volume_geral)
	_volume("Musica", atuais.volume_da_musica)
	_volume("Efeitos", atuais.volume_dos_efeitos)
	# Sem janela, como nas conferências em headless, não há tela para mudar.
	if DisplayServer.get_name() == "headless":
		return
	if atuais.tela_cheia:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var tamanho: Vector2i = BASE * atuais.escala
	DisplayServer.window_set_size(tamanho)
	var monitor: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_position(monitor.position + (monitor.size - tamanho) / 2)


## Volume zero é mudo de verdade, e não o decibel mais baixo que a conta alcança.
func _volume(barramento: String, valor: float) -> void:
	var indice: int = AudioServer.get_bus_index(barramento)
	if indice < 0:
		return
	AudioServer.set_bus_mute(indice, valor <= 0.0)
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(valor, 0.0001)))
