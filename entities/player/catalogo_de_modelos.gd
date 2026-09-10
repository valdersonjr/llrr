class_name CatalogoDeModelos
extends Resource
## Quem responde "que modelos de nave existem no jogo".
##
## Uma lista editável no Inspector, não uma constante em código: acrescentar um
## modelo tem que ser duplicar um `.tres`, montar a cena e arrastá-la para cá —
## sem recompilar, sem procurar onde mais o modelo está listado.
##
## Antes disso, só a fase de teste sabia quais modelos existiam, num
## `Array[PackedScene]` dela. Estaleiro, tela de escolha e save
## iam todos precisar da mesma lista, e cada um teria a sua.

@export var modelos: Array[PackedScene] = []


func quantidade() -> int:
	return modelos.size()


## Instancia um modelo pelo índice, dando a volta na lista. Devolve null se o
## catálogo estiver vazio — quem chama decide o que fazer com isso.
func criar(indice: int) -> Nave:
	if modelos.is_empty():
		return null
	var cena := modelos[posmod(indice, modelos.size())]
	return cena.instantiate() as Nave if cena != null else null


## O índice seguinte, dando a volta. Existe para quem cicla não precisar
## conhecer o tamanho da lista.
func seguinte(indice: int) -> int:
	return 0 if modelos.is_empty() else posmod(indice + 1, modelos.size())
