# Conjunto: nave

A nave do jogador, que é o personagem principal. Ela aparece nas duas vistas: grande no céu claro das regiões e pequena no espaço escuro, com a câmera afastada. Precisa ler nas duas, pela silhueta e pelo contraste, e continuar sendo um objeto de metal pintado e não um desenho chapado.

Referência de técnica, só para estudo: metal em cilindro com faixa de brilho estreita e dura, luz refletida fraca na borda da sombra (tutoriais de metal do Lospec e do fórum do itch.io); pintura em faixas sobre base neutra (Slynyrd, Pixelblog 12).

```
luz: cima_esquerda
rampas: neutros_quentes, neutros_frios, vermelho_laranja, vermelhos, magentas, terras, azuis, teais
valor.objeto: 25-70
valor.efeito: 40-95
```

## Materiais

| Material | Tons |
|---|---|
| Casco de metal | `neutros_frios:0` a `:3`, brilho de 1 px em `neutros_frios:4` numa faixa vertical do lado da luz; luz refletida de 1 px em `neutros_frios:1` junto da borda da sombra |
| Pintura vermelha (nariz, faixa, aletas) | `vermelhos:0`, `vermelho_laranja:0`, `vermelho_laranja:1`, realce `magentas:3` e brilho raro `magentas:4` |
| Metal escuro (saia, bocal, pernas) | `neutros_quentes:1` na sombra funda e `neutros_frios:0` a `:2` no corpo, lábio da saia em `neutros_frios:3`; nada de `neutros_quentes:3`, que lê como madeira |
| Escotilha | moldura de latão em `terras:1`, `terras:3`, `terras:4`; vidro `azuis:1` a `azuis:3`, reflexo `azuis:4` e ponto `neutros_frios:4` |
| Lâmpada da antena | `magentas:2` com ponto `magentas:4`, emissiva |
| Chama do motor | núcleo `neutros_frios:4`, `vermelho_laranja:4` e `:3`, borda `vermelho_laranja:2` e `:1`, ponta `vermelho_laranja:0`; sem contorno, emissiva |
| Piloto astronauta | traje `neutros_frios:1` a `:4`, faixa `vermelho_laranja:1` e `:0` do foguete, visor `azuis:0` a `:3` com brilho, mochila `neutros_frios:1` e `neutros_quentes:2`, lâmpada `vermelho_laranja:4`; contorno de personagem `neutros_quentes:1`; quadro 20x22 com o boneco nas 16 colunas da esquerda |
| Doca da tela de título | chapa `neutros_frios:1` a `:3`, faixa de aviso `vermelho_laranja:4` e `neutros_quentes:1` em diagonal, treliça `neutros_frios:0` e `neutros_quentes:2`; lâmpadas de 6x6 apagada, vermelha, amarela e verde |
| Contorno | `neutros_quentes:0` em volta de tudo, porque a nave precisa ler contra o céu claro |
| Anel de espaço | 1 px em `neutros_frios:1` em volta da silhueta, só no espaço, porque lá o contorno tem a cor do fundo; gerado do alfa em código, não desenhado; no espaço a nave é desenhada com cada pixel da arte em um pixel inteiro de janela |

## Forma

- Nariz em ogiva: os degraus da lateral crescem da ponta para a base (1, 1, 2, 2, 2, 2, 3), nunca voltam.
- Corpo em cilindro, sombreado por coluna: a luz vem de cima à esquerda, então a faixa de brilho fica no terço esquerdo e a sombra no terço direito.
- As aletas são as pernas de pouso: a sapata é a parte mais baixa do desenho, e é dela que a colisão tira o chão. O bocal fica acima da linha das sapatas, para a chama sair sem encostar no chão.
- Detalhe que conta história, pouco e pequeno: rebites em fila, emenda entre nariz e corpo, escotilha com reflexo.

## Tamanho

32x48 px, nariz para cima, centrada: a origem da nave é o centro do desenho.
