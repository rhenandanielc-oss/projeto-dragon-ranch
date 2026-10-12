#!/usr/bin/env python3
"""Imprime tamanho e checksum de cada script em src/ (mesmo cálculo usado no Studio) para conferir a sincronização."""
import os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src")
rows = []
for root, _, files in os.walk(ROOT):
    for f in files:
        p = os.path.join(root, f)
        b = open(p, "rb").read()
        h = 0
        for c in b:
            h = (h * 31 + c) % 2147483647
        name = f.replace(".server.lua", "").replace(".client.lua", "").replace(".lua", "")
        rel = os.path.relpath(p, ROOT).split(os.sep)[:-1]
        rows.append(f"{'.'.join(rel + [name])} {len(b)} {h}")
print("\n".join(sorted(rows)))
