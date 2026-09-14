#!/usr/bin/env python3
"""Gera os PNG do jogo a partir das fontes .pix em art/fonte/.

    python3 .claude/skills/pixel-art-sprite/scripts/montar_arte.py [pasta ...]

Para cada pasta art/fonte/ do projeto (ou só abaixo das pastas indicadas):

  - <peça>.pix          -> art/<peça>.png
  - tiles/*.pix         -> art/tiles.png, uma linha, em ordem alfabética
  - quadros/<anim>_N    -> art/<entidade>_<anim>.png, tira horizontal (hframes)
  - <anim>/N_<nome>.pix -> art/<anim>.png, tira horizontal na ordem do número

Cada peça passa pelas mesmas regras do `sprite.py construir` antes de virar PNG:
até 64x64, paleta, alfa, tipo e bordas. Qualquer erro para tudo e nada é escrito.
"""

import re
import sys
from pathlib import Path

from PIL import Image

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[3]
sys.path.insert(0, str(AQUI))
import sprite  # noqa: E402


def gerar(pix: Path) -> Image.Image:
    meta, paleta, grade = sprite.ler_pix(pix.read_text(encoding="utf-8"))
    sprite.conferir_meta(meta)
    if pix.stem != meta["nome"]:
        raise sprite.ErroSprite(f"{pix}: o arquivo se chama {pix.stem!r} mas 'nome:' diz {meta['nome']!r}")
    img = sprite.montar_imagem(meta, paleta, grade)
    bordas = sprite.ler_encaixe(meta.get("encaixe")) | sprite.ler_encaixe(meta.get("superficie"))
    if meta["tipo"] in sprite.TIPOS_DE_GRADE and not sprite.ler_encaixe(meta.get("encaixe")):
        bordas |= {"esquerda", "direita"}
    sprite.validar(img, meta["tipo"], bordas)
    return img


def tira(imagens: list[Image.Image], nome: str) -> Image.Image:
    tamanhos = {im.size for im in imagens}
    if len(tamanhos) != 1:
        raise sprite.ErroSprite(f"{nome}: quadros de tamanhos diferentes {sorted(tamanhos)}")
    w, h = imagens[0].size
    folha = Image.new("RGBA", (w * len(imagens), h), (0, 0, 0, 0))
    for i, im in enumerate(imagens):
        folha.paste(im, (i * w, 0))
    return folha


def numero(p: Path) -> int:
    achados = re.findall(r"\d+", p.stem)
    return int(achados[-1] if p.parent.name == "quadros" else achados[0]) if achados else 0


def planejar(fonte: Path) -> list[tuple[Path, Image.Image, str]]:
    art = fonte.parent
    saidas = []
    for pix in sorted(fonte.glob("*.pix")):
        img = gerar(pix)
        saidas.append((art / f"{pix.stem}.png", img, f"{img.width}x{img.height}"))
    for sub in sorted(p for p in fonte.iterdir() if p.is_dir()):
        pixes = sorted(sub.glob("*.pix"))
        if not pixes:
            continue
        if sub.name == "tiles":
            imgs = [gerar(p) for p in pixes]
            saidas.append((art / "tiles.png", tira(imgs, "tiles"), f"atlas de {len(imgs)}: " + ", ".join(p.stem for p in pixes)))
        elif sub.name == "quadros":
            grupos: dict[str, list[Path]] = {}
            for p in pixes:
                grupos.setdefault(re.sub(r"_\d+$", "", p.stem), []).append(p)
            for anim, lista in sorted(grupos.items()):
                lista.sort(key=numero)
                nome = f"{art.parent.name}_{anim}.png"
                saidas.append((art / nome, tira([gerar(p) for p in lista], nome), f"hframes = {len(lista)}"))
        else:
            pixes.sort(key=numero)
            saidas.append((art / f"{sub.name}.png", tira([gerar(p) for p in pixes], sub.name),
                           f"hframes = {len(pixes)}: " + ", ".join(p.stem for p in pixes)))
    return saidas


def main() -> int:
    alvos = [Path(a).resolve() for a in sys.argv[1:]] or [RAIZ]
    fontes = sorted({f for alvo in alvos for f in alvo.rglob("fonte")
                     if f.is_dir() and f.parent.name == "art" and ".godot" not in f.parts and ".claude" not in f.parts})
    try:
        plano = [s for f in fontes for s in planejar(f)]
    except sprite.ErroSprite as e:
        print(f"erro: {e}", file=sys.stderr)
        return 1
    for destino, img, detalhe in plano:
        img.save(destino, optimize=True)
        print(f"ok  res://{destino.relative_to(RAIZ)}  ({detalhe})")
    print(f"{len(plano)} PNG gerado(s) a partir de {len(fontes)} pasta(s) de fonte")
    return 0


if __name__ == "__main__":
    sys.exit(main())
