#!/usr/bin/env python3
"""Converte um mapa de pixels em texto (.pix) para PNG e, opcionalmente, preview HTML.

Uso:
    build_sprite.py ARQUIVO.pix [--png CAMINHO] [--html CAMINHO] [--scale N]

O PNG sai com a dimensão exata declarada no arquivo, em RGBA, sem
reamostragem. O preview HTML é só para revisão visual — nunca entra no jogo.
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("erro: Pillow não instalado. Rode: python3 -m pip install Pillow")

TRANSPARENT = (0, 0, 0, 0)


class PixError(Exception):
    pass


def parse_hex(token: str) -> tuple[int, int, int, int]:
    """Aceita #rgb, #rrggbb e #rrggbbaa."""
    if token.lower() == "transparent":
        return TRANSPARENT
    if not token.startswith("#"):
        raise PixError(f"cor precisa começar com '#' ou ser 'transparent': {token!r}")
    h = token[1:]
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    if len(h) == 6:
        h += "ff"
    if len(h) != 8:
        raise PixError(f"cor com tamanho inválido: {token!r}")
    try:
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4, 6))
    except ValueError:
        raise PixError(f"cor não é hexadecimal: {token!r}")


def parse_pix(text: str):
    """Devolve (meta, palette, grid). Levanta PixError com a linha do problema."""
    meta: dict[str, str] = {}
    palette: dict[str, tuple] = {}
    names: dict[str, str] = {}
    grid: list[str] = []

    section = None
    for lineno, raw in enumerate(text.splitlines(), start=1):
        line = raw.rstrip()
        if section != "pixels":
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if stripped == "palette:":
                section = "palette"
                continue
            if stripped == "pixels:":
                section = "pixels"
                continue
            if section == "palette":
                parts = stripped.split(None, 2)
                if len(parts) < 2:
                    raise PixError(f"linha {lineno}: paleta espera 'CARACTERE COR [nome]'")
                char, color = parts[0], parts[1]
                if len(char) != 1:
                    raise PixError(f"linha {lineno}: o caractere da paleta tem que ter 1 char, veio {char!r}")
                if char in palette:
                    raise PixError(f"linha {lineno}: caractere {char!r} declarado duas vezes na paleta")
                palette[char] = parse_hex(color)
                names[char] = parts[2] if len(parts) > 2 else ""
                continue
            if ":" in stripped:
                key, _, value = stripped.partition(":")
                meta[key.strip()] = value.strip()
                continue
            raise PixError(f"linha {lineno}: não entendi {stripped!r}")
        else:
            if line.strip().startswith("#"):
                continue
            grid.append(line)

    while grid and not grid[-1].strip():
        grid.pop()
    while grid and not grid[0].strip():
        grid.pop(0)

    if not palette:
        raise PixError("faltou a seção 'palette:'")
    if not grid:
        raise PixError("faltou a seção 'pixels:' ou ela está vazia")
    return meta, palette, names, grid


def validate(meta, palette, grid):
    height = len(grid)
    width = max(len(row) for row in grid)

    for i, row in enumerate(grid):
        if len(row) != width:
            raise PixError(
                f"linha {i + 1} do desenho tem {len(row)} pixels, mas a mais larga tem {width}. "
                "Todas as linhas precisam ter o mesmo comprimento."
            )

    declared = meta.get("size")
    if declared:
        try:
            dw, dh = (int(n) for n in declared.lower().replace("×", "x").split("x"))
        except ValueError:
            raise PixError(f"'size: {declared}' não está no formato LARGURAxALTURA")
        if (dw, dh) != (width, height):
            raise PixError(
                f"'size: {declared}' não bate com o desenho, que é {width}x{height}"
            )

    unknown: dict[str, tuple[int, int]] = {}
    for y, row in enumerate(grid):
        for x, char in enumerate(row):
            if char not in palette and char not in unknown:
                unknown[char] = (x, y)
    if unknown:
        detalhe = ", ".join(
            f"{c!r} (primeiro em x={x}, y={y})" for c, (x, y) in sorted(unknown.items())
        )
        raise PixError(f"caractere fora da paleta: {detalhe}")

    return width, height


def build_png(palette, grid, width, height, out: Path):
    img = Image.new("RGBA", (width, height), TRANSPARENT)
    px = img.load()
    for y, row in enumerate(grid):
        for x, char in enumerate(row):
            px[x, y] = palette[char]
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG", optimize=True)
    return img


