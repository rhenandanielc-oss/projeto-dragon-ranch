#!/usr/bin/env python3
"""Gera o mapa conceitual do mundo (WORLD-DESIGN.md) a partir dos dados abaixo.

Coordenadas do mundo em studs: x = leste, y = norte, origem no centro do mapa.
Saídas:
  docs/world-map-concept.svg  (arquivo independente, cores fixas)
  função svg_markup(themed=True) usada pela página do artifact (cores por tokens CSS)
"""
import math
import os

W = 1600  # pixels por lado (1 px = 10 studs)


def P(x, y):
    return ((x + 8000) / 10.0, (8000 - y) / 10.0)


def smooth_path(points, closed=True):
    """Curva Catmull-Rom convertida em Béziers cúbicas, para contornos orgânicos."""
    pts = [P(*p) for p in points]
    n = len(pts)
    if n < 2:
        return ""
    d = [f"M{pts[0][0]:.1f},{pts[0][1]:.1f}"]
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        p0 = pts[(i - 1) % n] if (closed or i > 0) else pts[i]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
        p3 = pts[(i + 2) % n] if (closed or i + 2 < n) else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d.append(f"C{c1[0]:.1f},{c1[1]:.1f} {c2[0]:.1f},{c2[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}")
    if closed:
        d.append("Z")
    return " ".join(d)


def continent():
    pts = []
    for i in range(48):
        a = i / 48 * 2 * math.pi
        r = 1 + 0.045 * math.sin(3 * a + 0.7) + 0.03 * math.sin(7 * a + 1.9) + 0.02 * math.sin(13 * a)
        pts.append((7300 * r * math.cos(a), -150 + 7150 * r * math.sin(a)))
    return pts


HUB = (0, -1500)

REGIONS = [
    # (id, nome, classe, pontos, posição do rótulo, perigosa)
    ("cordilheira", "Cordilheira Alta", "mountain", [(-6400, 3500), (-3000, 4100), (0, 3800), (3000, 4300), (5400, 3500), (6400, 5300), (4600, 6900), (800, 7300), (-3200, 7300), (-6600, 6400)], (900, 4900), False),
    ("gelo", "Picos Gelados", "snow", [(-7000, 4300), (-3100, 4500), (-2500, 7000), (-6400, 6900)], (-4700, 5550), True),
    ("floresta", "Floresta Densa", "forest", [(-5200, -3400), (-1800, -2700), (-1500, 900), (-2300, 3300), (-5100, 3300), (-5700, 0)], (-3200, 2300), False),
    ("canion", "Cânion Vulcânico", "volcanic", [(-7400, -3300), (-5400, -3500), (-5600, 0), (-5200, 2300), (-7100, 2100)], (-6450, -2300), True),
    ("prados", "Prados Centrais", "meadow", [(-1500, -500), (1700, -500), (2200, 1300), (1200, 3300), (-1900, 3000)], (300, 2350), False),
    ("encantada", "Floresta Encantada", "enchanted", [(2100, 1000), (4500, 800), (5000, 2700), (4000, 3600), (2200, 3500)], (3500, 3200), False),
    ("lago", "Grande Lago", "lakeland", [(2400, -3000), (5200, -3000), (5300, 500), (3000, 700), (2200, -800)], (4000, -2650), False),
    ("cristais", "Vale dos Cristais", "crystal", [(5600, -2300), (7300, -1600), (7400, 1900), (5900, 2700), (5500, 300)], (6500, 2150), True),
    ("pantano", "Pântano", "swamp", [(1400, -3600), (4900, -3200), (5500, -5300), (3600, -6500), (1500, -5900)], (3700, -5850), False),
    ("pantano_core", "", "swampcore", [(2800, -4600), (4600, -4200), (4800, -5600), (3500, -6100)], None, True),
    ("sul", "Prados do Sul e Costa", "coast", [(-4300, -3500), (1300, -3500), (1400, -5900), (0, -6900), (-3900, -6700)], (-2300, -5250), False),
    ("ruinas", "Planalto das Ruínas", "ruins", [(4000, 3100), (5700, 3200), (5800, 4900), (4100, 4900)], (5250, 4750), True),
    ("coroa", "Coroa do Dragão", "castle", [(2300, 4900), (4300, 4700), (5000, 5600), (4400, 6800), (2600, 7000), (1900, 6000)], (3150, 5350), True),
]

