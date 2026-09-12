# mundo/art/

Arte que **mais de um lugar** usa. Quase toda arte de planeta é só dele e mora no `art/` da pasta dele; aqui entra o que é genérico de verdade, como estrela, grão de tela e partícula.

A regra que segura esta pasta está no `CLAUDE.md` da raiz: subir o asset quando aparece um segundo dono vale para o que é genérico. **Não vale para arte de assunto.** Se dois planetas querem a mesma pedra, o problema não é a pasta, são os dois planetas.

## O campo de estrelas

`campo_de_estrelas.gd` desenha uma textura lado a lado e a arrasta mais devagar do que a câmera anda. Duas ou três camadas com `fator` diferente dão profundidade sem nenhuma estrela existir de verdade.

- `fator` 0 gruda a camada na janela, como se estivesse infinitamente longe; 1 a prende no mundo, como qualquer outro objeto. O sistema usa 0.04 e 0.11.
- A emenda do mosaico é ancorada numa grade do tamanho da textura. Sem isso o padrão andaria junto com a câmera e a profundidade se cancelaria.
- As duas texturas são ruído esparso de um pixel, com algumas estrelas maiores na camada da frente para dar hierarquia. Foram geradas por script e entraram como PNG: daqui para a frente o PNG é a fonte, e trocar o céu é trocar o arquivo.
- **IMPORTANT:** uma volta inteira do sistema tem que deslocar um número redondo de mosaicos, ou seja, `tamanho do espaço × fator` divisível pelo tamanho da textura. É isso que faz atravessar a borda do sistema não aparecer na tela. Hoje o espaço tem 4096 por 2304 e a textura 512 por 288, então os fatores válidos são 0.125, 0.25 e assim por diante. Mexeu no tamanho do espaço, confira: `sistema.gd` avisa no console e `orbita_check` reprova.
- Elas precisam ser lado a lado sem emenda visível. Se você redesenhar uma, confira as bordas: uma costura aparece na hora, porque a mesma textura se repete dezenas de vezes na tela.
