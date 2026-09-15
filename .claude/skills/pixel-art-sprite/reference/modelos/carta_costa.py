"""Rascunho da costa mata/mar em esquema de dois cantos. Gera os .pix para retoque."""
import math, sys
sys.path.insert(0, ".claude/skills/pixel-art-sprite/scripts")
D = "mundo/planetas/arvo/art/fonte/carta"
N = 16

def ler(nome):
    linhas = open(f"{D}/{nome}.pix").read().split("pixels:\n")[1].strip().split("\n")
    return [list(l) for l in linhas]

mar = ler("0_mar_a"); mata = ler("15_mata_a")

def ruido(x, y):
    a = 2 * math.pi / N
    return (0.55 * math.sin(a * x * 2 + 1.3) * math.cos(a * y + 0.4)
            + 0.45 * math.sin(a * y * 2 + 2.1) * math.cos(a * x + 1.7))

def mascara(tl, tr, bl, br):
    m = [[False] * N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            u, v = (x + 0.5) / N, (y + 0.5) / N
            f = tl * (1 - u) * (1 - v) + tr * u * (1 - v) + bl * (1 - u) * v + br * u * v
            m[y][x] = f + 0.16 * ruido(x + 0.5, y + 0.5) > 0.5
    return m

def compor(m):
    out = [[None] * N for _ in range(N)]
    def terra(x, y):
        return m[y][x] if 0 <= x < N and 0 <= y < N else None
    for y in range(N):
        for x in range(N):
            if m[y][x]:
                agua_s = terra(x, y + 1) is False; agua_e = terra(x + 1, y) is False
                agua_n = terra(x, y - 1) is False; agua_w = terra(x - 1, y) is False
                ch = mata[y][x]
                if agua_s or agua_e: ch = "D"
                elif (agua_n or agua_w) and ch in "DB": ch = "L"
                out[y][x] = ch
            else:
                viz = [(dx, dy) for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2)
                       if terra(x + dx, y + dy)]
                if terra(x, y - 1) or terra(x - 1, y):
                    ch = "s"                         # sombra da margem na água
                elif terra(x, y + 1) or terra(x + 1, y):
                    ch = "e" if (x * 3 + y) % 4 else "r"  # espuma quebrada no lado da luz
                elif viz:
                    ch = "r"                         # água rasa
                else:
                    ch = mar[y][x]
                out[y][x] = ch
    return ["".join(l) for l in out]

CAB = """nome: {nome}
tipo: tile
camada: terreno
conjunto: carta
luz: cima_esquerda
encaixe: esquerda,direita,cima,baixo
uso: costa entre mata e mar em esquema de dois cantos (cantos {cantos}: TL TR BL BR, 1 = terra); encaixa com qualquer vizinho de cantos iguais
tamanho: 16x16

paleta:
  W teais:0            mar, fundo
  l teais:1            marola
  r teais:1            água rasa junto da costa
  e teais:3            espuma
  s azuis:0            sombra da margem na água
  D verdes:0           vão entre copas, margem na sombra
  B verdes:1           copa, corpo
  L verdes:2           copa, lado da luz
  H verdes:3           realce da copa

pixels:
"""
feitos = []
for k in range(1, 15):
    tl, tr, bl, br = k & 1, (k >> 1) & 1, (k >> 2) & 1, (k >> 3) & 1
    cantos = f"{tl}{tr}{bl}{br}"
    nome = f"{k}_costa_{cantos}"
    linhas = compor(mascara(tl, tr, bl, br))
    usados = set("".join(linhas))
    cab = CAB.format(nome=nome, cantos=cantos)
    cab = "\n".join(l for l in cab.split("\n") if not (l.startswith("  ") and l[2] not in usados))
    open(f"{D}/{nome}.pix", "w").write(cab + "\n".join(linhas) + "\n")
    feitos.append(nome)
print(" ".join(feitos))
