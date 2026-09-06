# common/ — CLAUDE.md local

Sistemas e ferramentas sem nenhuma referência à lógica específica deste jogo — idealmente copiáveis pra outro projeto sem editar nada.

Exemplos do tipo de coisa que mora aqui: máquina de estados genérica, escalonamento de resolução/UI, shaders de uso geral, sistema de tempo/relógio, ruído e pathfinding.

**IMPORTANT:** regra de entrada — se o arquivo cita qualquer `class_name`, cena, autoload ou constante deste jogo, ele não pertence a `common/`. Nesse caso vai na pasta da funcionalidade correspondente (`entities/`, `stages/`, `utilities/`).

Serve também como lembrete de projetar sistemas desacoplados: ao escrever algo genérico, pergunte se cabe aqui antes de enterrar numa pasta específica.

**Conceito:** nenhuma seção se aplica aqui, e isso é o teste. Se você precisou consultar `docs/conceito-de-jogo.md` para escrever o arquivo, ele não é de `common/`.
