---
name: pixel-art
description: Cria pixel art para o jogo — sprites de nave, inimigos, tiles de terreno, plataformas, ícones de UI, efeitos e estados de dano. Use sempre que a tarefa envolver desenhar, ajustar ou revisar arte do jogo, ou quando aparecerem as palavras sprite, pixel art, tile, ícone, arte, desenho, animação ou paleta. Produz .pix (fonte em texto), PNG pronto para o Godot e preview HTML.
---

# Pixel art do Lunar RPG

Você atua como **designer de pixel art de jogos experiente**. Não gere blobs coloridos: cada sprite passa por silhueta, paleta declarada, luz consistente e verificação visual antes de entrar no projeto.

## O ciclo solo

Você consegue fechar esse ciclo sozinho porque consegue **ver** o que desenhou. Nunca entregue um sprite sem ter olhado para ele.

1. **Confirme o tamanho** na tabela de escala abaixo. Se o asset não estiver na tabela, escolha o múltiplo de 8 mais próximo e diga qual escolheu.
2. **Leia a paleta** em `reference/paleta.md`. Não invente cor nova sem dizer por quê.
3. **Escreva o `.pix`** — silhueta primeiro (só contorno e vazio), forma legível, depois preencha.
4. **Compile e inspecione:**
   ```
   python3 .claude/skills/pixel-art/scripts/build_sprite.py CAMINHO.pix --inspect SCRATCHPAD/inspect.png
   ```
5. **Abra `inspect.png` com a ferramenta Read.** Julgue de verdade: a silhueta lê? o contorno some em algum dos dois fundos? a luz é consistente? tem jaggie?
6. **Corrija o `.pix` e repita** do passo 4. Duas ou três voltas é normal.
7. Só então mova para a pasta definitiva da entidade.

O `--inspect` mostra o sprite ampliado sobre fundo escuro **e** claro, lado a lado. Os dois precisam funcionar.

## Escala do projeto

Viewport base **384×216**, escala inteira 5× para 1920×1080. Definido em `project.godot`.

| Asset | Tamanho | Observação |
|---|---|---|
| Nave do jogador (3 cascos) | 32×32 | hero asset, 4 regiões de dano |
| Nave inimiga | 32×32 | mesma escala do jogador |
| Tile de terreno | 16×16 | casa com o grid |
| Ícone de UI (mercadoria, módulo) | 16×16 | são 8 + 18–24, precisa ser barato |
| Plataforma de pouso | 32×16 e múltiplos | a largura comunica dificuldade |
| Depósito mineral | 24×24 | precisa de estados de consumo |
| Efeito (chama, explosão) | 16×16 ou 32×32 | um `.pix` por quadro |

Uma nave de 32px ocupa 14,8% da altura da tela. Ao desenhar, lembre que o jogador julga **inclinação e contato das pernas** nesse tamanho — a silhueta tem que denunciar o ângulo.

## O formato `.pix`

```
# comentário
name: utilitario_leve
size: 32x32
light: top-left

palette:
  . transparent
  K #16161f  contorno
  c #4a6fc4  casco base

pixels:
....KK....
...KccK...
```

- Um caractere = um pixel. `.` é sempre transparente.
- `size:` é conferido contra o desenho. Se divergir, o script falha e diz a diferença.
- Caractere fora da paleta falha com a coordenada exata do primeiro erro.
- Todas as linhas precisam ter o mesmo comprimento.

O `.pix` é a fonte de verdade e vai para o git junto do PNG. Editar arte = trocar caractere, e o diff mostra o desenho.

## Regras de ofício

**Silhueta primeiro.** O sprite tem que ser identificável como mancha preta sólida. Se não for, nenhuma cor salva.

**Contorno nunca é preto puro, e nunca some no fundo.** Este é um jogo espacial: o fundo é escuro quase sempre. Um contorno `#16161f` sobre um céu `#14161f` faz a nave dissolver. Use contorno **mais claro que o fundo esperado**, ou uma versão escurecida da cor adjacente em vez de um contorno único. Confira sempre nos dois fundos do `--inspect`.

**Paleta limitada, com hue shifting.** 4 a 9 cores por sprite. A rampa de sombra desloca a matiz para o azul/roxo; a de luz, para o amarelo/laranja. Só escurecer a mesma matiz produz rampa morta e cinzenta.

**Luz consistente:** `top-left` em todo o projeto. Se um asset precisar de outra luz, declare no `light:` e justifique.

**Zero antialiasing automático.** Nada de borda suave. AA manual só no interior da forma, nunca no contorno externo — contorno com meio-tom brilha contra fundo variável.

**Sem jaggies.** Uma diagonal vai 1-1-1 ou 2-2-2, nunca 1-2-1-3. Cluster de pixel inconsistente é o que mais denuncia amador.

**Sem pillow shading.** Não sombreie seguindo o contorno para dentro, como um travesseiro. A sombra segue o volume e a direção da luz.

**Leia a 1× também.** O preview HTML mostra 1×, 5× e ampliado. Se só funciona ampliado, o sprite tem detalhe demais para o tamanho.

## Direção de arte deste jogo

Vem da seção 14 de `docs/conceito-de-jogo.md`. Leia antes de começar uma série nova.

- **Retrô anos 80 com leitura moderna.** Não é fidelidade a hardware específico.
- **Cor sozinha nunca distingue inimigo, aliado e objetivo.** A diferença tem que estar na silhueta e na forma. Um jogador com daltonismo precisa jogar.
- **Silhuetas por facção.** Corporação, colonos rebeldes e piratas têm linguagem de forma distinta — não a mesma nave repintada.
- **Paletas por planeta.** O ambiente muda de paleta; a nave do jogador se mantém reconhecível.
- **Indicadores de dano consistentes.** Íntegro, degradado e desativado usam o mesmo vocabulário visual em todo asset.
- Os três cascos são **utilitário leve, cargueiro resistente e interceptador**. Silhuetas que se distinguem a 32px e em preto.

## Onde os arquivos vão

Vale a "Estrutura da pasta-folha" do `CLAUDE.md` da raiz: `.pix` e `.png` moram na pasta `art/` da própria entidade.

```
entities/player/utilitario_leve/
├── art/
│   ├── utilitario_leve.pix    ← fonte
│   └── utilitario_leve.png    ← build, é o que o Godot importa
├── utilitario_leve.tscn
└── utilitario_leve.gd
```

`snake_case` no nome do arquivo. Preview HTML é descartável: gere no scratchpad, nunca dentro do projeto.

Commit segue o `CLAUDE.md`: `content(entities): adiciona sprite do casco utilitário leve`. O `.pix` e o `.png` entram no **mesmo** commit.

## Godot

`project.godot` já está configurado — **não mexa nisso ao criar arte**:

- `textures/canvas_textures/default_texture_filter=0` (Nearest). Sem isso toda pixel art sai borrada.
- `window/stretch/mode="canvas_items"` com `scale_mode="integer"`.

A nave é desenhada com **o nariz para cima** (repouso pousado). A rotação 0 do Godot aponta para a direita, então a cena aplica o offset — não redesenhe o sprite deitado.
