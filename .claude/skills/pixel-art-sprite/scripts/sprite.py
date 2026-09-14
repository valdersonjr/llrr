#!/usr/bin/env python3
"""Compila e valida sprites de pixel art: um sprite isolado por arquivo, até 64x64.

    python3 .claude/skills/pixel-art-sprite/scripts/sprite.py construir <pasta>/art/fonte/<nome>.pix \
        [--inspecao SCRATCHPAD/nome_inspecao.png] [--repeticao SCRATCHPAD/nome_repeticao.png]
    python3 .claude/skills/pixel-art-sprite/scripts/sprite.py validar ARQ.png [--tipo tile] [--encaixe esquerda,direita]
    python3 .claude/skills/pixel-art-sprite/scripts/sprite.py folha Q1.pix Q2.pix ... --saida <pasta>/art/<nome>.png --explicita

O `.pix` é a fonte e o PNG é gerado ao lado dele. Sai com código 1 em qualquer
violação de regra dura, então dá para usar como verificação antes de entregar.

Regras duras (erro):
  - largura e altura inteiras entre 1 e 64;
  - tipo declarado e dentro da lista de tipos de sprite;
  - nome ou tipo que descreve cena, tela, mapa ou ilustração;
  - cor fora da Resurrect 64 e alfa diferente de 0 ou 255;
  - sprite que não é tile com uma borda inteira opaca sem ter declarado
    `encaixe` nela: isso é recorte de cena, não peça solta;
  - folha de sprites sem `--explicita`, ou com quadros de tamanhos diferentes.

Avisos (não bloqueiam, mas pedem olhar): cores demais para o tamanho, pixels
órfãos, xadrez de dither, margem transparente sobrando, emenda de tile visível,
cor declarada e não usada.
"""

import argparse
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("erro: Pillow não encontrado. Rode com o python3 que tem PIL (`python3 -c 'import PIL'`).")

RAIZ = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from paleta import PALETA, PRETO, RAMPAS, rgb  # noqa: E402

MAXIMO = 64
TRANSPARENTE = (0, 0, 0, 0)

# tipo -> pasta dentro de sprites/
TIPOS = {
    "personagem": "personagens",
    "parte_de_personagem": "personagens",
    "objeto": "objetos",
    "item": "objetos",
    "tile": "terreno",
    "terreno": "terreno",
    "cenario": "cenario",
    "decoracao": "cenario",
    "efeito": "efeitos",
    "icone": "interface",
    "interface": "interface",
}
TIPOS_DE_GRADE = {"tile", "terreno"}
BORDAS = ("cima", "baixo", "esquerda", "direita")

# Palavras que denunciam pedido de imagem composta. Vale para nome e tipo.
PROIBIDAS = re.compile(
    r"(^|_)(cena|cenas|tela|telas|mapa|mapas|fase|ilustracao|composicao|paisagem|"
    r"wallpaper|background|fundo_completo|cenario_completo|screen|scene|level|splash|capa)(_|$)"
)

LUZES = {"cima_esquerda", "cima", "cima_direita", "esquerda", "direita", "frontal", "emissivo"}

# Camada de leitura na tela. O conjunto dá a cada uma uma faixa de valor, para
# o cenário não se misturar com o terreno nem o lugar de pouso com o cenário.
CAMADAS = {"fundo", "terreno", "cenario", "pouso", "personagem", "objeto", "efeito", "interface"}

# Marcador de escala da prévia de contexto: a nave do llrr tem ~29 px de altura.
NAVE = (24, 29)

# Fundos da inspeção: preto e branco do projeto, e um meio-tom neutro.
FUNDOS = [rgb("2e222f"), rgb("7f708a"), rgb("c7dcd0")]


class ErroSprite(Exception):
    pass


# ---------------------------------------------------------------- leitura .pix