LAKE = [(2900, -1400), (3600, -600), (4600, -650), (5100, -1300), (4700, -2150), (3600, -2250)]
LAKE_ISLAND = [(4000, -1500), (4350, -1450), (4450, -1800), (4100, -1950), (3900, -1750)]

RIVERS = [
    ("Rio Principal", [(-3000, 5700), (-3300, 3000), (-3800, 700), (-3600, -1200), (-3000, -3200), (-2400, -5200), (-2200, -7000)], 7),
    ("", [(2900, -1350), (1600, -1300), (600, -1250)], 5),
    ("", [(600, -1250), (200, -1000), (-300, -1050), (-650, -1400)], 4),
    ("", [(600, -1250), (300, -1900), (-300, -1950), (-650, -1600)], 4),
    ("", [(-650, -1500), (-1500, -2200), (-2300, -3300), (-2700, -4600)], 4),
    ("", [(3200, 3700), (3500, 2200), (3700, 600), (3800, -650)], 3),
]

ROADS = [
    [HUB, (-300, -400), (-200, 700), (-1300, 3300), (-1500, 4300), (-800, 5000)],
    [(-1500, 4300), (-3000, 4800), (-4300, 5300)],
    [(-800, 5000), (300, 4500), (990, 4230)],
    [(750, 5130), (800, 5400)],
    [HUB, (-1200, -1000), (-2300, -700), (-3600, -900), (-4300, 800)],
    [(-3600, -900), (-4900, -700), (-5300, -300), (-6000, -400)],
    [HUB, (1200, -1200), (2300, -500), (3300, 200), (3400, 2300), (4300, 3300), (5200, 4400)],
    [(4300, 3300), (3300, 4100), (3300, 5500), (3600, 6000)],
    [(2300, -500), (2900, -900), (3700, -1550), (4150, -1700)],
    [(3300, 200), (4600, 100), (5000, -200), (5400, -100), (5500, 300), (6400, 600)],
    [HUB, (900, -2300), (1700, -2800), (2500, -4000), (3300, -4700)],
    [HUB, (-300, -2600), (-300, -3700), (-1000, -5000), (-1800, -6200), (-900, -6600)],
    [HUB, (-1100, -2300), (-2600, -2900), (-3400, -3000), (-4700, -2700)],
]

# (nº, nome, x, y, faixa)
FARMS = [
    (1, "Riacho", -300, -3700, "inner"),
    (2, "Pinheiral", -2300, -700, "inner"),
    (3, "Beira-Lago", 2300, -500, "inner"),
    (4, "Colina das Flores", -200, 700, "inner"),
    (5, "Moinho", 1700, -2800, "inner"),
    (6, "Raízes Antigas", -2600, -2900, "inner"),
    (7, "Cascata do Oeste", -4300, 800, "mid"),
    (8, "Bosque Encantado", 3400, 2300, "mid"),
    (9, "Mirante do Penhasco", -1300, 3300, "mid"),
    (10, "Ilha do Lago", 4200, -1700, "mid"),
    (11, "Brejo", 3300, -4700, "mid"),
    (12, "Costa", -1800, -6200, "mid"),
    (13, "Garganta Rubra", -4700, -2700, "mid"),
    (14, "Geleira", -4300, 5300, "outer"),
    (15, "Fontes Termais", -6000, -400, "outer"),
    (16, "Cristalina", 5500, 300, "outer"),
    (17, "Ruínas Antigas", 5200, 4400, "outer"),
    (18, "Vale Oculto", 800, 5400, "outer"),
]

