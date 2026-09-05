# stages/ — CLAUDE.md local

Tudo aqui é "pai" do player na scene tree: as fases/áreas/mapas exploráveis.

- Geração procedural ou handmade de cada mapa mora dentro da pasta da própria fase.
- Tileset ou material reaproveitado entre múltiplas fases vai numa subpasta compartilhada aqui dentro (ex.: `stages/tilesets/`), nunca duplicado por fase.
- Algoritmo de geração genérico e reaproveitável em outro projeto (ruído, pathfinding etc.) vive em `common/`, não aqui — aqui fica só como esse jogo específico usa esse algoritmo pra montar as fases.
