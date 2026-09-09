# stages/ — CLAUDE.md local

Tudo aqui é "pai" do player na scene tree: as fases/áreas/mapas exploráveis.

- Geração procedural ou handmade de cada mapa mora dentro da pasta da própria fase.
- Arte só daquela fase (rocha, crosta, pedras, corpo celeste ao fundo) vai na `art/` da fase, como em qualquer pasta-folha. Assim que uma segunda fase precisar do mesmo material, mova para `stages/tilesets/`.
- Uma região se lê em camadas, do fundo para a frente: céu em gradiente, corpo celeste distante, duas cristas de contraste baixo, terreno com textura, crosta iluminada sobre o perfil, pedras soltas. Terreno chapado com contorno de 1px não tem profundidade nem escala.
- Tileset ou material reaproveitado entre múltiplas fases vai numa subpasta compartilhada aqui dentro (ex.: `stages/tilesets/`), nunca duplicado por fase.
- Algoritmo de geração genérico e reaproveitável em outro projeto (ruído, pathfinding etc.) vive em `common/`, não aqui — aqui fica só como esse jogo específico usa esse algoritmo pra montar as fases.

**Conceito:** seção 7 de `docs/conceito-de-jogo.md`. Superfícies são regiões locais, não planetas inteiros — e o mundo lembra: depósito exaurido, estrutura destruída e carga largada permanecem.