CHOKEPOINTS = [
    ("Ponte do Rio", -3600, -900, (14, 22)),
    ("Ponte da Fenda", -5300, -300, (14, -12)),
    ("Passo", -1500, 4300, (-10, -14)),
    ("Túnel de Gelo", -3000, 4800, (14, 4)),
    ("Ponte da Ilha", 3700, -1550, (-12, 24)),
    ("Desfiladeiro", 5400, -100, (14, 22)),
    ("Passarelas", 2500, -4000, (-14, 20)),
    ("Caverna", 300, 5800, (-14, 4)),
    ("Serpentina", 3300, 5000, (14, 4)),
]

LANDMARKS = [
    ("Árvore-Mãe", -3200, 1300),
    ("Vulcão", -6500, -800),
    ("Pico Branco", -4800, 6500),
    ("Cachoeira Grande", 3700, 400),
    ("Pilar de Cristal", 6600, 300),
    ("Árvore de Luz", 3300, 2800),
    ("Farol", -700, -6800),
    ("Cúpula das Ruínas", 5300, 3900),
    ("Castelo dos Dragões", 3600, 6000),
]

CAMPS = [
    ("Acamp. do Rio", -3200, -1600),
    ("Acamp. da Fenda", -4900, -700),
    ("Acamp. do Passo", -900, 3700),
    ("Acamp. do Lago", 2700, 0),
    ("Acamp. do Sul", -1000, -5000),
    ("Acamp. do Brejo", 1900, -4900),
    ("Acamp. do Nordeste", 3200, 4000),
]

# (nome, x, y, altura em studs, raio aproximado)
SKY_ISLANDS = [
    ("Arquipélago Celeste", 1300, 2300, 520, 170),
    ("Arquipélago Celeste", 1900, 2700, 640, 130),
    ("Arquipélago Celeste", 900, 2900, 760, 110),
    ("Ilha dos Ventos do Sul", -3000, -4700, 480, 160),
    ("Ilha da Bruma", 2100, -5900, 500, 140),
    ("Ilha do Gelo Eterno", -5600, 3600, 950, 150),
    ("Ilha das Brasas", -6600, -2600, 600, 130),
    ("Ilha de Cristal", 6500, -1600, 700, 140),
    ("Ilha da Guarda", 2400, 5200, 1100, 120),
]

WAYPOINTS = [
    ("Pico Branco", -4600, 6000),
    ("Vulcão", -6200, -1300),
    ("Farol", -900, -6600),
    ("Pilar de Cristal", 6400, 600),
    ("Cúpula das Ruínas", 5300, 3900),
    ("Portão do Castelo", 3300, 5500),
    ("Coração do Pântano", 3900, -5600),
    ("Cachoeira Grande", 3700, 500),
]

DUNGEON = (-700, 5400)

LIGHT = {
    "sea": "#BFD3D6", "land": "#DCE3CF", "forest": "#9DB98A", "meadow": "#D3DDB0", "mountain": "#B9B4A6",
    "snow": "#EEF1F2", "volcanic": "#C9A08C", "enchanted": "#C8B6DA", "crystal": "#B7D3E4", "swamp": "#AFB997",
    "swampcore": "#8F9C78", "coast": "#E2D6AE", "ruins": "#CFC2A8", "castle": "#9A9097", "sky": "#FFFFFF", "waypoint": "#3C6FA8", "lakeland": "#C5D7B5", "water": "#7FA8BC",
    "ink": "#1F2A2B", "muted": "#566362", "road": "#7A5B3A", "danger": "#B5452F", "inner": "#2F6F62",
    "mid": "#B07A1E", "outer": "#8E3B5F", "paper": "#F5F6F1",
}


