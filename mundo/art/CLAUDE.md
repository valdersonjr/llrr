# mundo/art/

Arte que **mais de um lugar** usa, e o fundo da vista de espaço. Arte de um planeta ou de uma região mora no `art/` da pasta dela.

A regra que segura esta pasta está no `CLAUDE.md` da raiz: subir o asset quando aparece um segundo dono vale para o que é genérico. **Não vale para arte de assunto.** Se dois planetas querem a mesma pedra, o problema não é a pasta, são os dois planetas.

As fontes `.pix` estão em `fonte/` (fora do import) e os PNG saem de `python3 .claude/skills/pixel-art-sprite/scripts/montar_arte.py`. As cores seguem o conjunto `espaco` da skill `pixel-art-sprite`.

## O fundo do espaço

A vista de espaço tem três camadas de `campo_de_estrelas.gd` dentro do nó `Estrelas` do sistema, da mais longe para a mais perto:

| Camada | `fator` | Ladrilhos | Mosaico | Enfeites |
|---|---|---|---|---|
| `Longe` | 0,125 | `estrelas_longe.png`, 4 variações de 64x48 | 8x6 = 512x288 | nenhum |
| `Nebulosas` | 0,1875 | nenhum | 12x9 = 768x432 | `nebulosa_roxa.png`, `nebulosa_azul.png` |
| `Perto` | 0,25 | `estrelas_perto.png`, 4 variações de 64x48 | 16x12 = 1024x576 | estrelas que cintilam em quatro cores e `estrela_cadente.png` |

A cor de fundo da janela é o preto da paleta, `#2e222f`, e o espaço é pintado sobre ela.

- **Ladrilhos são uma tira de variações**, sorteadas pela posição dentro do mosaico: o campo não repete o mesmo quadrado lado a lado e o desenho é igual a cada volta.
- **Enfeite é uma tira de quadros num ponto do mosaico**, repetida com ele. Estrela que cintila vai e volta pelos quadros e espera como ponto; estrela cadente tem pausa negativa, passa uma vez e some.
- **A camada é desenhada em pixel de tela, não de mundo.** Na vista de espaço a câmera fica afastada; um fundo preso ao mundo encolheria junto, perderia pixels e o mosaico caberia várias vezes na tela. O nó anula a transformação da câmera a cada quadro e anda só pela paralaxe: a posição da câmera vezes o `fator`, arredondada para o pixel. `fator` 0 deixa a camada parada na tela; quanto maior, mais ela acompanha o voo.
- **IMPORTANT:** uma volta inteira do sistema tem que deslocar um número redondo de mosaicos: `tamanho do espaço × fator` divisível pelo `mosaico()` da camada. O espaço tem 4096x2304, e é isso que fecha os três mosaicos acima. Mexeu no tamanho do espaço, no `fator` ou no `periodo`, confira: `sistema.gd` avisa no console e `orbita_check` reprova.
- **O mosaico das nebulosas é maior que a tela** de propósito: menor que 640x360, a mesma nuvem apareceria duas vezes no mesmo quadro.
- Ladrilho novo precisa emendar nas quatro bordas: um ponto encostado na borda aparece cortado quando repete.
