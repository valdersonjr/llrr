# A paleta do projeto

**IMPORTANT: toda cor do jogo sai desta lista. Nada fora dela.** Vale para arte desenhada, arte gerada por script, interface, luz e cor de fundo. Cor que não está aqui é erro, não estilo.

É a [Resurrect 64](https://lospec.com/palette-list/resurrect-64). A tela inicial do jogo já foi desenhada nela.

## As rampas

O agrupamento abaixo é para leitura; a paleta é a lista inteira. Cada linha é uma rampa, do escuro ao claro, e **uma rampa é o caminho certo para sombrear**: escurecer misturando preto dá cor morta.

| Rampa | Cores |
|---|---|
| Neutros quentes | `#2e222f` `#3e3546` `#625565` `#966c6c` `#ab947a` |
| Neutros frios | `#694f62` `#7f708a` `#9babb2` `#c7dcd0` `#ffffff` |
| Vermelhos | `#6e2727` `#b33831` `#ea4f36` `#f57d4a` |
| Vermelho-laranja | `#ae2334` `#e83b3b` `#fb6b1d` `#f79617` `#f9c22b` |
| Terras | `#7a3045` `#9e4539` `#cd683d` `#e6904e` `#fbb954` |
| Olivas e amarelos | `#4c3e24` `#676633` `#a2a947` `#d5e04b` `#fbff86` |
| Verdes | `#165a4c` `#239063` `#1ebc73` `#91db69` `#cddf6c` |
| Verdes acinzentados | `#313638` `#374e4a` `#547e64` `#92a984` `#b2ba90` |
| Teais | `#0b5e65` `#0b8a8f` `#0eaf9b` `#30e1b9` `#8ff8e2` |
| Azuis | `#323353` `#484a77` `#4d65b4` `#4d9be6` `#8fd3ff` |
| Roxos | `#45293f` `#6b3e75` `#905ea9` `#a884f3` `#eaaded` |
| Rosas | `#753c54` `#a24b6f` `#cf657f` `#ed8099` |
| Magentas | `#831c5d` `#c32454` `#f04f78` `#f68181` `#fca790` `#fdcbb0` |

## Como usar

- **Sombrear é andar na rampa**, e mudar de rampa na ponta escura é o que dá sombra colorida em vez de suja.
- **A identidade de um lugar é a escolha de rampas**, não a saturação. O Outpost de Arvo vive nas terras e nos neutros quentes com céu azul. Cada lugar novo declara as rampas dele num conjunto da skill `pixel-art-sprite`.
- **Preto é `#2e222f` e branco é `#ffffff`.** Não existe `#000000` no jogo.
- Cor de interface sai daqui também. O painel, o convite de entrada e a tela de regiões não são exceção.

## Arte de terceiros

Pacote baixado quase nunca vem nesta paleta. Duas saídas honestas, e a escolha é por lugar:

1. **Converter** para a paleta mais próxima, o que uniformiza o jogo e afasta a arte do que o autor desenhou.
2. **Aceitar como está**, declarando o lugar como protótipo até existir arte própria.

Nunca a terceira: misturar as duas coisas no mesmo quadro sem decidir.

## Conferir

`tools/paleta_check.tscn` percorre os PNG do projeto e diz quanto de cada um está fora da paleta.
