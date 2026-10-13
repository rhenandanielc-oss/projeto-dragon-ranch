--!strict
-- Dados do mundo aberto (WORLD-DESIGN.md v0.2). Coordenadas do mapa em studs:
-- x = leste, y = norte, origem no centro. No Roblox: X = x, Z = -y.
-- Usado pelo gerador de terreno (WorldGen) e pelos construtores de conteúdo.

local WorldData = {}

WorldData.SIZE = 16000 -- lado do mundo (de -8000 a 8000)
WorldData.SEA_LEVEL = 0

-- Contorno do continente (mesma fórmula do mapa conceitual)
WorldData.CONTINENT = { rx = 7300, ry = 7150, cy = -150 }

-- Parâmetros de relevo por região:
--   B  altura base          Ah colinas (escala 1100)   Am morros (escala 320)
--   Ar cristas de montanha  Ad detalhe (escala 70)      Ac cânions (cortes)
--   blur raio da transição em células de 32 studs (menor = borda mais íngreme)
WorldData.REGION_PARAMS = {
	land = { B = 32, Ah = 34, Am = 10, Ar = 0, Ad = 2, Ac = 0, blur = 8 },
	mountain = { B = 230, Ah = 120, Am = 45, Ar = 620, Ad = 6, Ac = 0, blur = 10 },
	snow = { B = 350, Ah = 140, Am = 55, Ar = 720, Ad = 6, Ac = 0, blur = 10 },
	forest = { B = 46, Ah = 48, Am = 20, Ar = 0, Ad = 2.5, Ac = 0, blur = 8 },
	volcanic = { B = 95, Ah = 50, Am = 30, Ar = 70, Ad = 5, Ac = 120, blur = 6 },
	meadow = { B = 38, Ah = 44, Am = 16, Ar = 0, Ad = 1.5, Ac = 0, blur = 8 },
	enchanted = { B = 54, Ah = 52, Am = 26, Ar = 0, Ad = 3, Ac = 0, blur = 8 },
	lakeland = { B = 26, Ah = 14, Am = 7, Ar = 0, Ad = 1.5, Ac = 0, blur = 8 },
	crystal = { B = 165, Ah = 45, Am = 30, Ar = 60, Ad = 4, Ac = 0, blur = 3 },
	swamp = { B = 8, Ah = 4, Am = 5, Ar = 0, Ad = 1.2, Ac = 0, blur = 8 },
	swampcore = { B = 4.5, Ah = 3, Am = 6, Ar = 0, Ad = 1, Ac = 0, blur = 6 },
	coast = { B = 24, Ah = 24, Am = 10, Ar = 0, Ad = 1.5, Ac = 0, blur = 8 },
	ruins = { B = 150, Ah = 22, Am = 12, Ar = 0, Ad = 2, Ac = 0, blur = 3 },
	castle = { B = 250, Ah = 80, Am = 40, Ar = 280, Ad = 6, Ac = 0, blur = 6 },
	lake = { B = -28, Ah = 0, Am = 4, Ar = 0, Ad = 1, Ac = 0, blur = 7 },
}