def ler_cor(token: str) -> tuple[int, int, int, int]:
    """`transparente`, `#rrggbb` ou `rampa:indice` (índice 0 é o mais escuro)."""
    if token in ("transparente", "transparent"):
        return TRANSPARENTE
    if ":" in token:
        rampa, _, indice = token.partition(":")
        if rampa not in RAMPAS:
            raise ErroSprite(f"rampa desconhecida {rampa!r}; existem: {', '.join(RAMPAS)}")
        cores = RAMPAS[rampa]
        if not indice.isdigit() or int(indice) >= len(cores):
            raise ErroSprite(f"{token!r}: a rampa {rampa} tem índices de 0 a {len(cores) - 1}")
        return rgb(cores[int(indice)]) + (255,)
    h = token.lstrip("#").lower()
    if not re.fullmatch(r"[0-9a-f]{6}", h):
        raise ErroSprite(f"cor inválida {token!r}: use #rrggbb, rampa:indice ou transparente")
    cor = rgb(h)
    if cor not in PALETA:
        raise ErroSprite(f"#{h} não está na Resurrect 64 (paleta.py)")
    return cor + (255,)


def ler_pix(texto: str):
    meta: dict[str, str] = {}
    paleta: dict[str, tuple] = {}
    grade: list[str] = []
    secao = None
    for n, bruta in enumerate(texto.splitlines(), start=1):
        linha = bruta.rstrip()
        limpa = linha.strip()
        if secao == "pixels":
            if limpa.startswith("#"):
                continue
            grade.append(linha)
            continue
        if not limpa or limpa.startswith("#"):
            continue
        if limpa in ("paleta:", "pixels:"):
            secao = limpa[:-1]
            continue
        if secao == "paleta":
            partes = limpa.split(None, 2)
            if len(partes) < 2 or len(partes[0]) != 1:
                raise ErroSprite(f"linha {n}: paleta espera 'CARACTERE COR [papel]'")
            if partes[0] in paleta:
                raise ErroSprite(f"linha {n}: caractere {partes[0]!r} repetido na paleta")
            try:
                paleta[partes[0]] = ler_cor(partes[1])
            except ErroSprite as e:
                raise ErroSprite(f"linha {n}: {e}")
            continue
        if ":" in limpa:
            chave, _, valor = limpa.partition(":")
            meta[chave.strip()] = valor.strip()
            continue
        raise ErroSprite(f"linha {n}: não entendi {limpa!r}")

    while grade and not grade[-1].strip():
        grade.pop()
    if not paleta:
        raise ErroSprite("faltou a seção 'paleta:'")
    if not grade:
        raise ErroSprite("faltou a seção 'pixels:' ou ela está vazia")
    return meta, paleta, grade


def conferir_meta(meta: dict[str, str]) -> None:
    for campo in ("nome", "tipo", "tamanho", "uso"):
        if not meta.get(campo):
            raise ErroSprite(f"faltou o campo '{campo}:' no cabeçalho")
    if not re.fullmatch(r"[a-z0-9_]+", meta["nome"]):
        raise ErroSprite(f"nome {meta['nome']!r} precisa ser snake_case")
    conferir_pedido(meta["nome"], meta["tipo"])
    luz = meta.get("luz", "cima_esquerda")
    if luz not in LUZES:
        raise ErroSprite(f"luz {luz!r} inválida; use uma de: {', '.join(sorted(LUZES))}")
    camada = meta.get("camada")
    if camada and camada not in CAMADAS:
        raise ErroSprite(f"camada {camada!r} inválida; use uma de: {', '.join(sorted(CAMADAS))}")
    for campo in ("acima", "afunda"):
        if campo in meta and not meta[campo].isdigit():
            raise ErroSprite(f"'{campo}:' precisa ser um inteiro de pixels")


