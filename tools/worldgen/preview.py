#!/usr/bin/env python3
"""Gera prévias PNG do relevo rodando o WorldGen no Luau de linha de comando.
Uso: python3 tools/worldgen/preview.py <luau_bin> <saida_dir> [step]"""
import os, subprocess, sys, numpy as np
from PIL import Image
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
luau, outdir = sys.argv[1], sys.argv[2]
step = sys.argv[3] if len(sys.argv) > 3 else "16"
area = sys.argv[4:7]  # opcional: area cx cy
wg = os.path.join(root, "src/ServerStorage/WorldGen")
def body(name):
    return open(os.path.join(wg, name + ".lua"), encoding="utf-8").read()
script = "PREVIEW_STEP = " + step + "\n"
if area: script += f"PREVIEW_AREA = {area[0]}\nPREVIEW_CX = {area[1]}\nPREVIEW_CY = {area[2]}\n"
script += "local WorldData = (function()\n" + body("WorldData").replace("--!strict", "") + "\nend)()\n"
script += "local WorldGen = (function()\n" + body("WorldGen").replace("--!native", "").replace("--!optimize 2", "") + "\nend)()\n"
script += open(os.path.join(root, "tools/worldgen/preview_main.luau"), encoding="utf-8").read()
tmp = os.path.join(outdir, "preview_run.luau")
open(tmp, "w", encoding="utf-8").write(script)
res = subprocess.run([luau, "-O2", tmp], capture_output=True, text=True)
if res.returncode != 0:
    print(res.stderr); sys.exit(1)
sys.stderr.write(res.stderr)
lines = res.stdout.split("\n")
print(lines[0]); lines = lines[1:]
N = int(lines[0])
arr = np.array([l.split() for l in lines[1:1 + N * N]], dtype=float)
h = arr[:, 0].reshape(N, N)[::-1]  # norte para cima
wl = arr[:, 1].reshape(N, N)[::-1]
mat = arr[:, 2].astype(int).reshape(N, N)[::-1]
np.save(os.path.join(outdir, "heights.npy"), h)
COL = {1:(96,150,64),2:(70,120,52),3:(120,96,70),4:(120,118,112),5:(90,96,100),6:(240,244,248),7:(180,220,235),8:(222,206,150),9:(96,84,60),10:(60,58,62),11:(200,80,40),12:(205,195,170),13:(196,150,110),14:(130,128,124),15:(225,225,230),16:(170,210,230),17:(150,150,150)}
rgb = np.zeros((N, N, 3))
for k, c in COL.items():
    rgb[mat == k] = c
# sombreamento
gy, gx = np.gradient(h, float(step))
shade = np.clip(1 + (-gx * 0.6 + gy * 0.6) * 0.9, 0.45, 1.5)
rgb = rgb * shade[..., None]
water = wl > h
depth = np.clip((wl - h) / 40, 0, 1)
wcol = np.array([70, 130, 170]) * (1 - depth[..., None]) + np.array([25, 60, 100]) * depth[..., None]
rgb[water] = wcol[water]
img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8))
img.save(os.path.join(outdir, "terrain_preview.png" if not area else f"terrain_{area[1]}_{area[2]}.png"))
hm = np.clip((h + 50) / 1400 * 255, 0, 255).astype(np.uint8)
Image.fromarray(hm).save(os.path.join(outdir, "height_preview.png"))
print("ok", N, "h range", h.min(), h.max())
