"""Rascunho do corpo de Arvo visto do espaço: 288 px de tela, os continentes da carta
de superfície projetados numa esfera, com os mesmos campos de cantos que desenharam
a carta. Luz de cima à esquerda em faixas da rampa de cada chão, terminador em
xadrez, nuvens de bolhas desenhadas à mão e fio de atmosfera.
   python3 corpo_arvo.py previa <saida.png>      # imagem inteira para revisão
   python3 corpo_arvo.py pecas                   # grava as 36 peças .pix de 48x48
"""
import math, re, sys
from PIL import Image
sys.path.insert(0, ".claude/skills/pixel-art-sprite/scripts")
from paleta import RAMPAS

A = "mundo/planetas/arvo/art/fonte"
MODELO = ".claude/skills/pixel-art-sprite/reference/modelos/montar_carta_arvo.gd"
CANTOS = re.findall(r'^\t"([0-3]{23})",$', open(MODELO).read(), re.M)
TW, TH, N = 22, 12, 16

def ler(p):
    return [l for l in open(p).read().split("pixels:\n")[1].strip().split("\n")]
MATA = ler(f"{A}/carta/15_mata_a.pix")
AREIA = ler(f"{A}/deserto/15_deserto_1111.pix")

def ruido(x, y, fase=0.0):
    a = 2 * math.pi / N
    return (0.55 * math.sin(a * x * 2 + 1.3 + fase) * math.cos(a * y + 0.4 + fase)
            + 0.45 * math.sin(a * y * 2 + 2.1 - fase) * math.cos(a * x + 1.7 + fase))

def campo(u, v, teste, fase, amp):
    u = u % TW; v = min(max(v, 0.0), TH - 1e-6)
    tx, ty = int(u), int(v); fu, fv = u - tx, v - ty
    px_, py_ = fu * N, fv * N
    fu, fv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)   # cantos suavizados: um canto sozinho vira mancha redonda, não losango
    c = lambda x, y: 1.0 if teste(int(CANTOS[y][x % (TW + 1)])) else 0.0
    f = (c(tx, ty) * (1 - fu) * (1 - fv) + c(tx + 1, ty) * fu * (1 - fv)
         + c(tx, ty + 1) * (1 - fu) * fv + c(tx + 1, ty + 1) * fu * fv)
    return f + amp * ruido(px_, py_, fase) + amp * 0.4 * ruido(px_ * 2 + 3.1, py_ * 2 + 1.7, fase + 0.5)

terra = lambda u, v: campo(u, v, lambda k: k >= 1, 0.0, 0.16)
plato = lambda u, v: campo(u, v, lambda k: k == 2, 0.9, 0.14)
areia = lambda u, v: campo(u, v, lambda k: k == 3, 2.3, 0.18)

