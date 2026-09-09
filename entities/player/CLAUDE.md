# entities/player/ — CLAUDE.md local

A nave do jogador: um script de comportamento, um recurso de dados, uma pasta-folha por casco.

## Padrão dos cascos

- `nave.gd` (`class_name Nave`) — todo o comportamento de voo. É o script que a cena de cada casco usa.
- `casco.gd` (`class_name Casco`) — o recurso com os números: massa, empuxo, consumo, tolerância do trem de pouso.
- `<casco>/` — pasta-folha com `art/`, `data/<casco>.tres` e a cena, no formato da raiz.

Os três cascos (utilitário leve, cargueiro resistente, interceptador) diferem por `.tres` e por cena, não por código — nenhum tem script próprio, todos apontam para `nave.gd`. Só crie `<casco>.gd extends Nave` quando o casco tiver comportamento que a base não tem. Número diferente não é comportamento diferente.

O que muda de cena para cena: o sprite, a colisão, quantos bocais, e `altura_dos_pes`, que é como quem posiciona a nave sabe onde está a sola.

## A família de formas

As três silhuetas foram desenhadas juntas e julgadas em preto, que é o único jeito de garantir que se distinguem:

| Casco | Mancha |
|---|---|
| Utilitário leve | quadro aberto, com dois vazios laterais |
| Cargueiro resistente | laje maciça e fechada, dois bocais |
| Interceptador | cunha estreita com asas em flecha |

Casco novo entra comparando a mancha preta dele com essas três, não desenhando bonito sozinho.

**Estados de dano são opcionais por casco.** Quem não tiver as três texturas em `texturas_de_dano` simplesmente não muda de aparência — `_atualizar_casco()` sai fora quando o índice não existe. Hoje só o utilitário leve tem os três.

## Por que dado, e não uma subclasse por casco

A pergunta aparece sempre: "não deveria haver uma interface `Nave` e um tipo por casco?" O papel dessa interface já existe, e é o **`Casco`** — o `Resource` que define o contrato que todo casco preenche. O que não existe, de propósito, é uma subclasse por casco.

| | Subclasse por casco | Como está |
|---|---|---|
| Casco novo | escrever classe, compilar, registrar | duplicar um `.tres`, digitar números no Inspector |
| Ajustar peso | editar código, compilar, rodar | arrastar um slider com o jogo aberto |
| Quem ajusta | quem programa | quem projeta o jogo |
| Casco × módulo | uma classe por combinação | duas listas que se combinam |

Uma subclasse cujo corpo inteiro é constante não faz nada: ela só embrulha números em sintaxe mais cara de mudar. E o conceito prevê 18–24 módulos além dos três cascos — inheritance não expressa combinação, ela multiplica classes.

**A regra:** `<casco>.gd extends Nave` só quando o casco tiver **comportamento** que a base não tem. Número diferente não é comportamento diferente. No dia em que um casco precisar, por exemplo, de dois estágios de propulsão, aí sim ele ganha script.

`catalogo_de_cascos.gd` é a fábrica: quem responde "que cascos existem" e sabe instanciá-los. A lista mora num `.tres`, então acrescentar um casco não recompila nada nem exige lembrar de atualizá-lo em dois lugares.

## Simulação e apresentação são classes diferentes

`nave.gd` simula: inércia, massa, combustível, contato, avaliação de pouso.
`apresentacao_da_nave.gd` desenha: chama, textura de dano, luz do motor.

O fluxo é de mão única — a nave manda, a apresentação desenha. A apresentação **não** conhece `Nave`, não lê o pai, e recebe só o empuxo aplicado e o estado de dano. Por isso dá para trocá-la sem tocar em física, e por isso partícula de dano, sopro de manobra e alerta de cabine vão para lá, não para dentro do código de voo.

Cada cena de casco tem o seu nó `Apresentacao` com as texturas dele.

## Decisões que o código não explica sozinho

| Decisão | Por quê |
|---|---|
| `CharacterBody2D` com integração manual, não `RigidBody2D` | O desfecho do contato é autoral — raspão, perna quebrada e impacto frontal são coisas diferentes (seção 4). Escrever a regra é mais direto, e muito mais fácil de depurar, que calibrar atrito e restituição de corpo rígido. |
| O "para frente" da nave é `Vector2.UP` | `rotation == 0` é a nave em pé, como o sprite é desenhado. Não existe offset de -90° na cena. |
| O atrito de apoio roda **depois** de `move_and_slide()` | Os raycasts das pernas enxergam o chão alguns pixels antes do toque. Usá-los antes do movimento zerava a descida antes de a colisão existir, e nenhum pouso chegava a ser rápido o bastante para causar dano. |
| A gravidade vem da região, não da nave | Cada corpo celeste tem a sua (seção 7). `Nave.gravidade` começa em 0 — vácuo — e quem a define é a fase. |
| Perder o foco da janela solta os comandos | Seção 6 promete que voltar de uma suspensão nunca deixa o propulsor travado ligado. Só zerar as variáveis não basta: o SO pode continuar reportando a tecla presa, então `soltar_comandos()` também chama `Input.action_release`. |
| Atribuir `integridade` atualiza o sprite sozinho | É propriedade com setter, não campo solto. Antes cabia a quem escrevia lembrar de pedir a atualização, e quem esquecesse ficava com casco intacto na tela e destruído nos números. |
| Quem lê pergunta a fração, não os dois números | `integridade_fracao()`, `combustivel_fracao()` e `intacta()` existem para HUD, fase e harness não repetirem `x / casco.maximo` em doze lugares. |
| O casco tem três texturas, não uma | `texturas_de_dano` vem da cena do casco e `Nave` troca conforme a integridade (íntegro > 60%, degradado > 25%, crítico abaixo). Perder casco tem que aparecer na nave, não só na barra — é a seção 2, consequência legível. |
| O dano do contato é uma regra só | A tolerância do trem de pouso encolhe conforme o desalinhamento: "você bateu rápido demais para o ângulo em que estava". Encostar torto devagar não quebra nada. |

## Camadas de física

| Camada | Quem |
|---|---|
| 1 `terreno` | terreno das fases e plataformas |
| 2 `naves` | nave do jogador, e as inimigas quando existirem |

A nave é camada 2 e só enxerga a 1. É isso que impede os raycasts das pernas de acertarem o próprio casco.

**Conceito:** seções 4 (pilotagem), 5 (nave, módulos e dano) e 10 (combate). Os critérios de aceitação do voo estão no fim da seção 4 e viraram cenários executáveis em `tools/voo_check.gd` — rode antes e depois de mexer na física.
