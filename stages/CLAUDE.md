# stages/ — CLAUDE.md local

Tudo aqui é "pai" do player na scene tree: as fases/áreas/mapas exploráveis.

O jogo tem duas vistas (seção 1 do conceito), e as duas são fases daqui: a região de superfície de um planeta, com gravidade e terreno, e o espaço, com a câmera afastada e `Nave.gravidade` em 0. A receita de terreno abaixo vale para as fases de superfície; a fase de espaço não tem crosta nem estratos e monta o próprio fundo.

- Geração procedural ou handmade de cada mapa mora dentro da pasta da própria fase.
- **Arte se decide na hora de desenhar, não na hora que dói.** Antes de criar o sprite, pergunte se ele é assinatura daquele planeta (corpo celeste do fundo, marco construído, silhueta característica) ou vocabulário do jogo (grão de rocha, estrela, poeira, pedra solta). Assinatura vai na `art/` da fase; vocabulário nasce já em `stages/art/`. Ver `stages/art/CLAUDE.md`.
- Uma região se lê em camadas, do fundo para a frente. A receita completa está em "Como se constrói um terreno", no fim deste arquivo — **leia antes de montar ou revisar qualquer superfície**.
- Material usado por mais de uma fase mora em `stages/art/`, nunca duplicado por fase. **Não existe `TileSet` neste projeto:** o terreno se monta por polígono e linha derivados do `perfil`, pela receita abaixo. Se um dia existir um, ele é dado e vai em `stages/data/`.
- Algoritmo de geração genérico e reaproveitável em outro projeto (ruído, pathfinding etc.) vive em `common/`, não aqui — aqui fica só como esse jogo específico usa esse algoritmo pra montar as fases.

**Conceito:** seção 7 de `docs/conceito-de-jogo.md`. Superfícies são regiões locais, não planetas inteiros — e o mundo lembra (seção 8): ponto de coleta esgotado, carga deixada para trás, contrato e créditos permanecem. Cada planeta tem uma região e um objetivo só: pousar no ponto de coleta do recurso dele.

## Como se constrói um terreno

Leia esta seção inteira antes de montar uma superfície nova ou mexer numa existente. Ela é a diferença entre cenário de protótipo e cenário acabado, e cada regra aqui foi paga com uma versão feia antes.

### O princípio

**Arte se lê em três escalas: silhueta, forma média e grão.** A silhueta é o que você reconhece de olhos semicerrados. A forma média é o que dá volume. O grão é textura.

Quase todo terreno amador tem silhueta e grão e **nada no meio** — e é exatamente por isso que ele parece chapado por mais bonita que a textura seja. Se você só puder fazer uma coisa, faça a forma média.

### As camadas, do fundo para a frente

| # | Camada | Nó | Por quê |
|---|---|---|---|
| 1 | Céu em gradiente | `_draw()` da fase | Cor chapada não tem profundidade |
| 2 | Poeira | `_draw()` | Massa entre o gradiente e as estrelas |
| 3 | Estrelas em aglomerado, três brilhos | `_draw()` | Espalhamento uniforme lê como chuvisco |
| 4 | Neblina no horizonte | `_draw()` | É o que separa "longe" de "pequeno" |
| 5 | Corpo celeste | `Sprite2D` em `Parallax2D` | Marco fixo |
| 6 | Três cristas de fundo, cada uma com fio de luz na aresta | `Polygon2D` + `Relevo.aresta_iluminada` | Polígono chapado é recorte de papel |
| 7 | Marco feito por gente ao longe | `Sprite2D` na crista intermediária | Sem ele a região é gerada, não projetada |
| 8 | Massa do terreno com grão | `Polygon2D` texturizado | Grão, não mancha |
| 9 | **Estratos e fraturas** | `Relevo.estratos`, `Relevo.fraturas` | **A forma média. É esta camada que falta quando o chão parece chapado** |
| 10 | Oclusão sob a crosta | `Relevo.oclusao` | Dá espessura à superfície |
| 11 | Crosta iluminada | `Line2D` + `Relevo.gradiente_de_luz` | A face que o sol pega |
| 12 | Pedras soltas, afundadas alguns px | `Sprite2D` | Escala. Apoiada na linha exata lê como adesivo |

### Use `utilities/relevo.gd`

Tudo da camada 6, 9, 10 e 11 já está pronto lá, derivado do mesmo `perfil` que define visual e colisão. Não reimplemente: chame. Assim o relevo acompanha sozinho qualquer edição do perfil, e o mesmo vocabulário vale para todas as fases.

### Regras que não se negociam

- **A crosta obedece à luz.** Faixa clara de brilho e largura iguais dando a volta na silhueta **não é iluminação, é contorno** — e é o tell mais forte de amadorismo. Face virada para cima e à esquerda recebe banda larga e clara; face virada para a direita quase não recebe nada. `Relevo.gradiente_de_luz` e `Relevo.largura_por_luz` fazem isso a partir da inclinação.
- **A oclusão também obedece à luz.** Sombra é o que uma face iluminada projeta. Banda escura de opacidade igual em toda a volta é o mesmo contorno preto de novo.
- **Estratos são horizontais, nunca paralelos à superfície.** Sedimento assenta na horizontal e a encosta corta ele em ângulo. Banda acompanhando o perfil vira espaguete assim que existe uma encosta íngreme, porque duas bandas vizinhas se cruzam.
- **Recorte tudo contra o polígono da massa** com `Geometry2D.intersect_polygons`. É o que garante que nenhum estrato nem fratura escape para o céu.
- **Contraste baixo no chão.** Ele é massa, não ponto de interesse, e tem que pesar mais que o céu. Rocha mais clara que o fundo faz o terreno flutuar; banda contrastada vira listra de pijama. O que se quer é forma legível, não chão claro.
- **Nada de espaçamento regular.** Estrato, fratura, pedra e ponto do perfil em intervalo constante viram régua. Irregularidade é o que denuncia que aquilo não saiu de um laço.
- **O perfil precisa de pontos.** Uma dúzia de vértices dá quinas de 135° que rocha não tem. Subdivida a cada ~9px com deslocamento de poucos pixels — e **deixe intocado o apoio de cada plataforma**, que ali é jogabilidade, não decoração.
- **Um tile de terreno repete dezenas de vezes.** Qualquer forma reconhecível nele — mancha, veio, fratura — vira papel de parede. O tile carrega só grão fino; as formas grandes vêm das camadas 9 a 11.

### Ordem de trabalho recomendada

1. Perfil com pontos suficientes e irregular.
2. Crosta e oclusão obedecendo à luz. São baratas e consertam a leitura da superfície.
3. Estratos e fraturas. É o trabalho grande e o que mais muda o resultado.
4. Cristas de fundo com fio de luz, e o marco feito por gente.
5. Céu.
6. Pedras.

Depois de cada passo, fotografe e **olhe**: `godot --path . --scene res://tools/screenshot.tscn -- --scene res://stages/<fase>/<fase>.tscn --out shot.png`.

### O grão precisa emendar

O tile de grão da camada 8 repete dezenas de vezes, então uma emenda visível vira grade e denuncia o terreno inteiro. Antes de usar um grão novo, veja ele repetido:

```
.venv/bin/python .claude/skills/pixel-art/scripts/build_sprite.py <arquivo>.pix --tile grade.png
```

Se a costura aparecer na grade, ela vai aparecer no chão.
