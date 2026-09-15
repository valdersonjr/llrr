# Conjunto: espaço

A vista de espaço do sistema: fundo quase preto, campo de estrelas em duas camadas de paralaxe, nebulosas em bolhas e estrelas que cintilam. Referência de técnica: Slynyrd, Pixelblog 12 ("To the Stars"), só para estudo.

```
luz: frontal
rampas: neutros_quentes, azuis, roxos, teais, magentas, neutros_frios, verdes, verdes_acinzentados, terras
valor.fundo: 5-45
valor.efeito: 40-95
valor.objeto: 5-75
valor.interface: 5-95
```

## Materiais

| Material | Tons |
|---|---|
| Fundo | `neutros_quentes:0` (`#2e222f`), cor chapada; é também a cor de fundo da janela |
| Estrela longe | pontos de 1 px em `azuis:1`, `azuis:2` e `roxos:1`, apagados |
| Estrela perto | pontos em `azuis:4`, `roxos:3`, `teais:4`; cruz pequena com centro `teais:4` e braços `azuis:2` |
| Estrela que cintila | ponto → cruz pequena → cruz grande → brilho de quatro pontas, em quatro cores: ciano, azul, roxo, vermelho |
| Nebulosa roxa | corpo `roxos:0`, meio `roxos:1`, borda iluminada `roxos:2`, fiapos `azuis:0` |
| Nebulosa azul | corpo `azuis:0`, meio `azuis:1`, borda iluminada `azuis:2`, fiapos `roxos:0` |
| Estrela cadente | cabeça branca, cauda em `teais:4`, `azuis:3`, `azuis:1` |
| Corpo de planeta | a rampa de cada chão da carta de superfície, em seis níveis: noite `roxos:0`, penumbra, sombra, corpo, luz, realce; o terminador em xadrez de 1 px entre níveis |
| Nuvem sobre o planeta | bolhas com base reta em `neutros_frios:1` a `:4`, seguindo o nível de luz do chão embaixo; sombra de 2 px no chão, para baixo e à direita |
| Atmosfera | fio de 1 px em `teais:3` por dentro e `teais:1` por fora, só do lado da luz |
| Mira de entrada | quatro cantos em `neutros_frios:4` com contorno `neutros_quentes:0` |

## Regras

- Nada de alfa parcial: estrela apagada é uma cor mais escura da rampa, não transparência.
- Estrela é pixel isolado de propósito; o aviso de órfão do script não vale aqui.
- Nebulosa é bolha com três tons e borda clara no alto à esquerda, nunca ruído nem névoa lisa; fica atrás das estrelas perto.
- Ladrilho do campo de estrelas tem 64x48: o espaço tem 4096x2304, e com os fatores 0,125 e 0,25 a volta inteira fecha num número redondo de ladrilhos. Mexeu no tamanho do espaço, confira a costura.
- Dither só em planeta e corpo grande, nunca no campo de estrelas.
- **Corpo de planeta é desenhado em pixel de tela.** A câmera do espaço fica em `zoom_no_espaco` (0,45); um corpo desenhado em pixel de mundo encolheria e borraria. O corpo tem o diâmetro que ocupa na tela (Arvo: 288 px), em peças de 48x48 num `TileMapLayer` com escala `1 / zoom_no_espaco`. Os continentes são os da carta de superfície do planeta, projetados na esfera.