def conferir_pedido(nome: str, tipo: str) -> None:
    """A trava contra imagem composta que não depende de pixel nenhum."""
    for valor in (nome, tipo):
        if PROIBIDAS.search(valor):
            raise ErroSprite(
                f"{valor!r} descreve uma imagem composta. Esta skill só produz sprites "
                "isolados: decomponha o pedido em peças (ver SKILL.md, 'Decomposição')."
            )
    if tipo not in TIPOS:
        raise ErroSprite(f"tipo {tipo!r} não é tipo de sprite; use um de: {', '.join(TIPOS)}")


def ler_tamanho(texto: str) -> tuple[int, int]:
    m = re.fullmatch(r"\s*(\d+)\s*[x×]\s*(\d+)\s*", texto)
    if not m:
        raise ErroSprite(f"tamanho {texto!r} precisa ser LARGURAxALTURA com inteiros")
    return int(m.group(1)), int(m.group(2))


def ler_encaixe(texto: str | None) -> set[str]:
    if not texto or texto == "nenhum":
        return set()
    bordas = {b.strip() for b in texto.split(",") if b.strip()}
    invalidas = bordas - set(BORDAS)
    if invalidas:
        raise ErroSprite(f"encaixe com borda inválida {sorted(invalidas)}; use {', '.join(BORDAS)}")
    return bordas


def montar_imagem(meta, paleta, grade) -> Image.Image:
    altura = len(grade)
    largura = max(len(l) for l in grade)
    for i, linha in enumerate(grade):
        if len(linha) != largura:
            raise ErroSprite(f"linha {i} do desenho tem {len(linha)} pixels; a mais larga tem {largura}")
    if ler_tamanho(meta["tamanho"]) != (largura, altura):
        raise ErroSprite(f"'tamanho: {meta['tamanho']}' não bate com o desenho, que é {largura}x{altura}")
    conferir_dimensao(largura, altura)
    img = Image.new("RGBA", (largura, altura), TRANSPARENTE)
    px = img.load()
    for y, linha in enumerate(grade):
        for x, c in enumerate(linha):
            if c not in paleta:
                raise ErroSprite(f"caractere {c!r} em x={x}, y={y} não está na paleta do arquivo")
            px[x, y] = paleta[c]
    return img


# ---------------------------------------------------------------- validação

def conferir_dimensao(largura: int, altura: int) -> None:
    if not (1 <= largura <= MAXIMO and 1 <= altura <= MAXIMO):
        raise ErroSprite(
            f"{largura}x{altura} passa do limite de {MAXIMO}x{MAXIMO}. Não existe exceção: "
            "divida em peças menores que se encaixam."
        )


