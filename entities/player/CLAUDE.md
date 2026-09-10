# entities/player/ — CLAUDE.md local

A nave do jogador: um script de comportamento, um de apresentação, um recurso de dados, um catálogo que os junta, e uma pasta-folha por modelo.

## Padrão dos modelos

- `nave.gd` (`class_name Nave`) — todo o comportamento de voo. É o script que a cena de cada modelo usa.
- `modelo.gd` (`class_name Modelo`) — o recurso com os números: massa, empuxo, torque, tolerância do trem de pouso.
- `<modelo>/` — pasta-folha com `art/`, `data/<modelo>.tres` e a cena, no formato da raiz.

Os três modelos (utilitário leve, cargueiro resistente, interceptador) diferem por `.tres` e por cena, não por código — nenhum tem script próprio, todos apontam para `nave.gd`. Só crie `<modelo>.gd extends Nave` quando o modelo tiver comportamento que a base não tem. Número diferente não é comportamento diferente.

O que muda de cena para cena: o sprite, a colisão, quantos bocais, e `altura_dos_pes`, que é como quem posiciona a nave sabe onde está a sola.

## A família de formas

As três silhuetas foram desenhadas juntas e julgadas em preto, que é o único jeito de garantir que se distinguem:

| Modelo | Mancha |
|---|---|
| Utilitário leve | quadro aberto, com dois vazios laterais |
| Cargueiro resistente | laje maciça e fechada, dois bocais |
| Interceptador | cunha estreita com asas em flecha |

Modelo novo entra comparando a mancha preta dele com essas três, não desenhando bonito sozinho.

**Cada modelo tem uma textura só.** Não existe estado de casco: a seção 5 do conceito removeu o dano, então a nave tem a mesma aparência do começo ao fim de uma partida.

## Por que dado, e não uma subclasse por modelo

A pergunta aparece sempre: "não deveria haver uma interface `Nave` e um tipo por modelo?" O papel dessa interface já existe, e é o **`Modelo`** — o `Resource` que define o contrato que todo modelo preenche. O que não existe, de propósito, é uma subclasse por modelo.

| | Subclasse por modelo | Como está |
|---|---|---|
| Modelo novo | escrever classe, compilar, registrar | duplicar um `.tres`, digitar números no Inspector |
| Ajustar peso | editar código, compilar, rodar | arrastar um slider com o jogo aberto |
| Quem ajusta | quem programa | quem projeta o jogo |
| Modelo × módulo | uma classe por combinação | duas listas que se combinam |

Uma subclasse cujo corpo inteiro é constante não faz nada: ela só embrulha números em sintaxe mais cara de mudar. E o conceito prevê 18–24 módulos além dos três modelos — inheritance não expressa combinação, ela multiplica classes.

**A regra:** `<modelo>.gd extends Nave` só quando o modelo tiver **comportamento** que a base não tem. Número diferente não é comportamento diferente. No dia em que um modelo precisar, por exemplo, de dois estágios de propulsão, aí sim ele ganha script.

`catalogo_de_modelos.gd` é a fábrica: quem responde "que modelos existem" e sabe instanciá-los. A lista mora num `.tres`, então acrescentar um modelo não recompila nada nem exige lembrar de atualizá-lo em dois lugares.

## Simulação e apresentação são classes diferentes

`nave.gd` simula: inércia, massa, carga, contato, avaliação de pouso.
`apresentacao_da_nave.gd` desenha: chama e luz do motor.

O fluxo é de mão única — a nave manda, a apresentação desenha. A apresentação **não** conhece `Nave`, não lê o pai, e recebe só o empuxo aplicado. Por isso dá para trocá-la sem tocar em física, e por isso sopro de manobra e alerta de cabine vão para lá, não para dentro do código de voo.

Cada cena de modelo tem o seu nó `Apresentacao` com as texturas dele.

## Decisões que o código não explica sozinho

| Decisão | Por quê |
|---|---|
| `CharacterBody2D` com integração manual, não `RigidBody2D` | O que conta como pouso assentado é regra autoral (seção 4). Escrever a regra é mais direto, e muito mais fácil de depurar, que calibrar atrito e restituição de corpo rígido. |
| O "para frente" da nave é `Vector2.UP` | `rotation == 0` é a nave em pé, como o sprite é desenhado. Não existe offset de -90° na cena. |
| O atrito de apoio roda **depois** de `move_and_slide()` | Os raycasts das pernas enxergam o chão alguns pixels antes do toque. Usá-los antes do movimento zerava a descida antes de a colisão existir, e nenhum pouso chegava a ser rápido o bastante para ser avaliado. |
| A gravidade vem da região, não da nave | Cada corpo celeste tem a sua (seção 7). `Nave.gravidade` começa em 0 — vácuo — e quem a define é a fase. É isto que faz a mesma nave servir às duas vistas: no espaço a fase deixa a gravidade em 0. |
| Perder o foco da janela solta os comandos | Seção 6 promete que voltar de uma suspensão nunca deixa o propulsor travado ligado. Só zerar as variáveis não basta: o SO pode continuar reportando a tecla presa, então `soltar_comandos()` também chama `Input.action_release`. |
| Voar não consome nada | Não existe combustível (seção 4). O empuxo está sempre disponível, e a massa é só a nave vazia mais a carga. Não reintroduza tanque, consumo nem `abastecer()`: a decisão está registrada, e a pergunta do que substitui isso está na seção 18. |
| A nave não tem dano | Não existe integridade, estado de casco nem estado destruído (seção 5). As tolerâncias do trem de pouso em `Modelo` continuam existindo, mas hoje só alimentam o alerta do HUD: nenhum pouso quebra nada. Não reintroduza barra de estrutura nem sprite de casco amassado. |

## Camadas de física

| Camada | Quem |
|---|---|
| 1 `terreno` | terreno das fases e plataformas |
| 2 `naves` | nave do jogador |

A nave é camada 2 e só enxerga a 1. É isso que impede os raycasts das pernas de acertarem o próprio casco.

**Conceito:** seções 4 (pilotagem), 5 (nave e módulos) e 10 (o pouso e o ponto de coleta). Os critérios de aceitação do voo estão no fim da seção 4 e viraram cenários executáveis em `tools/voo_check.gd` — rode antes e depois de mexer na física.
