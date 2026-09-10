# localization/ — CLAUDE.md local

Textos localizados (CSV/PO de tradução), registrados em Project Settings → Localization.

Texto voltado ao jogador não deve ser escrito direto no script nem na cena: use a chave de tradução e mantenha o texto aqui. Retrofitar localização depois é o que torna essa pasta cara.

**A pasta ainda está vazia, e o jogo tem texto.** As strings moram literais em dois lugares, em português e em caixa alta: `entities/ui/hud/hud.gd` no script e `entities/ui/pausa/pausa.tscn` dentro da própria cena. Isso é dívida assumida, não a regra.

O gatilho para pagá-la é o primeiro dos dois que acontecer: a segunda língua entrar, ou o texto do jogo sair da fase de teste (menu, contrato, nome de planeta). Nesse dia, o CSV nasce aqui, é registrado em Project Settings → Localization, e esses três arquivos são os primeiros a trocar literal por chave.

**Conceito:** seção 14 de `docs/conceito-de-jogo.md`: os textos são preparados para inglês e português brasileiro.