-- Ordem importa: regiões posteriores sobrepõem as anteriores.
WorldData.REGIONS = {
	{ id = "mountain", name = "Cordilheira Alta", danger = false, pts = { { -6400, 3500 }, { -3000, 4100 }, { 0, 3800 }, { 3000, 4300 }, { 5400, 3500 }, { 6400, 5300 }, { 4600, 6900 }, { 800, 7300 }, { -3200, 7300 }, { -6600, 6400 } } },
	{ id = "snow", name = "Picos Gelados", danger = true, pts = { { -7000, 4300 }, { -3100, 4500 }, { -2500, 7000 }, { -6400, 6900 } } },
	{ id = "forest", name = "Floresta Densa", danger = false, pts = { { -5200, -3400 }, { -1800, -2700 }, { -1500, 900 }, { -2300, 3300 }, { -5100, 3300 }, { -5700, 0 } } },
	{ id = "volcanic", name = "Cânion Vulcânico", danger = true, pts = { { -7400, -3300 }, { -5400, -3500 }, { -5600, 0 }, { -5200, 2300 }, { -7100, 2100 } } },
	{ id = "meadow", name = "Prados Centrais", danger = false, pts = { { -1500, -500 }, { 1700, -500 }, { 2200, 1300 }, { 1200, 3300 }, { -1900, 3000 } } },
	{ id = "enchanted", name = "Floresta Encantada", danger = false, pts = { { 2100, 1000 }, { 4500, 800 }, { 5000, 2700 }, { 4000, 3600 }, { 2200, 3500 } } },
	{ id = "lakeland", name = "Grande Lago", danger = false, pts = { { 2400, -3000 }, { 5200, -3000 }, { 5300, 500 }, { 3000, 700 }, { 2200, -800 } } },
	{ id = "crystal", name = "Vale dos Cristais", danger = true, pts = { { 5600, -2300 }, { 7300, -1600 }, { 7400, 1900 }, { 5900, 2700 }, { 5500, 300 } } },
	{ id = "swamp", name = "Pântano", danger = false, pts = { { 1400, -3600 }, { 4900, -3200 }, { 5500, -5300 }, { 3600, -6500 }, { 1500, -5900 } } },
	{ id = "swampcore", name = "Coração do Pântano", danger = true, pts = { { 2800, -4600 }, { 4600, -4200 }, { 4800, -5600 }, { 3500, -6100 } } },
	{ id = "coast", name = "Prados do Sul e Costa", danger = false, pts = { { -4300, -3500 }, { 1300, -3500 }, { 1400, -5900 }, { 0, -6900 }, { -3900, -6700 } } },
	{ id = "ruins", name = "Planalto das Ruínas", danger = true, pts = { { 4000, 3100 }, { 5700, 3200 }, { 5800, 4900 }, { 4100, 4900 } } },
	{ id = "castle", name = "Coroa do Dragão", danger = true, pts = { { 2300, 4900 }, { 4300, 4700 }, { 5000, 5600 }, { 4400, 6800 }, { 2600, 7000 }, { 1900, 6000 } } },
	{ id = "lake", name = "Grande Lago", danger = false, pts = { { 2900, -1400 }, { 3600, -600 }, { 4600, -650 }, { 5100, -1300 }, { 4700, -2150 }, { 3600, -2250 } } },
}

WorldData.LAKE_LEVEL = 12
WorldData.SWAMP_LEVEL = 4

-- Rios: hw = meia-largura do leito, depth = profundidade; pontos {x, y, nível da água}
WorldData.RIVERS = {
	{ name = "Rio Principal", hw = 34, depth = 14, pts = { { -3000, 5700, 250 }, { -3300, 3000, 42 }, { -3800, 700, 26 }, { -3600, -1200, 17 }, { -3000, -3200, 9 }, { -2400, -5200, 3 }, { -2200, -7000, 0 }, { -2150, -7700, 0 } } },
	{ name = "Rio do Lago", hw = 26, depth = 11, pts = { { 3000, -1360, 12 }, { 1600, -1300, 8.5 }, { 700, -1260, 6 } } },
	{ name = "Rio do Sudoeste", hw = 24, depth = 10, pts = { { -650, -1650, 6 }, { -1500, -2200, 5.4 }, { -2300, -3300, 4.6 }, { -2560, -4650, 4.2 } } },
	{ name = "Rio das Cachoeiras", hw = 20, depth = 9, pts = { { 3200, 3700, 70 }, { 3500, 2200, 42 }, { 3700, 800, 30 }, { 3720, 450, 29 }, { 3732, 352, 29 }, { 3742, 326, 13 }, { 3760, 260, 13 }, { 3800, -650, 12 } } },
}

-- Estradas e trilhas (meia-largura 7 studs)
WorldData.ROAD_HW = 7
local HUB = { 0, -1500 }
WorldData.ROADS = {
	{ HUB, { -300, -400 }, { -200, 700 }, { -1300, 3300 }, { -1500, 4300 }, { -800, 5000 } },
	{ { -1500, 4300 }, { -3000, 4800 }, { -4300, 5300 } },
	{ { -800, 5000 }, { 300, 4500 }, { 990, 4230 } },
	{ { 750, 5130 }, { 800, 5400 } }, -- dentro do Vale Oculto (saída da caverna)
	{ HUB, { -1200, -1000 }, { -2300, -700 }, { -3600, -900 }, { -4300, 800 } },
	{ { -3600, -900 }, { -4900, -700 }, { -5300, -300 }, { -6000, -400 } },
	{ HUB, { 1200, -1200 }, { 2300, -500 }, { 3300, 200 }, { 3400, 2300 }, { 4300, 3300 }, { 5200, 4400 } },
	{ { 4300, 3300 }, { 3300, 4100 }, { 3300, 5500 }, { 3600, 6000 } },
	{ { 2300, -500 }, { 2900, -900 }, { 3700, -1550 }, { 4200, -1700 } },
	{ { 3300, 200 }, { 4600, 100 }, { 5000, -200 }, { 5400, -100 }, { 5500, 300 }, { 6400, 600 } },
	{ HUB, { 900, -2300 }, { 1700, -2800 }, { 2500, -4000 }, { 3300, -4700 } },
	{ HUB, { -300, -2600 }, { -300, -3700 }, { -1000, -5000 }, { -1800, -6200 }, { -900, -6600 } },
	{ HUB, { -1100, -2300 }, { -2600, -2900 }, { -3400, -3000 }, { -4700, -2700 } },
}

