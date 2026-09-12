class_name RecursoMineral
extends Resource

## O que um contrato pede e o que o porão carrega. É massa e valor: a massa é o
## que liga economia e pilotagem, porque aceitar carga grande é decolar pesado.
## Ver a seção 12 do conceito.
##
## O nome não é `Recurso` de propósito. Num código em português isso se confunde
## com o `Resource` do próprio Godot.

@export var nome: String = ""
@export_multiline var descricao: String = ""
@export var massa_por_unidade: float = 1.0
@export var valor_por_unidade: int = 1
@export var cor: Color = Color.WHITE