def validar(img: Image.Image, tipo: str, encaixe: set[str]) -> list[str]:
    """Levanta ErroSprite em regra dura; devolve a lista de avisos."""
    img = img.convert("RGBA")
    w, h = img.size
    conferir_dimensao(w, h)
    px = img.load()
    avisos: list[str] = []

    opacos = 0
    fora: set[str] = set()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a not in (0, 255):
                raise ErroSprite(f"alfa {a} em x={x}, y={y}: sem suavização, alfa só 0 ou 255")
            if a:
                opacos += 1
                if (r, g, b) not in PALETA:
                    fora.add("#%02x%02x%02x" % (r, g, b))
    if fora:
        raise ErroSprite(f"cores fora da Resurrect 64: {sorted(fora)[:8]}")
    if opacos == 0:
        raise ErroSprite("sprite vazio")

    def opaco(x, y):
        return px[x, y][3] == 255

    bordas_cheias = {
        "cima": all(opaco(x, 0) for x in range(w)),
        "baixo": all(opaco(x, h - 1) for x in range(w)),
        "esquerda": all(opaco(0, y) for y in range(h)),
        "direita": all(opaco(w - 1, y) for y in range(h)),
    }
    if tipo not in TIPOS_DE_GRADE:
        sem_encaixe = [b for b, cheia in bordas_cheias.items() if cheia and b not in encaixe]
        if sem_encaixe:
            raise ErroSprite(
                f"bordas totalmente opacas sem encaixe declarado: {', '.join(sem_encaixe)}. "
                "Sprite solto precisa de transparência em volta; se a peça encosta em outra "
                "de propósito, declare 'encaixe:'."
            )
        if all(bordas_cheias.values()) and w * h >= 32 * 32:
            raise ErroSprite("retângulo cheio e grande: isso é fundo ou recorte de cena, não sprite")

    # Cores: o tamanho pede economia.
    cores = {px[x, y][:3] for y in range(h) for x in range(w) if opaco(x, y)}
    teto = 10 if w * h <= 16 * 32 else 16 if w * h <= 32 * 32 else 24
    if len(cores) > teto:
        avisos.append(f"{len(cores)} cores para {w}x{h}; acima de {teto} costuma virar ruído")

    # Órfãos: pixel opaco sem nenhum dos 8 vizinhos da mesma cor. Diagonal conta,
    # porque ponta de folha e linha fina em degrau são clusters legítimos.
    orfaos = 0
    xadrez = 0
    for y in range(h):
        for x in range(w):
            if not opaco(x, y):
                continue
            c = px[x, y]
            viz = [px[x + dx, y + dy] for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                   if (dx or dy) and 0 <= x + dx < w and 0 <= y + dy < h]
            if viz and all(v != c for v in viz):
                orfaos += 1
            if x + 1 < w and y + 1 < h:
                a, b, d, e = c, px[x + 1, y], px[x, y + 1], px[x + 1, y + 1]
                if a == e and b == d and a != b and a[3] and b[3]:
                    xadrez += 1
    if orfaos > max(3, opacos * 0.06):
        avisos.append(f"{orfaos} pixels órfãos ({100 * orfaos / opacos:.0f}%): cluster quebrado lê como ruído")
    if xadrez > max(4, opacos * 0.08):
        avisos.append(f"{xadrez} células de xadrez: dither demais para este tamanho")

    # Margem que sobra.
    caixa = img.getbbox()
    if caixa and tipo not in TIPOS_DE_GRADE:
        cw, ch = caixa[2] - caixa[0], caixa[3] - caixa[1]
        if cw <= w - 4 or ch <= h - 4:
            avisos.append(f"o desenho ocupa {cw}x{ch} de {w}x{h}: margem transparente sobrando")

    # A emenda consigo mesma só existe quando a peça repete naquele eixo: as
    # duas bordas opostas encaixam. Topo de terreno encaixa embaixo em outra
    # peça (a terra), então comparar a última linha com a primeira não diz nada.
    eh, ev = medir_emenda(img)
    if {"esquerda", "direita"} <= encaixe and eh >= 2.0:
        avisos.append(f"emenda horizontal {eh:.1f}x o interior: vai ler como grade ao repetir")
    if {"cima", "baixo"} <= encaixe and ev >= 2.0:
        avisos.append(f"emenda vertical {ev:.1f}x o interior: vai ler como grade ao repetir")
    return avisos


def _dif(a, b) -> float:
    return sum(sum(abs(int(p) - int(q)) for p, q in zip(pa, pb)) / 4 for pa, pb in zip(a, b)) / max(len(a), 1)


def medir_emenda(img: Image.Image) -> tuple[float, float]:
    """Diferença na junção (última com primeira) dividida pela média do interior."""
    px = img.load()
    w, h = img.size
    col = lambda x: [px[x, y] for y in range(h)]
    lin = lambda y: [px[x, y] for x in range(w)]
    int_h = sum(_dif(col(x), col(x + 1)) for x in range(w - 1)) / max(w - 1, 1)
    int_v = sum(_dif(lin(y), lin(y + 1)) for y in range(h - 1)) / max(h - 1, 1)
    return (_dif(col(w - 1), col(0)) / int_h if int_h else 0.0,
            _dif(lin(h - 1), lin(0)) / int_v if int_v else 0.0)