def svg_markup(themed=True):
    def c(name):
        return f"var(--map-{name})" if themed else LIGHT[name]

    out = []
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {W}" role="img" aria-labelledby="mapTitle mapDesc" class="worldmap">')
    out.append('<title id="mapTitle">Mapa conceitual das Terras de Escamarra</title>')
    out.append('<desc id="mapDesc">Continente de cerca de 14 mil studs com o Hub numa ilha fluvial no centro-sul, 18 fazendas espalhadas a pelo menos 2.100 studs umas das outras, biomas, rios, estradas, passagens, marcos, acampamentos, waypoints, ilhas flutuantes, o Castelo dos Dragões e zonas perigosas.</desc>')
    out.append("<defs>")
    out.append(f'<pattern id="hatch" width="14" height="14" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="14" height="14" fill="none"/><line x1="0" y1="0" x2="0" y2="14" stroke="{c("danger")}" stroke-width="3" stroke-opacity="0.55"/></pattern>')
    out.append(f'<clipPath id="land"><path d="{smooth_path(continent())}"/></clipPath>')
    out.append("</defs>")
    out.append(f'<rect width="{W}" height="{W}" fill="{c("sea")}"/>')
    # grade de 2.048 studs (blocos de construção)
    for k in range(-3, 4):
        v = k * 2048
        x1, _ = P(v, 0)
        _, y1 = P(0, v)
        out.append(f'<line x1="{x1:.1f}" y1="0" x2="{x1:.1f}" y2="{W}" stroke="{c("ink")}" stroke-opacity="0.07" stroke-width="1"/>')
        out.append(f'<line x1="0" y1="{y1:.1f}" x2="{W}" y2="{y1:.1f}" stroke="{c("ink")}" stroke-opacity="0.07" stroke-width="1"/>')
    out.append(f'<path d="{smooth_path(continent())}" fill="{c("land")}" stroke="{c("ink")}" stroke-opacity="0.35" stroke-width="2"/>')
    out.append('<g clip-path="url(#land)">')
    for rid, name, cls, pts, lab, danger in REGIONS:
        out.append(f'<path d="{smooth_path(pts)}" fill="{c(cls)}" stroke="{c("ink")}" stroke-opacity="0.18" stroke-width="1.5"><title>{name or "Coração do Pântano"}</title></path>')
    for rid, name, cls, pts, lab, danger in REGIONS:
        if danger:
            out.append(f'<path d="{smooth_path(pts)}" fill="url(#hatch)"/>')
    out.append("</g>")
    # penhascos do leste
    cliff = [P(5300, -2600), P(5250, -800), P(5350, 800), P(5300, 2800)]
    out.append('<polyline points="' + " ".join(f"{a:.1f},{b:.1f}" for a, b in cliff) + f'" fill="none" stroke="{c("ink")}" stroke-width="5" stroke-dasharray="2 6" stroke-linecap="round" opacity="0.6"/>')
    # lago e ilha
    out.append(f'<path d="{smooth_path(LAKE)}" fill="{c("water")}" stroke="{c("ink")}" stroke-opacity="0.25"/>')
    out.append(f'<path d="{smooth_path(LAKE_ISLAND)}" fill="{c("forest")}" stroke="{c("ink")}" stroke-opacity="0.3"/>')
    # rios
    for name, pts, wdt in RIVERS:
        out.append(f'<path d="{smooth_path(pts, closed=False)}" fill="none" stroke="{c("water")}" stroke-width="{wdt}" stroke-linecap="round"/>')
    # estradas
    for pts in ROADS:
        out.append(f'<path d="{smooth_path(pts, closed=False)}" fill="none" stroke="{c("road")}" stroke-width="2.6" stroke-dasharray="9 6" stroke-linecap="round" opacity="0.85"/>')
    # rótulos de região
    for rid, name, cls, pts, lab, danger in REGIONS:
        if lab and name:
            x, y = P(*lab)
            out.append(f'<text x="{x:.1f}" y="{y:.1f}" class="m-region" text-anchor="middle" fill="{c("ink")}">{name.upper()}</text>')
    x, y = P(-2800, 2600)
    out.append(f'<text x="{x:.1f}" y="{y:.1f}" class="m-river" fill="{c("muted")}" transform="rotate(-80 {x:.1f} {y:.1f})">Rio Principal</text>')
    # zona protegida do Hub
    hx, hy = P(*HUB)
    out.append(f'<ellipse cx="{hx:.1f}" cy="{hy:.1f}" rx="58" ry="46" fill="{c("paper")}" fill-opacity="0.55" stroke="{c("inner")}" stroke-width="2.5" stroke-dasharray="6 4"/>')
    out.append(f'<circle cx="{hx:.1f}" cy="{hy:.1f}" r="15" fill="{c("ink")}"/><circle cx="{hx:.1f}" cy="{hy:.1f}" r="6" fill="{c("paper")}"/>')
    out.append(f'<text x="{hx:.1f}" y="{hy + 66:.1f}" class="m-hub" text-anchor="middle" fill="{c("ink")}">HUB · ILHA DO CORAÇÃO</text>')
    # acampamentos
    for name, x0, y0 in CAMPS:
        x, y = P(x0, y0)
        out.append(f'<g><title>{name} (zona protegida pequena)</title><path d="M{x - 8:.1f},{y + 6:.1f} L{x:.1f},{y - 8:.1f} L{x + 8:.1f},{y + 6:.1f} Z" fill="{c("paper")}" stroke="{c("inner")}" stroke-width="2"/></g>')
    # estreitamentos
    for name, x0, y0, (dx, dy) in CHOKEPOINTS:
        x, y = P(x0, y0)
        out.append(f'<g><title>{name}</title><rect x="{x - 6:.1f}" y="{y - 6:.1f}" width="12" height="12" transform="rotate(45 {x:.1f} {y:.1f})" fill="{c("paper")}" stroke="{c("ink")}" stroke-width="2"/>')
        anchor = "start" if dx > 0 else "end"
        out.append(f'<text x="{x + dx:.1f}" y="{y + dy:.1f}" class="m-small" text-anchor="{anchor}" fill="{c("ink")}">{name}</text></g>')
    # marcos
    for name, x0, y0 in LANDMARKS:
        x, y = P(x0, y0)
        s = 9
        star = " ".join(
            f"{x + (s if i % 2 == 0 else s * 0.42) * math.cos(-math.pi / 2 + i * math.pi / 5):.1f},{y + (s if i % 2 == 0 else s * 0.42) * math.sin(-math.pi / 2 + i * math.pi / 5):.1f}"
            for i in range(10)
        )
        out.append(f'<g><title>Marco: {name}</title><polygon points="{star}" fill="{c("ink")}"/>')
        out.append(f'<text x="{x:.1f}" y="{y + 22:.1f}" class="m-small m-italic" text-anchor="middle" fill="{c("muted")}">{name}</text></g>')
    # dungeon (escondida)
    dx_, dy_ = P(*DUNGEON)
    out.append(f'<g><title>Portão da dungeon (sem marcador no jogo)</title><circle cx="{dx_:.1f}" cy="{dy_:.1f}" r="12" fill="{c("paper")}" stroke="{c("danger")}" stroke-width="2.5" stroke-dasharray="3 3"/>')
    out.append(f'<text x="{dx_:.1f}" y="{dy_ + 5:.1f}" class="m-farm" text-anchor="middle" fill="{c("danger")}">?</text>')
    out.append(f'<text x="{dx_ + 18:.1f}" y="{dy_ + 5:.1f}" class="m-small" fill="{c("danger")}">dungeon</text></g>')
    # waypoints
    for name, x0, y0 in WAYPOINTS:
        x, y = P(x0, y0)
        out.append(f'<g><title>Waypoint: {name}</title><path d="M{x - 5:.1f},{y + 8:.1f} L{x - 3:.1f},{y - 10:.1f} L{x:.1f},{y - 14:.1f} L{x + 3:.1f},{y - 10:.1f} L{x + 5:.1f},{y + 8:.1f} Z" fill="{c("waypoint")}" stroke="{c("paper")}" stroke-width="1.5"/></g>')
    # ilhas flutuantes
    for name, x0, y0, alt, r in SKY_ISLANDS:
        x, y = P(x0, y0)
        rr = r / 10.0
        out.append(f'<g><title>{name} · ilha flutuante a {alt} studs, com comida e água</title>')
        out.append(f'<ellipse cx="{x + 4:.1f}" cy="{y + 7:.1f}" rx="{rr:.1f}" ry="{rr * 0.7:.1f}" fill="{c("ink")}" fill-opacity="0.18"/>')
        out.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rr:.1f}" ry="{rr * 0.7:.1f}" fill="{c("sky")}" stroke="{c("waypoint")}" stroke-width="2" stroke-dasharray="4 3"/>')
        out.append(f'<circle cx="{x + rr * 0.2:.1f}" cy="{y - rr * 0.1:.1f}" r="{max(2.5, rr * 0.28):.1f}" fill="{c("water")}"/></g>')
    # fazendas
    for num, name, x0, y0, ring in FARMS:
        x, y = P(x0, y0)
        out.append(f'<g class="farm"><title>Fazenda {num} · {name}</title>')
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="24" fill="{c(ring)}" fill-opacity="0.18"/>')
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="13" fill="{c(ring)}" stroke="{c("paper")}" stroke-width="2.5"/>')
        out.append(f'<text x="{x:.1f}" y="{y + 5:.1f}" class="m-farm" text-anchor="middle" fill="{c("paper")}">{num}</text></g>')
    # escala e norte
    sx, sy = 70, 1540
    out.append(f'<g><rect x="{sx}" y="{sy}" width="100" height="8" fill="{c("ink")}"/><rect x="{sx + 100}" y="{sy}" width="100" height="8" fill="{c("paper")}" stroke="{c("ink")}" stroke-width="1.5"/>')
    out.append(f'<text x="{sx}" y="{sy - 8}" class="m-small" fill="{c("ink")}">0</text><text x="{sx + 100}" y="{sy - 8}" class="m-small" text-anchor="middle" fill="{c("ink")}">1.000</text><text x="{sx + 200}" y="{sy - 8}" class="m-small" text-anchor="middle" fill="{c("ink")}">2.000 studs</text></g>')
    nx, ny = 1525, 90
    out.append(f'<g><polygon points="{nx},{ny - 34} {nx + 12},{ny + 6} {nx},{ny - 2} {nx - 12},{ny + 6}" fill="{c("ink")}"/><text x="{nx}" y="{ny + 30}" class="m-region" text-anchor="middle" fill="{c("ink")}">N</text></g>')
    out.append("</svg>")
    return "\n".join(out)


STANDALONE_STYLE = """<style>
.m-region{font:600 15px Georgia,serif;letter-spacing:.14em}
.m-hub{font:700 16px Georgia,serif;letter-spacing:.12em}
.m-small{font:13px Georgia,serif}
.m-italic{font-style:italic}
.m-river{font:italic 14px Georgia,serif}
.m-farm{font:700 14px Georgia,serif}
</style>"""

if __name__ == "__main__":
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    svg = svg_markup(themed=False).replace("<defs>", STANDALONE_STYLE + "<defs>", 1)
    os.makedirs(os.path.join(root, "docs"), exist_ok=True)
    with open(os.path.join(root, "docs", "world-map-concept.svg"), "w", encoding="utf-8") as f:
        f.write(svg)
    print("docs/world-map-concept.svg gerado")
