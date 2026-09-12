@tool
class_name CamadaDeTiles
extends TileMapLayer

## Uma camada de tiles montada a partir de um mapa em texto.
##
## Serve tanto ao relevo, que colide, quanto à vegetação, que não colide. O que
## separa as duas é o tileset e o z: o script é o mesmo.
##
## O mapa é a fonte da verdade e mora ao lado da região, num `.txt` de largura
## fixa: um caractere por tile. Editar terreno vira editar arte ASCII, que lê bem
## no diff do git e não exige abrir o editor. Linha começada por `;` é comentário.
##
## A legenda mora na cena e não aqui, porque cada planeta tem o tileset dele. Ela
## é um dicionário de caractere para coordenada de atlas, como `{"#": Vector2i(2, 2)}`.
##
## `@tool` existe para o terreno aparecer também ao abrir a cena no editor.

const FONTE: int = 0

@export_file("*.txt") var mapa: String = ""
@export var legenda: Dictionary[String, Vector2i] = {}


func _ready() -> void:
	montar()


func montar() -> void:
	clear()
	if mapa.is_empty() or legenda.is_empty():
		return

	var texto: String = FileAccess.get_file_as_string(mapa)
	if texto.is_empty():
		push_warning("CamadaDeTiles: mapa vazio ou ilegível em " + mapa)
		return

	var linha: int = 0
	for bruta: String in texto.split("\n", false):
		if bruta.begins_with(";"):
			continue
		for coluna: int in bruta.length():
			var desenho: String = bruta[coluna]
			if legenda.has(desenho):
				set_cell(Vector2i(coluna, linha), FONTE, legenda[desenho])
		linha += 1