# ---------------------------------------------------------------- inspeção

def inspecao(img: Image.Image, saida: Path, zoom: int = 10) -> None:
    """Uma faixa para o agente abrir com Read e julgar o próprio desenho.

    Em cima: o sprite ampliado sobre fundo escuro, médio e claro (o contorno tem
    que ler nos três), a silhueta chapada e os valores em cinza (a forma tem que
    ler só pela luz). Embaixo: 1x e 2x, que é como o jogo mostra.
    """
    w, h = img.size
    gap = 2
    blocos = []
    for cor in FUNDOS:
        fundo = Image.new("RGBA", (w, h), cor + (255,))
        blocos.append(Image.alpha_composite(fundo, img))
    alfa = img.getchannel("A")
    silhueta = Image.new("RGBA", (w, h), FUNDOS[2] + (255,))
    silhueta.paste(Image.new("RGBA", (w, h), FUNDOS[0] + (255,)), mask=alfa)
    blocos.append(silhueta)
    cinza = Image.alpha_composite(Image.new("RGBA", (w, h), FUNDOS[1] + (255,)), img).convert("L").convert("RGBA")
    blocos.append(cinza)

    faixa = Image.new("RGBA", (len(blocos) * (w + gap) - gap, h), (0, 0, 0, 0))
    for i, b in enumerate(blocos):
        faixa.paste(b, (i * (w + gap), 0))
    grande = faixa.resize((faixa.width * zoom, faixa.height * zoom), Image.NEAREST)

    reais = Image.new("RGBA", (w * 3 + gap * 4, h * 2 + gap * 2), FUNDOS[1] + (255,))
    reais.alpha_composite(img, (gap, gap))
    reais.alpha_composite(img.resize((w * 2, h * 2), Image.NEAREST), (w + gap * 3, gap))
    reais = reais.resize((reais.width * 2, reais.height * 2), Image.NEAREST)

    tela = Image.new("RGBA", (max(grande.width, reais.width), grande.height + reais.height + 16), FUNDOS[0] + (255,))
    tela.paste(grande, (0, 0))
    tela.paste(reais, (0, grande.height + 16))
    saida.parent.mkdir(parents=True, exist_ok=True)
    tela.save(saida)


def repeticao(img: Image.Image, saida: Path, encaixe: set[str], vezes: int = 3, zoom: int = 4) -> None:
    """A peça repetida nas direções em que ela encaixa, para a emenda aparecer."""
    w, h = img.size
    nx = vezes if ({"esquerda", "direita"} & encaixe) else 1
    ny = vezes if ({"cima", "baixo"} & encaixe) else 1
    grade = Image.new("RGBA", (w * nx, h * ny), FUNDOS[2] + (255,))
    for j in range(ny):
        for i in range(nx):
            grade.alpha_composite(img, (i * w, j * h))
    saida.parent.mkdir(parents=True, exist_ok=True)
    grade.resize((grade.width * zoom, grade.height * zoom), Image.NEAREST).save(saida)


# ---------------------------------------------------------------- conjunto

def valor_medio(img: Image.Image) -> float:
    """Luminância média dos pixels opacos, de 0 (preto) a 100 (branco)."""
    total = n = 0
    for r, g, b, a in img.convert("RGBA").get_flattened_data():
        if a:
            total += (0.299 * r + 0.587 * g + 0.114 * b) / 2.55
            n += 1
    return total / max(n, 1)