RAMPA = {  # do lado da noite ao realce: noite, penumbra, sombra, corpo, luz, realce
    "mar": ["roxos:0", "azuis:0", "azuis:1", "teais:0", "teais:1", "teais:2"],
    "raso": ["roxos:0", "azuis:0", "azuis:1", "teais:1", "teais:2", "teais:3"],
    "mata": ["roxos:0", "neutros_quentes:1", "verdes:0", "verdes:1", "verdes:2", "verdes:3"],
    "plato": ["roxos:0", "neutros_quentes:1", "verdes:1", "verdes:2", "verdes:3", "verdes:4"],
    "penhasco": ["roxos:0", "neutros_quentes:1", "verdes_acinzentados:0", "verdes_acinzentados:1", "verdes_acinzentados:2", "verdes_acinzentados:3"],
    "deserto": ["roxos:0", "roxos:1", "terras:1", "terras:2", "terras:3", "terras:4"],
    "nuvem": ["roxos:1", "neutros_frios:1", "neutros_frios:2", "neutros_frios:3", "neutros_frios:4", "neutros_frios:4"],
}
NUVENS_DESENHO_VELHO = {
    "grande": ["......llll..........",
               "...lllnnnnll..lll...",
               ".llnnnnnnnnnllnnnll.",
               "lnnnnnnnnnnnnnnnnnnn",
               "snnnnnnnnnnnnnnnnnns",
               ".ssssssssssssssssss."],
    "media": ["....lll......",
              "..llnnnll.ll.",
              ".lnnnnnnnlnnl",
              "snnnnnnnnnnns",
              ".sssssssssss."],
    "pequena": ["..lll....",
                ".lnnnlll.",
                "snnnnnnns",
                ".sssssss."],
}
NUVENS_DESENHO = {
    "grande": ["..............llll..................",
               ".........lllllnnnnll....lll.........",
               "......lllnnnnnnnnnnnlllnnnnll.......",
               "...lllnnnnnnnnnnnnnnnnnnnnnnnlll....",
               ".llnnnnnnnnnnnnnnnnnnnnnnnnnnnnnll..",
               "lnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnl",
               "snnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnns",
               ".ssssssssssssssssssssssssssssssssss."],
    "media": [".......lllll............",
              "....llnnnnnnll.lll......",
              "..llnnnnnnnnnnlnnnll....",
              ".lnnnnnnnnnnnnnnnnnnnll.",
              "snnnnnnnnnnnnnnnnnnnnnns",
              ".ssssssssssssssssssssss."],
    "pequena": ["...llll.....",
                ".llnnnnlll..",
                "lnnnnnnnnnnl",
                ".ssssssssss."],
}
NUVENS = [("grande", 40, 60), ("media", 150, 48), ("pequena", 210, 90), ("grande", 120, 150),
          ("media", 20, 190), ("pequena", 90, 118), ("media", 190, 200), ("grande", 70, 236),
          ("pequena", 230, 150), ("pequena", 150, 262)]
NUVENS_VELHAS = [("grande", 58, 46), ("media", 150, 64), ("grande", 196, 124), ("media", 34, 150),
          ("pequena", 112, 206), ("grande", 150, 232), ("pequena", 236, 176), ("pequena", 92, 104)]

D = 288; R = 141.5; C = 144.0
CENTRO = 0.56 * 2 * math.pi
L = (-0.42, -0.42, 0.8); n = math.sqrt(sum(x * x for x in L)); L = tuple(x / n for x in L)

def nivel(lam, x, y):
    xadrez = (x + y) % 2
    if lam >= 0.9: return 4
    if lam >= 0.86: return 4 if xadrez else 3
    if lam >= 0.47: return 3
    if lam >= 0.43: return 3 if xadrez else 2
    if lam >= 0.18: return 2
    if lam >= 0.12: return 2 if xadrez else 1
    if lam >= -0.02: return 1
    if lam >= -0.08: return 1 if xadrez else 0
    return 0

nuvem = {}
for nome, x0, y0 in NUVENS:
    for dy, linha in enumerate(NUVENS_DESENHO[nome]):
        for dx, ch in enumerate(linha):
            if ch != ".":
                nuvem[(x0 + dx, y0 + dy)] = ch