def build_html(meta, palette, names, grid, width, height, out: Path, scale: int):
    used = {c for row in grid for c in row}
    rows = "\n".join(
        "".join(
            f'<i style="background:{"transparent" if palette[c][3] == 0 else "#%02x%02x%02x" % palette[c][:3]}"></i>'
            for c in row
        )
        for row in grid
    )
    swatches = "\n".join(
        f'<li><b style="background:{"transparent" if palette[c][3] == 0 else "#%02x%02x%02x" % palette[c][:3]}"></b>'
        f'<code>{c}</code> <span>{names.get(c, "") or "—"}</span></li>'
        for c in sorted(used)
    )
    title = meta.get("name") or out.stem
    html = f"""<!doctype html>
<meta charset="utf-8">
<title>{title} — preview</title>
<style>
  :root {{ color-scheme: light dark; }}
  body {{ margin:0; padding:24px; font:13px/1.5 ui-monospace,SFMono-Regular,Menlo,monospace;
         background:#14161f; color:#e6e8ef; }}
  h1 {{ font-size:15px; margin:0 0 4px; }}
  .meta {{ color:#8b90a3; margin-bottom:24px; }}
  .row {{ display:flex; gap:32px; align-items:flex-start; flex-wrap:wrap; }}
  .box {{ background:#0b0d14; padding:16px; border:1px solid #262a38; }}
  .box h2 {{ font-size:11px; text-transform:uppercase; letter-spacing:.08em;
             color:#8b90a3; margin:0 0 12px; font-weight:600; }}
  .sprite {{ display:grid; grid-template-columns:repeat({width},var(--s));
             grid-auto-rows:var(--s); image-rendering:pixelated; }}
  .sprite i {{ display:block; width:var(--s); height:var(--s); }}
  .checker {{ background-image:
      linear-gradient(45deg,#1c1f2b 25%,transparent 25%,transparent 75%,#1c1f2b 75%),
      linear-gradient(45deg,#1c1f2b 25%,transparent 25%,transparent 75%,#1c1f2b 75%);
      background-size:16px 16px; background-position:0 0,8px 8px; }}
  ul {{ list-style:none; margin:0; padding:0; }}
  li {{ display:flex; align-items:center; gap:8px; padding:3px 0; }}
  b {{ width:16px; height:16px; border:1px solid #363b4d; flex:none; }}
  span {{ color:#8b90a3; }}
</style>
<h1>{title}</h1>
<div class="meta">{width}&times;{height} px &middot; {len(used)} cores &middot; luz: {meta.get('light', 'não declarada')}</div>
<div class="row">
  <div class="box">
    <h2>{scale}&times; &mdash; inspeção</h2>
    <div class="sprite checker" style="--s:{scale}px">
{rows}
    </div>
  </div>
  <div class="box">
    <h2>5&times; &mdash; tamanho em tela</h2>
    <div class="sprite checker" style="--s:5px">
{rows}
    </div>
  </div>
  <div class="box">
    <h2>1&times; &mdash; real</h2>
    <div class="sprite checker" style="--s:1px">
{rows}
    </div>
  </div>
  <div class="box">
    <h2>Paleta</h2>
    <ul>
{swatches}
    </ul>
  </div>
</div>
"""
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html, encoding="utf-8")


def build_inspect(img: Image.Image, out: Path, zoom: int):
    """Ampliação nearest sobre fundo escuro e claro, lado a lado.

    Serve para o agente abrir com a ferramenta Read e julgar o próprio desenho.
    O contorno precisa ler nos dois fundos.
    """
    w, h = img.size
    gap = 8
    escuro = Image.new("RGBA", (w, h), (20, 22, 31, 255))
    claro = Image.new("RGBA", (w, h), (198, 202, 214, 255))
    painel = Image.new("RGBA", (w * 2 + gap, h), (0, 0, 0, 0))
    painel.paste(Image.alpha_composite(escuro, img), (0, 0))
    painel.paste(Image.alpha_composite(claro, img), (w + gap, 0))
    ampliado = painel.resize(
        (painel.width * zoom, painel.height * zoom), Image.NEAREST
    )
    out.parent.mkdir(parents=True, exist_ok=True)
    ampliado.save(out, "PNG")


def main() -> int:
    ap = argparse.ArgumentParser(description="Compila um .pix para PNG e preview HTML.")
    ap.add_argument("pix", type=Path, help="arquivo .pix de entrada")
    ap.add_argument("--png", type=Path, help="saída PNG (padrão: mesmo nome, ao lado do .pix)")
    ap.add_argument("--html", type=Path, help="saída do preview HTML (opcional)")
    ap.add_argument("--inspect", type=Path, help="PNG ampliado para inspeção visual do agente")
    ap.add_argument("--zoom", type=int, default=10, help="ampliação do --inspect (padrão: 10)")
    ap.add_argument("--scale", type=int, default=16, help="zoom do painel de inspeção (padrão: 16)")
    args = ap.parse_args()

    if not args.pix.is_file():
        print(f"erro: não achei {args.pix}", file=sys.stderr)
        return 1

    try:
        meta, palette, names, grid = parse_pix(args.pix.read_text(encoding="utf-8"))
        width, height = validate(meta, palette, grid)
    except PixError as e:
        print(f"erro em {args.pix}: {e}", file=sys.stderr)
        return 1

    png_path = args.png or args.pix.with_suffix(".png")
    img = build_png(palette, grid, width, height, png_path)

    used = len({c for row in grid for c in row})
    print(f"ok  {png_path}  {width}x{height}  {used} cores")

    if args.inspect:
        build_inspect(img, args.inspect, args.zoom)
        print(f"ok  {args.inspect}  inspeção {args.zoom}x (fundo escuro | fundo claro)")

    if args.html:
        build_html(meta, palette, names, grid, width, height, args.html, args.scale)
        print(f"ok  {args.html}  preview")

    declared = {c for c in palette}
    unused = declared - {c for row in grid for c in row}
    if unused:
        print(f"aviso: cores declaradas e não usadas: {' '.join(sorted(unused))}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