def conferir_conjunto(img: Image.Image, meta: dict[str, str]) -> list[str]:
    """Regras de coesão declaradas em sprites/conjuntos/<conjunto>.md."""
    nome = meta["conjunto"]
    arquivo = Path(__file__).resolve().parents[1] / "conjuntos" / f"{nome}.md"
    if not arquivo.is_file():
        return [f"conjunto {nome!r} não tem arquivo em conjuntos/{nome}.md da skill"]
    texto = arquivo.read_text(encoding="utf-8")
    avisos: list[str] = []

    faixas = {c: (int(a), int(b)) for c, a, b in
              re.findall(r"^valor\.(\w+):\s*(\d+)\s*-\s*(\d+)", texto, re.M)}
    camada = meta.get("camada")
    if not camada:
        avisos.append("sprite de conjunto sem 'camada:'; a faixa de valor não foi conferida")
    elif camada in faixas:
        v = valor_medio(img)
        a, b = faixas[camada]
        if not a <= v <= b:
            avisos.append(f"valor médio {v:.0f} fora da faixa {a}-{b} da camada {camada} "
                          f"no conjunto {nome}: vai se misturar com outra camada")

    m = re.search(r"^rampas:\s*(.+)$", texto, re.M)
    if m:
        permitidas = {r.strip() for r in m.group(1).split(",")}
        de_quem = {rgb(c): r for r, cores in RAMPAS.items() for c in cores}
        estranhas = {de_quem[p[:3]] for p in img.convert("RGBA").get_flattened_data()
                     if p[3] and de_quem[p[:3]] not in permitidas}
        if estranhas:
            avisos.append(f"rampas fora do conjunto {nome}: {', '.join(sorted(estranhas))}")
    return avisos


# ---------------------------------------------------------------- contexto

def carregar(caminho: Path) -> tuple[Image.Image, dict[str, str]]:
    if caminho.suffix == ".pix":
        meta, paleta, grade = ler_pix(caminho.read_text(encoding="utf-8"))
        conferir_meta(meta)
        return montar_imagem(meta, paleta, grade), meta
    img = Image.open(caminho).convert("RGBA")
    conferir_dimensao(*img.size)
    return img, {}