grade = [[None] * D for _ in range(D)]
for y in range(D):
    for x in range(D):
        nx, ny = (x + 0.5 - C) / R, (y + 0.5 - C) / R
        d2 = nx * nx + ny * ny
        if d2 > 1.0:
            if d2 < ((R + 1.2) / R) ** 2 and nx * L[0] + ny * L[1] > 0.3:
                grade[y][x] = "teais:1"          # atmosfera por fora, só do lado da luz
            continue
        z = math.sqrt(1 - d2)
        lam = nx * L[0] + ny * L[1] + z * L[2]
        lon = math.atan2(nx, z) + CENTRO; lat = math.asin(-ny)
        u = lon / (2 * math.pi) * TW; v = (0.5 - lat / math.pi) * TH
        cu, cv = int(u * N * 2) % N, int(v * N * 2) % N   # textura da carta no dobro da frequência
        lv = nivel(lam, x, y)
        desloc = 0
        if terra(u, v) > 0.5:
            if plato(u, v) > 0.5:
                chao = "plato"; t = MATA[cv][cu]
                desloc = -1 if t == "D" else (1 if t in "LH" and lv <= 3 else 0)
            elif plato(u - 0.14, v - 0.14) > 0.5:
                chao = "penhasco"
            elif areia(u, v) > 0.5:
                chao = "deserto"; t = AREIA[cv][cu]
                desloc = -1 if t == "b" else (1 if t == "c" and lv <= 3 else 0)
            else:
                chao = "mata"; t = MATA[cv][cu]
                desloc = -1 if t == "D" else (1 if t in "LH" and lv <= 3 else 0)
        else:
            chao = "raso" if terra(u, v) > 0.36 else "mar"
        if lv >= 2:
            lv = min(max(lv + desloc, 2), 5)
        if lam > 0.97 and chao in ("mar", "raso"):
            lv = 5
        if (x, y) in nuvem:
            ch = nuvem[(x, y)]
            base = nivel(lam, x, y)
            lv_n = min(max(base + (1 if ch == "l" else -1 if ch == "s" else 0), 0), 5)
            grade[y][x] = RAMPA["nuvem"][lv_n]
            continue
        if (x - 2, y - 2) in nuvem and lv >= 2 and nuvem[(x - 2, y - 2)] != "l":
            lv = max(lv - 1, 1)                  # sombra da nuvem no chão
        borda = (x + 0.5 - C) ** 2 + (y + 0.5 - C) ** 2 > (R - 1.0) ** 2
        if borda and nx * L[0] + ny * L[1] > 0.35:
            grade[y][x] = "teais:3"              # fio de atmosfera por dentro
            continue
        grade[y][x] = RAMPA[chao][lv]

def rgb(cor):
    r, i = cor.split(":"); h = RAMPAS[r][int(i)]
    return tuple(int(h[k:k + 2], 16) for k in (0, 2, 4)) + (255,)

if sys.argv[1] == "previa":
    im = Image.new("RGBA", (D + 32, D + 32), rgb("neutros_quentes:0"))
    for y in range(D):
        for x in range(D):
            if grade[y][x]:
                im.putpixel((x + 16, y + 16), rgb(grade[y][x]))
    im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(sys.argv[2])
    cores = {c for l in grade for c in l if c}
    print("ok previa,", len(cores), "cores")
else:
    import os
    pasta = f"{A}/corpo"; os.makedirs(pasta, exist_ok=True)
    letras = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    P = 48; lado = D // P
    for j in range(lado):
        for i in range(lado):
            bloco = [grade[y][i * P:(i + 1) * P] for y in range(j * P, (j + 1) * P)]
            simb = {}
            linhas = []
            for l in bloco:
                s = ""
                for c in l:
                    if c is None: s += "."; continue
                    if c not in simb: simb[c] = letras[len(simb)]
                    s += simb[c]
                linhas.append(s)
            enc = [n for n, ok in (("esquerda", i > 0), ("direita", i < lado - 1), ("cima", j > 0), ("baixo", j < lado - 1)) if ok]
            k = j * lado + i
            nome = f"{k}_corpo"
            pal = "\n".join(f"  {s} {c}" for c, s in simb.items())
            vazio = not simb
            if vazio:
                continue
            open(f"{pasta}/{nome}.pix", "w").write(
                f"nome: {nome}\ntipo: tile\ncamada: objeto\nconjunto: espaco\nluz: cima_esquerda\n"
                f"encaixe: {','.join(enc)}\n"
                f"uso: peça {i},{j} (coluna, linha) do corpo de Arvo visto do espaço, 6x6 peças de 48 num TileMapLayer; atlas na posição {k}\n"
                f"tamanho: 48x48\n\npaleta:\n  . transparente\n{pal}\n\npixels:\n" + "\n".join(linhas) + "\n")
    print("ok pecas")
