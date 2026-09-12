# entities/

O que é instanciado **dentro** de um lugar. Se a coisa é o lugar, ela mora em `mundo/`.

## As quatro categorias

| Pasta | O teste para entrar | Hoje tem |
|---|---|---|
| `nave/` | é o jogador | a nave, com três modelos previstos |
| `estruturas/` | foi construído e fica parado | plataforma de pouso |
| `carga/` | a nave embarca, larga ou recupera | o esquema `RecursoMineral`, o âmbar bruto e o níquel bruto |
| `obstaculos/` | tem tamanho para o jogador ler como sólido | pedra, asteroide |
| `cenario/` | parece vivo e não faz nada | caracol |

`cenario/` é a categoria que mais convida gambiarra, então a regra é dura e vem da seção 10 do conceito. Cenário **nunca** vira tarefa, **nunca** disputa leitura com o lugar de pouso e **nunca** entra no save, porque vive na cena da região e morre com ela. No instante em que uma das três cair, aquilo deixou de ser cenário.

Foi exatamente o que aconteceu com as pedras grandes de Arvo. Elas nasceram como enfeite, mas têm tamanho para o jogador ler como sólidas, e o que parece sólido e não é vira armadilha. Viraram `obstaculos/pedra`, com colisão tirada do alfa da própria arte para forma e desenho nunca discordarem. A pedra baixa continua em `cenario/`, porque é detalhe de chão e ninguém espera bater nela.

`obstaculos/` já tem duas entidades e ganhou o `CLAUDE.md` dela. `estruturas/` e `cenario/` ainda não pedem: têm uma entidade cada e o que há para dizer cabe nesta tabela. Quando a segunda entrar, a pasta ganha o dela.

## Esquema e instância

O script de um `Resource` fica no nível da categoria; os `.tres` que o instanciam ficam num `data/` abaixo. `entities/carga/recurso_mineral.gd` é o esquema, `entities/carga/data/ambar_bruto.tres` é um mineral concreto.

## Quem marca o ponto de coleta

A plataforma não tem script. Ela é um `StaticBody2D` no grupo `pontos_de_coleta`, na camada de colisão 3, com duas balizas acesas de luz própria, e é esse grupo que a nave consulta para saber se encostou no lugar demarcado ou só no chão. Encostar no terreno não é pousar.
