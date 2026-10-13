#!/usr/bin/env python3
"""Revisão "de cima" da floresta, sem abrir o Studio.
Reproduz a regra de plantio do WorldBuilder.forestBlock (mesmo ruído, limiares e exclusões)
e desenha as copas vistas de cima, com estatísticas de cobertura por região.
Uso: python3 tools/worldgen/forest_topdown.py <topdown.txt> <saida.png> [raio_copa_mult]
topdown.txt vem de tools/worldgen/forest_topdown.luau (tipo, ruído m, altura, exclusão por célula de 30)."""
import sys, random
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

FOREST = {'land': (0.15, 420, 'mixed'), 'meadow': (0.3, 420, 'meadow'), 'forest': (-0.15, 520, 'pine'),
          'enchanted': (-0.05, 520, 'ench'), 'lakeland': (0.25, 320, 'lake'), 'coast': (0.3, 320, 'coast'),
          'swamp': (0.1, 220, 'swamp'), 'swampcore': (0.15, 220, 'swamp'), 'mountain': (0.15, 560, 'fir'),
          'snow': (0.25, 760, 'fir'), 'volcanic': (0.45, 620, 'dead'), 'crystal': (0.25, 620, 'crys'),
          'ruins': (0.25, 520, 'mixed'), 'castle': (0.35, 720, 'dead')}
# raio de copa estimado (studs) por kit — a medir no Studio
CROWN = {'pine': 8, 'fir': 8, 'mixed': 10, 'meadow': 12, 'lake': 12, 'coast': 8, 'swamp': 11, 'ench': 11, 'dead': 6, 'crys': 7}
RC = {'forest': (140, 150, 110), 'enchanted': (160, 140, 170), 'mountain': (150, 140, 120), 'snow': (220, 220, 225),
      'volcanic': (120, 90, 80), 'meadow': (170, 180, 120), 'lakeland': (160, 175, 130), 'coast': (200, 190, 150),
      'swamp': (120, 130, 100), 'swampcore': (100, 110, 90), 'crystal': (150, 170, 190), 'ruins': (170, 160, 140),
      'castle': (110, 100, 110), 'lake': (80, 120, 170), 'land': (165, 170, 125)}

src, out = sys.argv[1], sys.argv[2]
cm = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
N, CELL, HALF, R = 534, 30, 8000, 4
W = 16000 // R
rows = [l.split() for l in open(src).read().split('\n') if l.strip()]
typ = np.array([r[0] for r in rows], dtype=object).reshape(N, N)
m = np.array([float(r[1]) for r in rows]).reshape(N, N)
h = np.array([float(r[2]) for r in rows]).reshape(N, N)
ex = np.array([int(r[3]) for r in rows]).reshape(N, N)

canopy = np.zeros((W, W), bool)
random.seed(1)
trees = 0
for j in range(N):
    for i in range(N):
        cfg = FOREST.get(typ[j, i])
        if not cfg or ex[j, i] or h[j, i] <= 1 or h[j, i] >= cfg[1]:
            continue
        th, mm = cfg[0], m[j, i]
        p = 0.55 if mm > th + 0.3 else (0.22 if mm > th else 0.03)
        for extra in range(2):
            if extra == 0 and random.random() >= p:
                break
            if extra == 1 and not (mm > th + 0.3 and random.random() < 0.18):
                break
            x = -HALF + i * CELL + random.random() * CELL
            y = -HALF + j * CELL + random.random() * CELL
            cr = CROWN[cfg[2]] * random.uniform(0.85, 1.25) * cm * (0.6 if extra else 1)
            cx, cy, rr = int((x + HALF) / R), int((HALF - y) / R), max(1, int(cr / R))
            y0, y1, x0, x1 = max(0, cy - rr), min(W, cy + rr + 1), max(0, cx - rr), min(W, cx + rr + 1)
            if y1 <= y0 or x1 <= x0:
                continue
            gy, gx = np.ogrid[y0:y1, x0:x1]
            canopy[y0:y1, x0:x1] |= (gx - cx) ** 2 + (gy - cy) ** 2 <= rr * rr
            trees += 1

# cobertura por célula (linha j = y crescente; na imagem o norte fica em cima)
cellcov = np.zeros((N, N))
f = CELL / R
for j in range(N):
    ye = int(W - j * f); ys = int(W - (j + 1) * f)
    ys, ye = max(ys, 0), min(ye, W)
    for i in range(N):
        xs, xe = int(i * f), min(int((i + 1) * f), W)
        if ye > ys and xe > xs:
            cellcov[j, i] = canopy[ys:ye, xs:xe].mean()

print(f"árvores estimadas: {trees}  (raio de copa × {cm})")
for t in ['forest', 'enchanted', 'mountain', 'swamp', 'lakeland', 'land', 'meadow', 'coast', 'snow']:
    mask = (typ == t) & (ex == 0) & (h > 1)
    if mask.sum():
        field = ((m < FOREST[t][0]) & mask).sum() / mask.sum()
        print(f"{t:10s} área {mask.sum()*900/1e6:6.1f} M studs²  copa vista de cima {cellcov[mask].mean()*100:5.1f}%  em modo 'campo' {field*100:5.1f}%")
fm = (typ == 'forest') & (ex == 0) & (h > 1)
smooth = ndimage.uniform_filter(cellcov, size=5)
lab, nl = ndimage.label(fm & (smooth < 0.03))
sizes = sorted(ndimage.sum(np.ones_like(lab), lab, range(1, nl + 1)) * 900, reverse=True)[:6]
print("maiores vazios (sem copa num raio de ~75 studs) na Floresta Densa, studs²:", [int(s) for s in sizes])

base = np.zeros((N, N, 3), np.uint8)
for j in range(N):
    for i in range(N):
        c = RC.get(typ[j, i], (160, 160, 140))
        if h[j, i] <= 1:
            c = (60, 100, 150)
        elif ex[j, i] == 2:
            c = (200, 170, 120)
        elif ex[j, i] == 1:
            c = (235, 225, 205)
        base[N - 1 - j, i] = c
size = 2000
b = np.array(Image.fromarray(base).resize((size, size), Image.NEAREST)).astype(float)
can = np.array(Image.fromarray((canopy * 255).astype(np.uint8)).resize((size, size), Image.BOX)).astype(float)[..., None] / 255
img = (b * (1 - can) + np.array([28, 66, 38]) * can).astype(np.uint8)
Image.fromarray(img).save(out)