WorldData.HUB = { x = 0, y = -1500, r0 = 320, r1 = 470, target = 16 }

-- Baía do Coração: o Hub vira uma ilha no meio de uma baía grande (rio do lago entra pelo leste,
-- rio do sudoeste sai pelo sudoeste). Fundo raso de areia perto das margens (água turquesa e
-- transparente) e fundo escuro no meio (azul profundo).
WorldData.BAY = { name = "Baía do Coração", x = 0, y = -1500, rIsland = 530, rShore = 980, level = 6 }

-- Pontes grandes: uma por estrada que sai do Hub (na ordem das estradas em ROADS)
WorldData.GRAND_BRIDGES = {
	{ name = "Ponte do Dragão", accent = { 90, 170, 255 } }, -- norte (Prados, Cordilheira)
	{ name = "Ponte da Floresta", accent = { 100, 230, 150 } }, -- oeste (Floresta Densa)
	{ name = "Ponte do Lago", accent = { 80, 220, 235 } }, -- leste (Grande Lago, Cristais)
	{ name = "Ponte dos Mercadores", accent = { 255, 190, 90 } }, -- sudeste (Moinho, Pântano)
	{ name = "Ponte do Farol", accent = { 120, 200, 255 } }, -- sul (Costa, Farol)
	{ name = "Ponte Celeste", accent = { 175, 115, 255 } }, -- sudoeste (Garganta Rubra)
}
WorldData.BRIDGE_WIDTH = 46

-- Bosques fechados especiais (floresta densa forçada, com borda aberta numa direção)
WorldData.DENSE_GROVES = {
	{ name = "Bosque Escondido", x = -1250, y = 3630, r = 650, openDir = { 1, -0.35 }, kit = "pine", giant = 1.3 },
}

-- Fazendas: tier 1 = faixa interna (novatos), 2 = média, 3 = externa
WorldData.FARMS = {
	{ id = 1, name = "Riacho", x = -300, y = -3700, tier = 1, biome = "meadow" },
	{ id = 2, name = "Pinheiral", x = -2300, y = -700, tier = 1, biome = "pine" },
	{ id = 3, name = "Beira-Lago", x = 2300, y = -500, tier = 1, biome = "lake" },
	{ id = 4, name = "Colina das Flores", x = -200, y = 700, tier = 1, biome = "blossom" },
	{ id = 5, name = "Moinho", x = 1700, y = -2800, tier = 1, biome = "orchard" },
	{ id = 6, name = "Raízes Antigas", x = -2600, y = -2900, tier = 1, biome = "oak" },
	{ id = 7, name = "Cascata do Oeste", x = -4300, y = 800, tier = 2, biome = "rainforest" },
	{ id = 8, name = "Bosque Encantado", x = 3400, y = 2300, tier = 2, biome = "enchanted" },
	{ id = 9, name = "Mirante do Penhasco", x = -1300, y = 3300, tier = 2, biome = "fir" },
	{ id = 10, name = "Ilha do Lago", x = 4200, y = -1700, tier = 2, biome = "lake", target = 20 },
	{ id = 11, name = "Brejo", x = 3300, y = -4700, tier = 2, biome = "swamp", target = 9 },
	{ id = 12, name = "Costa", x = -1800, y = -6200, tier = 2, biome = "coast" },
	{ id = 13, name = "Garganta Rubra", x = -4700, y = -2700, tier = 2, biome = "redrock" },
	{ id = 14, name = "Geleira", x = -4300, y = 5300, tier = 3, biome = "snow" },
	{ id = 15, name = "Fontes Termais", x = -6000, y = -400, tier = 3, biome = "volcanic" },
	{ id = 16, name = "Cristalina", x = 5500, y = 300, tier = 3, biome = "crystal" },
	{ id = 17, name = "Ruínas Antigas", x = 5200, y = 4400, tier = 3, biome = "ruins" },
	{ id = 18, name = "Vale Oculto", x = 800, y = 5400, tier = 3, biome = "hidden" },
}
WorldData.FARM_R0 = 150 -- raio plano (interior de 200 x 200)
WorldData.FARM_R1 = 330 -- fim da transição para o relevo natural