def contexto(terrenos: list[Path], pecas: list[Path], preenchimento: Path | None,
             saida: Path, fundo: str, largura: int, grupo: list[Path] | None = None) -> None:
    """Prévia de revisão: as peças no tamanho do jogo, a 2x, ao lado da nave.

    Não é entrega e não é cena: não pode ser salva dentro do projeto, e o nome termina
    em _contexto. Existe porque peça boa ampliada pode ser ruim no tamanho real
    e ruim ao lado das outras, e isso só aparece assim. Embaixo sai a mesma
    faixa em cinza, para conferir se cada camada se separa por valor.
    """
    if RAIZ in saida.resolve().parents:
        raise ErroSprite("a prévia de contexto é revisão, não entrega: salve no scratchpad, fora do projeto")
    if not saida.stem.endswith("_contexto"):
        raise ErroSprite("o arquivo da prévia precisa terminar em _contexto.png")
    if not 64 <= largura <= 640:
        raise ErroSprite("largura da prévia entre 64 e 640 (a tela do jogo tem 640)")

    chao = 72
    altura = chao + 48
    tela = Image.new("RGBA", (largura, altura), ler_cor(fundo))

    if preenchimento:
        img, _ = carregar(preenchimento)
        for y in range(chao + 16, altura, img.height):
            for x in range(0, largura, img.width):
                tela.paste(img, (x, y), img)

    tiles = [carregar(t) for t in terrenos]
    x = i = 0
    while x < largura:
        img, meta = tiles[i % len(tiles)]
        tela.paste(img, (x, chao - int(meta.get("acima", 0))), img)
        x += img.width
        i += 1

    nx = largura - NAVE[0] - 12
    for yy in range(chao - NAVE[1], chao):
        for xx in range(nx, nx + NAVE[0]):
            borda = yy in (chao - NAVE[1], chao - 1) or xx in (nx, nx + NAVE[0] - 1)
            tela.putpixel((xx, yy), rgb(PRETO if borda else "7f708a") + (255,))

    carregadas = [carregar(p) for p in pecas]
    if carregadas:
        vao = (nx - 12) / len(carregadas)
        for k, (img, meta) in enumerate(carregadas):
            x0 = int(12 + vao * k + (vao - img.width) / 2)
            tela.paste(img, (x0, chao - img.height + int(meta.get("afunda", 0))), img)

    # Peças modulares da mesma estrutura (pontas e meio de um deque), coladas
    # lado a lado no centro, para ver se as juntas batem.
    grupo = [carregar(p) for p in (grupo or [])]
    if grupo:
        total = sum(img.width for img, _ in grupo)
        x0 = max(0, (nx - total) // 2)
        for img, meta in grupo:
            tela.paste(img, (x0, chao - img.height + int(meta.get("afunda", 0))), img)
            x0 += img.width

    cinza = tela.convert("L").convert("RGBA")
    final = Image.new("RGBA", (largura * 2, altura * 4 + 8), rgb(PRETO) + (255,))
    final.paste(tela.resize((largura * 2, altura * 2), Image.NEAREST), (0, 0))
    final.paste(cinza.resize((largura * 2, altura * 2), Image.NEAREST), (0, altura * 2 + 8))
    saida.parent.mkdir(parents=True, exist_ok=True)
    final.save(saida)
    print(f"ok  {saida}  prévia a 2x (cor em cima, valores embaixo); o retângulo é a escala da nave")


# ---------------------------------------------------------------- comandos

def construir(caminho: Path, arq_inspecao: Path | None, arq_repeticao: Path | None) -> Image.Image:
    meta, paleta, grade = ler_pix(caminho.read_text(encoding="utf-8"))
    conferir_meta(meta)
    if caminho.stem != meta["nome"]:
        raise ErroSprite(f"o arquivo se chama {caminho.stem!r} mas 'nome:' diz {meta['nome']!r}")
    img = montar_imagem(meta, paleta, grade)
    tipo = meta["tipo"]
    encaixe = ler_encaixe(meta.get("encaixe"))
    if tipo in TIPOS_DE_GRADE and not encaixe:
        encaixe = {"esquerda", "direita"}
    # `superficie` é a borda onde algo pousa ou pisa (o topo de um deque): ela
    # pode ser opaca de ponta a ponta sem encaixar em outra peça.
    superficie = ler_encaixe(meta.get("superficie"))
    avisos = validar(img, tipo, encaixe | superficie)
    if int(meta.get("acima", 0)) >= img.height:
        raise ErroSprite("'acima:' precisa deixar pelo menos uma linha dentro da célula da grade")
    if meta.get("conjunto"):
        avisos += conferir_conjunto(img, meta)

    usados = {c for l in grade for c in l}
    sobras = set(paleta) - usados - {"."}
    if sobras:
        avisos.append(f"cores declaradas e não usadas: {' '.join(sorted(sobras))}")

    pasta_esperada = TIPOS[tipo]
    partes = caminho.resolve().parts
    espelha_llrr = "mundo" in partes or "entities" in partes or "estudos" in partes
    if not espelha_llrr and pasta_esperada not in partes:
        avisos.append(f"tipo {tipo} costuma morar em sprites/{pasta_esperada}/")

    png = caminho.with_suffix(".png")
    img.save(png, optimize=True)
    w, h = img.size
    print(f"ok  {png}  {w}x{h}  {len(usados - {'.'})} cores  tipo={tipo}  luz={meta.get('luz', 'cima_esquerda')}")
    if arq_inspecao:
        inspecao(img, arq_inspecao)
        print(f"ok  {arq_inspecao}  (escuro | médio | claro | silhueta | valores ; 1x e 2x)")
    if arq_repeticao:
        repeticao(img, arq_repeticao, encaixe or {"esquerda", "direita"})
        print(f"ok  {arq_repeticao}  repetição nas bordas de encaixe")
    for a in avisos:
        print(f"aviso: {a}", file=sys.stderr)
    return img


def folha(quadros: list[Path], saida: Path, explicita: bool) -> None:
    if not explicita:
        raise ErroSprite(
            "folha de sprites só quando o usuário pediu explicitamente; passe --explicita. "
            "O padrão é um PNG por sprite."
        )
    if PROIBIDAS.search(saida.stem):
        conferir_pedido(saida.stem, "objeto")
    imagens = []
    for q in quadros:
        imagens.append(construir(q, None, None) if q.suffix == ".pix" else Image.open(q).convert("RGBA"))
    tamanhos = {i.size for i in imagens}
    if len(tamanhos) != 1:
        raise ErroSprite(f"quadros com tamanhos diferentes: {sorted(tamanhos)}")
    w, h = imagens[0].size
    conferir_dimensao(w, h)
    sheet = Image.new("RGBA", (w * len(imagens), h), TRANSPARENTE)
    for i, im in enumerate(imagens):
        sheet.paste(im, (i * w, 0))
    saida.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(saida, optimize=True)
    print(f"ok  {saida}  {len(imagens)} quadros de {w}x{h} em uma linha")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="comando", required=True)

    c = sub.add_parser("construir", help="compila um .pix, valida e gera o PNG ao lado")
    c.add_argument("pix", type=Path)
    c.add_argument("--inspecao", type=Path, help="PNG ampliado para revisão (use o scratchpad)")
    c.add_argument("--repeticao", type=Path, help="PNG da peça repetida nas bordas de encaixe")

    v = sub.add_parser("validar", help="valida PNGs já existentes")
    v.add_argument("pngs", type=Path, nargs="+")
    v.add_argument("--tipo", default="objeto", help=f"um de: {', '.join(TIPOS)}")
    v.add_argument("--encaixe", default="", help="bordas que encostam em outra peça, ex.: esquerda,direita")

    f = sub.add_parser("folha", help="junta quadros de mesmo tamanho numa folha (só com pedido explícito)")
    f.add_argument("quadros", type=Path, nargs="+")
    f.add_argument("--saida", type=Path, required=True)
    f.add_argument("--explicita", action="store_true", help="confirma que o usuário pediu a folha")

    x = sub.add_parser("contexto", help="prévia de revisão das peças juntas, a 2x, com a nave; nunca é entrega")
    x.add_argument("--terreno", type=Path, nargs="+", required=True, help="tiles de topo, repetidos em sequência")
    x.add_argument("--pecas", type=Path, nargs="*", default=[], help="peças apoiadas no chão")
    x.add_argument("--preenchimento", type=Path, help="tile que preenche abaixo do topo")
    x.add_argument("--grupo", type=Path, nargs="*", default=[], help="peças modulares coladas em sequência no centro")
    x.add_argument("--fundo", default="neutros_frios:3", help="cor do fundo, da paleta")
    x.add_argument("--largura", type=int, default=320)
    x.add_argument("--saida", type=Path, required=True, help="no scratchpad, terminando em _contexto.png")

    args = ap.parse_args()
    try:
        if args.comando == "construir":
            construir(args.pix, args.inspecao, args.repeticao)
        elif args.comando == "validar":
            if args.tipo not in TIPOS:
                raise ErroSprite(f"tipo {args.tipo!r} inválido; use um de: {', '.join(TIPOS)}")
            falhou = False
            for p in args.pngs:
                try:
                    avisos = validar(Image.open(p), args.tipo, ler_encaixe(args.encaixe))
                    print(f"ok  {p}")
                    for a in avisos:
                        print(f"aviso: {p.name}: {a}", file=sys.stderr)
                except ErroSprite as e:
                    print(f"erro: {p}: {e}", file=sys.stderr)
                    falhou = True
            return 1 if falhou else 0
        elif args.comando == "folha":
            folha(args.quadros, args.saida, args.explicita)
        else:
            contexto(args.terreno, args.pecas, args.preenchimento, args.saida, args.fundo, args.largura, args.grupo)
    except ErroSprite as e:
        print(f"erro: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
