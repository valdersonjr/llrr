class_name CatalogoDeCascos
extends Resource
## Quem responde "que cascos existem no jogo".
##
## Uma lista editável no Inspector, não uma constante em código: acrescentar um
## casco tem que ser duplicar um `.tres`, montar a cena e arrastá-la para cá —
## sem recompilar, sem procurar onde mais o casco está listado.
##
## Antes disso, só a fase de teste sabia quais cascos existiam, num
## `Array[PackedScene]` dela. Estaleiro, tela de escolha, save e nave inimiga
## iam todos precisar da mesma lista, e cada um teria a sua.

@export var cascos: Array[PackedScene] = []


func quantidade() -> int:
	return cascos.size()


## Instancia um casco pelo índice, dando a volta na lista. Devolve null se o
## catálogo estiver vazio — quem chama decide o que fazer com isso.
func criar(indice: int) -> Nave:
	if cascos.is_empty():
		return null
	var cena := cascos[posmod(indice, cascos.size())]
	return cena.instantiate() as Nave if cena != null else null


## O índice seguinte, dando a volta. Existe para quem cicla não precisar
## conhecer o tamanho da lista.
func seguinte(indice: int) -> int:
	return 0 if cascos.is_empty() else posmod(indice + 1, cascos.size())
