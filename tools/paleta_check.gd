extends Node

## Ferramenta de dev: confere se a arte do jogo está na paleta do projeto.
##
##   godot --headless --path . --scene res://tools/paleta_check.tscn
##
## A regra está no `CLAUDE.md` da raiz e a lista em `docs/paleta.md`: toda cor
## do jogo sai da Resurrect 64, e nada fora dela. Cor fora da paleta não dá erro
## em lugar nenhum, não trava nada e não aparece em revisão de código: ela só
## aparece na tela, tarde, quando já existe conteúdo demais para refazer.
##
## **A lista de exceções é a lista de tarefas.** O que está nela é arte de
## terceiros ou protótipo declarado, e sai de lá quando for convertido ou
## substituído. Nada entra nela sem esse compromisso.

const PALETA: PackedStringArray = [
	"2e222f", "3e3546", "625565", "966c6c", "ab947a",
	"694f62", "7f708a", "9babb2", "c7dcd0", "ffffff",
	"6e2727", "b33831", "ea4f36", "f57d4a",
	"ae2334", "e83b3b", "fb6b1d", "f79617", "f9c22b",
	"7a3045", "9e4539", "cd683d", "e6904e", "fbb954",
	"4c3e24", "676633", "a2a947", "d5e04b", "fbff86",
	"165a4c", "239063", "1ebc73", "91db69", "cddf6c",
	"313638", "374e4a", "547e64", "92a984", "b2ba90",
	"0b5e65", "0b8a8f", "0eaf9b", "30e1b9", "8ff8e2",
	"323353", "484a77", "4d65b4", "4d9be6", "8fd3ff",
	"45293f", "6b3e75", "905ea9", "a884f3", "eaaded",
	"753c54", "a24b6f", "cf657f", "ed8099",
	"831c5d", "c32454", "f04f78", "f68181", "fca790", "fdcbb0",
]

## Arte que ainda não está na paleta e tem motivo declarado. Cada linha é uma
## dívida, não uma permissão.
const PERDOADOS: Dictionary = {
	"res://entities/nave/art/": "arte antiga da nave, anterior à paleta",
	"res://ui/art/": "moldura do painel, placeholder declarado",
}

## Abaixo disto, a diferença é de arredondamento de importador, não de escolha.
const TOLERANCIA: float = 0.02

var _falhas: int = 0
var _paleta: Dictionary = {}


func _ready() -> void:
	for cor: String in PALETA:
		_paleta[cor.hex_to_int()] = true

	print("--- conferência de paleta: %d cores ---" % PALETA.size())
	var arquivos: PackedStringArray = []
	_procurar("res://", arquivos)
	arquivos.sort()

	var limpos: int = 0
	var perdoados: int = 0
	var de_fora: int = 0
	for caminho: String in arquivos:
		var fora: float = _quanto_esta_fora(caminho)
		if fora < 0.0:
			# Não importado: não está no jogo, então não é assunto desta conferência.
			de_fora += 1
			continue
		if fora <= TOLERANCIA:
			limpos += 1
			continue
		var motivo: String = _motivo(caminho)
		if motivo.is_empty():
			print("  [FORA] %5.1f%%  %s" % [fora, caminho.trim_prefix("res://")])
			_falhas += 1
		else:
			perdoados += 1

	print("  na paleta:           %d arquivo(s)" % limpos)
	print("  fora do jogo:        %d arquivo(s) não importados, ignorados" % de_fora)
	print("  perdoados:           %d arquivo(s), por %d motivos declarados" % [
		perdoados, PERDOADOS.size()
	])
	print("--- %s ---" % (
		"tudo na paleta" if _falhas == 0
		else "%d arquivo(s) fora da paleta e sem motivo" % _falhas
	))
	get_tree().quit(_falhas)


func _procurar(pasta: String, achados: PackedStringArray) -> void:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	dir.list_dir_begin()
	var nome: String = dir.get_next()
	while nome != "":
		var caminho: String = pasta.path_join(nome)
		if dir.current_is_dir():
			# Pasta com .gdignore está fora do jogo, e tentar carregar o que há
			# dentro dela só enche o relatório de erro de carregamento.
			if not nome.begins_with(".") and not FileAccess.file_exists(caminho.path_join(".gdignore")):
				_procurar(caminho, achados)
		elif nome.get_extension().to_lower() == "png":
			achados.append(caminho)
		nome = dir.get_next()
	dir.list_dir_end()


func _motivo(caminho: String) -> String:
	for prefixo: String in PERDOADOS:
		if caminho.begins_with(prefixo):
			return PERDOADOS[prefixo]
	return ""


## Quanto do que se vê está fora da paleta, em porcentagem. Pixel transparente
## não conta: ele não aparece na tela. Devolve -1 para o que o Godot não importou,
## porque isso não está no jogo.
func _quanto_esta_fora(caminho: String) -> float:
	var recurso: Resource = load(caminho)
	if recurso == null or not recurso is Texture2D:
		return -1.0
	var imagem: Image = (recurso as Texture2D).get_image()
	if imagem == null:
		return -1.0
	imagem.convert(Image.FORMAT_RGBA8)
	var bytes: PackedByteArray = imagem.get_data()
	var visiveis: int = 0
	var fora: int = 0
	var i: int = 0
	while i < bytes.size():
		if bytes[i + 3] > 8:
			visiveis += 1
			var cor: int = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2]
			if not _paleta.has(cor):
				fora += 1
		i += 4
	if visiveis == 0:
		return 0.0
	return 100.0 * float(fora) / float(visiveis)