-- Acampamentos para dragões: ao lado das estradas (o portão fica virado para a estrada)
WorldData.CAMPS = {
	{ name = "Acampamento do Rio", x = -3297, y = -970 },
	{ name = "Acampamento da Fenda", x = -4917, y = -814 },
	{ name = "Acampamento do Passo", x = -1249, y = 3630 },
	{ name = "Acampamento do Lago", x = 2737, y = -53 },
	{ name = "Acampamento do Sul", x = -899, y = -5055 },
	{ name = "Acampamento do Brejo", x = 2530, y = -4179 },
	{ name = "Acampamento do Nordeste", x = 3372, y = 4190 },
}
WorldData.CAMP_R0 = 92 -- área plana do acampamento
WorldData.CAMP_R1 = 160

WorldData.WAYPOINTS = {
	{ name = "Pico Branco", x = -4600, y = 6000 },
	{ name = "Vulcão", x = -6200, y = -1300 },
	{ name = "Farol", x = -900, y = -6600 },
	{ name = "Pilar de Cristal", x = 6400, y = 600 },
	{ name = "Cúpula das Ruínas", x = 5300, y = 3900 },
	{ name = "Portão do Castelo", x = 3300, y = 5500 },
	{ name = "Coração do Pântano", x = 3900, y = -5600 },
	{ name = "Cachoeira Grande", x = 3700, y = 500 },
}

WorldData.DUNGEON = { x = -700, y = 5400, r0 = 70, r1 = 190, depth = 170 }

-- Relevos especiais. kind: "cone" (pico), "mesa" (rochedo de topo plano), "hill"
WorldData.SHAPES = {
	{ name = "Vulcão", kind = "cone", x = -6500, y = -800, R = 1500, H = 760, exp = 1.4, crater = 150, craterDepth = 130 },
	{ name = "Pico Branco", kind = "cone", x = -4800, y = 6500, R = 1000, H = 460, exp = 1.3 },
	{ name = "Rochedo do Castelo", kind = "mesa", x = 3600, y = 6000, top = 620, rTop = 200, R = 560 },
	{ name = "Colina da Árvore-Mãe", kind = "hill", x = -3200, y = 1300, R = 450, H = 70 },
	{ name = "Pilar de Cristal", kind = "cone", x = 6600, y = 300, R = 380, H = 260, exp = 2.2 },
	{ name = "Paredão da Cachoeira Grande", kind = "hill", x = 3700, y = 560, R = 340, H = 48 },
}

-- Ilhas flutuantes: centro (x, y), altitude do topo, raio
-- Mirantes da cordilheira (vista panorâmica): ponto aproximado e direção da vista (x, y)
WorldData.LOOKOUTS = {
	{ name = "Mirante do Passo", x = -1500, y = 4150, vx = 0, vy = -1 },
	{ name = "Mirante do Pico Branco", x = -4300, y = 5900, vx = 0.3, vy = -1 },
	{ name = "Mirante da Encosta", x = 900, y = 4300, vx = 0, vy = -1 },
	{ name = "Mirante da Serpentina", x = 3100, y = 5150, vx = -0.4, vy = -1 },
}

-- Túneis escavados na montanha (pontos aproximados nas duas pontas; o construtor acha a boca)
WorldData.TUNNELS = {
	{ name = "Túnel de Gelo", a = { -2800, 5000 }, b = { -4200, 5250 }, ice = true },
	{ name = "Caverna do Vale Oculto", a = { 1000, 4200 }, b = { 700, 5300 }, ice = false },
}

WorldData.GREAT_WATERFALL = { x = 3738, y = 338, top = 29, bottom = 13, width = 44 }

WorldData.SKY_ISLANDS = {
	{ name = "Arquipélago Celeste I", x = 1300, y = 2300, alt = 520, r = 170 },
	{ name = "Arquipélago Celeste II", x = 1900, y = 2700, alt = 640, r = 130 },
	{ name = "Arquipélago Celeste III", x = 900, y = 2900, alt = 760, r = 110 },
	{ name = "Ilha dos Ventos do Sul", x = -3000, y = -4700, alt = 480, r = 160 },
	{ name = "Ilha da Bruma", x = 2100, y = -5900, alt = 500, r = 140 },
	{ name = "Ilha do Gelo Eterno", x = -5600, y = 3600, alt = 1300, r = 150 },
	{ name = "Ilha das Brasas", x = -6600, y = -2600, alt = 900, r = 130 },
	{ name = "Ilha de Cristal", x = 6500, y = -1600, alt = 800, r = 140 },
	{ name = "Ilha da Guarda", x = 2400, y = 5200, alt = 1150, r = 120 },
	{ name = "Ilha do Bosque", x = -250, y = 3250, alt = 400, r = 95 }, -- vista das clareiras do Bosque Escondido
}

return WorldData
