"""Rascunho das camadas de platô e deserto sobre a mata, em esquema de dois cantos.

Cada camada é transparente fora da máscara dela, então empilha sobre a base
(mar/mata) sem precisar de tile para cada combinação de três terrenos.
Gera os .pix para retoque; o 15 do deserto é desenhado à mão e só é lido.
"""
import math

A = "mundo/planetas/arvo/art/fonte"
N = 16


def ler(caminho):
    linhas = open(caminho).read().split("pixels:\n")[1].strip().split("\n")
    return [list(l) for l in linhas]


def ruido(x, y, fase):
    a = 2 * math.pi / N
    return (0.55 * math.sin(a * x * 2 + 1.3 + fase) * math.cos(a * y + 0.4 + fase)
            + 0.45 * math.sin(a * y * 2 + 2.1 - fase) * math.cos(a * x + 1.7 + fase))


def dentro(cantos, x, y, fase, amp):
    tl, tr, bl, br = cantos
    u = min(max((x + 0.5) / N, 0.0), 1.0)
    v = min(max((y + 0.5) / N, 0.0), 1.0)
    f = tl * (1 - u) * (1 - v) + tr * u * (1 - v) + bl * (1 - u) * v + br * u * v
    return f + amp * ruido(x + 0.5, y + 0.5, fase) > 0.5


def cantos_de(k):
    return (k & 1, (k >> 1) & 1, (k >> 2) & 1, (k >> 3) & 1)


def gravar(pasta, nome, uso, paleta, linhas):
    usados = set("".join(linhas))
    pal = "\n".join(f"  {c} {cor:<20} {papel}" for c, cor, papel in paleta if c in usados)
    open(f"{A}/{pasta}/{nome}.pix", "w").write(
        f"nome: {nome}\ntipo: tile\ncamada: terreno\nconjunto: carta\nluz: cima_esquerda\n"
        f"encaixe: esquerda,direita,cima,baixo\nuso: {uso}\ntamanho: 16x16\n\n"
        f"paleta:\n{pal}\n\npixels:\n" + "\n".join(linhas) + "\n")


# ---------------------------------------------------------------- platô
mata = ler(f"{A}/carta/15_mata_a.pix")
SOBE = {"D": "b", "B": "p", "L": "q", "H": "Q"}  # a copa um degrau acima
PAL_PLATO = [
    (".", "transparente", ""),
    ("b", "verdes:1", "vão entre copas do platô"),
    ("p", "verdes:2", "copa do platô, corpo"),
    ("q", "verdes:3", "copa do platô, lado da luz"),
    ("Q", "verdes:4", "realce da copa do platô"),
    ("f", "verdes_acinzentados:2", "face do penhasco, alto"),
    ("F", "verdes_acinzentados:1", "face do penhasco, baixo"),
    ("k", "verdes_acinzentados:0", "sombra no pé do penhasco"),
]
for k in range(1, 16):
    c = cantos_de(k)
    em = lambda x, y: dentro(c, x, y, 0.9, 0.14)
    linhas = []
    for y in range(N):
        l = ""
        for x in range(N):
            if em(x, y):
                ch = SOBE[mata[y][x]]
            elif em(x, y - 1):
                ch = "f"
            elif em(x, y - 2) or em(x - 1, y):
                ch = "F"
            elif em(x, y - 3) or em(x - 1, y - 1):
                ch = "k"
            else:
                ch = "."
            l += ch
        linhas.append(l)
    cs = "".join(map(str, c))
    gravar("plato", f"{k}_plato_{cs}",
           f"platô de Arvo sobre a mata, cantos {cs} (TL TR BL BR); camada acima da base; penhasco cai para baixo e para a direita",
           PAL_PLATO, linhas)

# ---------------------------------------------------------------- deserto
areia = ler(f"{A}/deserto/15_deserto_1111.pix")
PAL_DESERTO = [
    (".", "transparente", ""),
    ("a", "terras:3", "areia"),
    ("b", "terras:2", "vale da marola"),
    ("c", "terras:4", "crista ao sol, só em pontos"),
    ("k", "terras:1", "sombra da mata sobre a areia"),
]
for k in range(1, 15):
    c = cantos_de(k)
    em = lambda x, y: dentro(c, x, y, 2.3, 0.18)
    linhas = []
    for y in range(N):
        l = ""
        for x in range(N):
            if not em(x, y):
                ch = "."
            elif not em(x, y - 1) or not em(x - 1, y):
                ch = "k"
            else:
                ch = areia[y][x]
            l += ch
        linhas.append(l)
    cs = "".join(map(str, c))
    gravar("deserto", f"{k}_deserto_{cs}",
           f"borda do deserto do Outpost sobre a mata, cantos {cs} (TL TR BL BR); a mata faz sombra na areia",
           PAL_DESERTO, linhas)
print("ok")
