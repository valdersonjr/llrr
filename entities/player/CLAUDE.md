# entities/player/ — CLAUDE.md local

A nave do jogador: um script de comportamento, um recurso de dados, uma pasta-folha por casco.

## Padrão dos cascos

- `nave.gd` (`class_name Nave`) — todo o comportamento de voo. É o script que a cena de cada casco usa.
- `casco.gd` (`class_name Casco`) — o recurso com os números: massa, empuxo, consumo, tolerância do trem de pouso.
- `<casco>/` — pasta-folha com `art/`, `data/<casco>.tres` e a cena, no formato da raiz.

Os três cascos previstos (utilitário leve, cargueiro resistente, interceptador) diferem por `.tres`, não por código — por isso a cena do casco **não** tem script próprio, ela aponta para `nave.gd` e carrega o seu `Casco`. Só crie `<casco>.gd extends Nave` quando o casco tiver comportamento que a base não tem. Número diferente não é comportamento diferente.

## Decisões que o código não explica sozinho

| Decisão | Por quê |
|---|---|
| `CharacterBody2D` com integração manual, não `RigidBody2D` | O desfecho do contato é autoral — raspão, perna quebrada e impacto frontal são coisas diferentes (seção 4). Escrever a regra é mais direto, e muito mais fácil de depurar, que calibrar atrito e restituição de corpo rígido. |
| O "para frente" da nave é `Vector2.UP` | `rotation == 0` é a nave em pé, como o sprite é desenhado. Não existe offset de -90° na cena. |
| O atrito de apoio roda **depois** de `move_and_slide()` | Os raycasts das pernas enxergam o chão alguns pixels antes do toque. Usá-los antes do movimento zerava a descida antes de a colisão existir, e nenhum pouso chegava a ser rápido o bastante para causar dano. |
| A gravidade vem da região, não da nave | Cada corpo celeste tem a sua (seção 7). `Nave.gravidade` começa em 0 — vácuo — e quem a define é a fase. |
| Perder o foco da janela solta os comandos | Seção 6 promete que voltar de uma suspensão nunca deixa o propulsor travado ligado. Só zerar as variáveis não basta: o SO pode continuar reportando a tecla presa, então `soltar_comandos()` também chama `Input.action_release`. |
| O casco tem três texturas, não uma | `texturas_de_dano` vem da cena do casco e `Nave` troca conforme a integridade (íntegro > 60%, degradado > 25%, crítico abaixo). Perder casco tem que aparecer na nave, não só na barra — é a seção 2, consequência legível. |
| O dano do contato é uma regra só | A tolerância do trem de pouso encolhe conforme o desalinhamento: "você bateu rápido demais para o ângulo em que estava". Encostar torto devagar não quebra nada. |

## Camadas de física

| Camada | Quem |
|---|---|
| 1 `terreno` | terreno das fases e plataformas |
| 2 `naves` | nave do jogador, e as inimigas quando existirem |

A nave é camada 2 e só enxerga a 1. É isso que impede os raycasts das pernas de acertarem o próprio casco.

**Conceito:** seções 4 (pilotagem), 5 (nave, módulos e dano) e 10 (combate). Os critérios de aceitação do voo estão no fim da seção 4 e viraram cenários executáveis em `tools/voo_check.gd` — rode antes e depois de mexer na física.
