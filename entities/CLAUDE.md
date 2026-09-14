# entities/

O que é instanciado **dentro** de um lugar. Se a coisa é o lugar, ela mora em `mundo/`.

## As quatro categorias

| Pasta | O teste para entrar | Hoje tem |
|---|---|---|
| `nave/` | é o jogador | a nave, com três modelos previstos |
| `estruturas/` | foi construído e fica parado | ponto de coleta, saloon, sinal de pouso |
| `carga/` | a nave embarca, larga ou recupera | o esquema `RecursoMineral` e o âmbar, recurso de Arvo |
| `obstaculos/` | tem tamanho para o jogador ler como sólido | nada hoje |
| `cenario/` | parece vivo e não faz nada | xerife, dono do saloon, cowboy, arbusto seco |

`cenario/` é a categoria que mais convida gambiarra, então a regra é dura e vem da seção 10 do conceito. Cenário **nunca** vira tarefa, **nunca** disputa leitura com o lugar de pouso e **nunca** entra no save, porque vive na cena da região e morre com ela. No instante em que uma das três cair, aquilo deixou de ser cenário.

`estruturas/` e `cenario/` também ganharam o `CLAUDE.md` delas, com o saloon, o sinal de pouso e os personagens do Outpost. `obstaculos/` foi apagada em 2026-09-14 junto com a pedra e o asteroide, e volta com o primeiro obstáculo de um lugar novo.

O dono do saloon está em `cenario/` porque hoje não faz nada. No dia em que ele emitir contrato, deixa de ser cenário e muda de pasta, como diz a regra acima.

## Esquema e instância

O script de um `Resource` fica no nível da categoria; os `.tres` que o instanciam ficam num `data/` abaixo. `entities/carga/recurso_mineral.gd` é o esquema, `entities/carga/data/ambar_bruto.tres` é um mineral concreto.

## Quem marca o ponto de coleta

`ponto_de_coleta` é um `StaticBody2D` no grupo `pontos_de_coleta`, na camada de colisão 3, e é esse grupo que a nave consulta para saber se encostou no lugar demarcado ou só no chão. Encostar no terreno não é pousar.

**Ele não tem arte própria.** A seção 10 do conceito diz que a demarcação é conteúdo autoral, feito para cada situação, e que ela nem sempre é uma plataforma. Então a cena não traz textura nenhuma: cada lugar aponta as suas na instância, e o script monta as balizas, a marca no chão e a colisão a partir da `largura` declarada. No Outpost de Arvo é um deque sobre palafitas com sinal luminoso; em outro lugar podem ser postes, uma boca de mina ou um pátio de carga.

Duas coisas que o desenho garante, porque o conceito as cobra:

- **a baliza fica fora da largura**, encostada nela. Se invadir o lugar de pouso, a distância entre as duas deixa de informar quanta margem existe.
- **a luz responde ao estado**: esperando, no contato, e pousada. Quem avisa é a nave, por sinal, e quem repassa é a cena do sistema, porque uma região não conhece a nave.

`largura` é o botão de dificuldade que a seção 10 chama de tamanho do lugar de pouso. A nave tem 26 pixels: 68 perdoa, 34 aperta.

