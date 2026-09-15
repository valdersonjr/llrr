"""Rascunho da miniatura de Arvo para o mapa do sistema: a carta de superfície
projetada numa esfera, com luz de cima à esquerda em faixas da rampa de cada chão.
Gera o .pix para revisão e retoque.   python3 miniatura_arvo.py <diametro>"""
import glob, math, re, sys
from PIL import Image
sys.path.insert(0, ".claude/skills/pixel-art-sprite/scripts")
from paleta import RAMPAS

A = "mundo/planetas/arvo/art/fonte"
CANTOS = open("/private/tmp/claude-501/-Users-valdersonjunior-valderson-pessoais-jogos-teste/ff41fa19-2ff6-4cd0-9cf2-f02d25f1268a/scratchpad/montar_carta_arvo.gd").read()
CANTOS = re.findall(r'^\t"([0-3]{23})",$', CANTOS, re.M)
W, H = 22, 12

def conjunto(pasta):
    return {int(re.match(r"(\d+)_", p.split("/")[-1]).group(1)): Image.open(p).convert("RGBA")
            for p in glob.glob(f"{A}/{pasta}/*.png")}

base, plato, deserto = conjunto("carta"), conjunto("plato"), conjunto("deserto")
def k_de(tx, ty, teste):
    c = lambda x, y: 1 if teste(int(CANTOS[y][x])) else 0
    return c(tx, ty) | c(tx + 1, ty) << 1 | c(tx, ty + 1) << 2 | c(tx + 1, ty + 1) << 3

camadas = {n: Image.new("RGBA", (W * 16, H * 16)) for n in ("base", "deserto", "plato")}
for ty in range(H):
    for tx in range(W):
        camadas["base"].paste(base[k_de(tx, ty, lambda v: v >= 1)], (tx * 16, ty * 16))
        for nome, tiles, alvo in (("deserto", deserto, 3), ("plato", plato, 2)):
            k = k_de(tx, ty, lambda v, a=alvo: v == a)
            if k:
                camadas[nome].paste(tiles[k], (tx * 16, ty * 16))
agua = {tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) for r in ("teais", "azuis") for c in RAMPAS[r]}
px = {n: im.load() for n, im in camadas.items()}

def chao(u, v):
    x, y = int(u) % (W * 16), min(max(int(v), 0), H * 16 - 1)
    if px["plato"][x, y][3]: return "plato"
    if px["deserto"][x, y][3]: return "deserto"
    return "mar" if px["base"][x, y][:3] in agua else "mata"

CORES = {  # realce, corpo, sombra, noite
    "mar": ("teais:1", "teais:0", "azuis:0", "roxos:0"),
    "mata": ("verdes:2", "verdes:1", "verdes:0", "neutros_quentes:1"),
    "plato": ("verdes:3", "verdes:2", "verdes:1", "neutros_quentes:1"),
    "deserto": ("terras:4", "terras:3", "terras:1", "roxos:0"),
}
D = int(sys.argv[1]); R = D / 2
centro = 0.5 * 2 * math.pi
luz = (-0.42, -0.42, 0.8); n_luz = math.sqrt(sum(c * c for c in luz)); luz = tuple(c / n_luz for c in luz)
grade = [["." for _ in range(D)] for _ in range(D)]
dentro = [[False] * D for _ in range(D)]
for py in range(D):
    for pxl in range(D):
        nx, ny = (pxl + 0.5 - R) / R, (py + 0.5 - R) / R
        if nx * nx + ny * ny > 1: continue
        dentro[py][pxl] = True
        votos = {}
        for sy in (-0.33, 0, 0.33):
            for sx in (-0.33, 0, 0.33):
                ax, ay = (pxl + 0.5 + sx - R) / R, (py + 0.5 + sy - R) / R
                if ax * ax + ay * ay >= 1: continue
                z = math.sqrt(1 - ax * ax - ay * ay)
                lon = math.atan2(ax, z) + centro; lat = math.asin(-ay)
                t = chao(lon / (2 * math.pi) * W * 16, (0.5 - lat / math.pi) * H * 16)
                votos[t] = votos.get(t, 0) + 1
        terreno = max(votos, key=votos.get)
        z = math.sqrt(max(0.0, 1 - nx * nx - ny * ny))
        lam = nx * luz[0] + ny * luz[1] + z * luz[2]
        if lam > 0.97: faixa = 0
        elif lam > 0.42: faixa = 1
        elif lam > 0.12: faixa = 2
        elif lam > 0.02: faixa = 3 if (pxl + py) % 2 else 2
        else: faixa = 3
        grade[py][pxl] = CORES[terreno][faixa]
for py in range(D):  # atmosfera: fio de 1 px na borda do lado da luz
    for pxl in range(D):
        if not dentro[py][pxl]: continue
        borda = any(not (0 <= pxl + dx < D and 0 <= py + dy < D and dentro[py + dy][pxl + dx]) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        nx, ny = (pxl + 0.5 - R) / R, (py + 0.5 - R) / R
        if borda and nx * luz[0] + ny * luz[1] > 0.25:
            grade[py][pxl] = "teais:3"
simbolos = {}
letras = iter("abcdefghijklmnopqrstuvwxyzABCDEFGHIJ")
linhas = []
for linha in grade:
    s = ""
    for cor in linha:
        if cor == ".": s += "."; continue
        if cor not in simbolos: simbolos[cor] = next(letras)
        s += simbolos[cor]
    linhas.append(s)
pal = "\n".join(f"  {c} {cor}" for cor, c in simbolos.items())
open(f"{A}/miniatura.pix", "w").write(f"""nome: miniatura
tipo: objeto
camada: interface
conjunto: carta
luz: cima_esquerda
encaixe: nenhum
uso: Arvo no mapa do sistema, já na escala do mapa ({D} px de diâmetro); os continentes são os da carta de superfície
tamanho: {D}x{D}

paleta:
  . transparente
{pal}

pixels:
""" + "\n".join(linhas) + "\n")
print("ok", D, "px,", len(simbolos), "cores")
