"""Resurrect 64, a paleta do llrr (docs/paleta.md). Toda cor gerada sai daqui."""

RAMPAS: dict[str, list[str]] = {
    "neutros_quentes": ["2e222f", "3e3546", "625565", "966c6c", "ab947a"],
    "neutros_frios": ["694f62", "7f708a", "9babb2", "c7dcd0", "ffffff"],
    "vermelhos": ["6e2727", "b33831", "ea4f36", "f57d4a"],
    "vermelho_laranja": ["ae2334", "e83b3b", "fb6b1d", "f79617", "f9c22b"],
    "terras": ["7a3045", "9e4539", "cd683d", "e6904e", "fbb954"],
    "olivas": ["4c3e24", "676633", "a2a947", "d5e04b", "fbff86"],
    "verdes": ["165a4c", "239063", "1ebc73", "91db69", "cddf6c"],
    "verdes_acinzentados": ["313638", "374e4a", "547e64", "92a984", "b2ba90"],
    "teais": ["0b5e65", "0b8a8f", "0eaf9b", "30e1b9", "8ff8e2"],
    "azuis": ["323353", "484a77", "4d65b4", "4d9be6", "8fd3ff"],
    "roxos": ["45293f", "6b3e75", "905ea9", "a884f3", "eaaded"],
    "rosas": ["753c54", "a24b6f", "cf657f", "ed8099"],
    "magentas": ["831c5d", "c32454", "f04f78", "f68181", "fca790", "fdcbb0"],
}

PRETO = "2e222f"
BRANCO = "ffffff"


def rgb(h: str) -> tuple[int, int, int]:
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


PALETA: set[tuple[int, int, int]] = {rgb(c) for r in RAMPAS.values() for c in r}
assert len(PALETA) == 64


def conferir(img) -> list[str]:
    """Problemas da imagem: cor fora da paleta ou alfa parcial. Vazio = ok."""
    problemas: list[str] = []
    fora: set = set()
    alfa_parcial = 0
    for r, g, b, a in img.convert("RGBA").get_flattened_data():
        if a == 0:
            continue
        if a != 255:
            alfa_parcial += 1
        if (r, g, b) not in PALETA:
            fora.add("%02x%02x%02x" % (r, g, b))
    if fora:
        problemas.append(f"{len(fora)} cor(es) fora da paleta: {sorted(fora)[:8]}")
    if alfa_parcial:
        problemas.append(f"{alfa_parcial} pixel(s) com alfa parcial")
    return problemas
