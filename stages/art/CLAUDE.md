# stages/art/ — CLAUDE.md local

Arte que serve **a categoria `stages/` inteira**, e não a uma fase só: o vocabulário visual que se repete de superfície em superfície.

É a mesma regra de pasta-folha da raiz que já vale para os modelos da nave, cuja chama de motor mora em `entities/player/art/`. Aqui não há exceção nenhuma, só a aplicação dela a `stages/`.

## O que entra

Material que é vocabulário do jogo, não assinatura de um planeta:

- grão de rocha e de crosta, que é textura fina e serve a qualquer superfície;
- estrela, poeira e outros elementos de céu;
- pedra solta genérica.

## O que não entra

- **Arte que é a cara de um planeta.** Corpo celeste do fundo, marco construído, silhueta característica. Isso é assinatura, fica na `art/` da própria fase, e é o que impede dois planetas de serem o mesmo planeta repintado (seção 7 do conceito).
- **Recurso `.tres`.** Se um dia existir um `TileSet` de verdade, ele é dado, e vai em `stages/data/`. Hoje não existe nenhum: o terreno se monta por polígono e linha derivados do `perfil`, não por grade de tiles — ver a receita em `stages/CLAUDE.md`.
- **A montagem do mapa.** Cena e nós são da fase, sempre.

## As duas regras que mantêm esta pasta útil

- **Decida quando desenhar, não quando doer.** Antes de criar o sprite, pergunte se ele é vocabulário ou assinatura. Vocabulário nasce aqui; assinatura nasce na fase. Mover depois é o caso raro, não o fluxo normal.
- **IMPORTANT: só entra o que já tem dois donos reais.** Um único uso não justifica compartilhar. Sem esse teto, toda pasta compartilhada vira depósito de arte órfã que ninguém tem coragem de apagar.

## Carregue por `uid`, não por caminho

Arte daqui é a que mais tem chance de mudar de lugar, e cena e script se comportam de formas diferentes: a cena referencia por `uid` e sobrevive a mover e renomear, o script referencia por caminho e quebra calado.

Nos scripts, use o `uid` (está no `.import` ao lado do PNG):

```gdscript
## grao_de_rocha.png
const GRAO_DE_ROCHA := preload("uid://<o uid do .import>")
```

O comentário não é opcional: `uid` não se lê.
