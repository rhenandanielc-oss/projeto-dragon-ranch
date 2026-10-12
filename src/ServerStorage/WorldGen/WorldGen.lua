--!native
--!optimize 2
-- Gerador do relevo das Terras de Escamarra.
-- Código puro (sem APIs do Roblox além de math/buffer): roda no Studio e no Luau de
-- linha de comando (para gerar prévias do mapa fora do Studio).
--
-- Uso:
--   local gen = WorldGen.new(WorldData)
--   local chunk = gen:computeChunk(x0, y0, n)  -- n x n colunas de 4 studs a partir de (x0, y0)
-- Coordenadas do mapa: x = leste, y = norte (no Roblox Z = -y).

local WorldGen = {}
WorldGen.__index = WorldGen

local CELL = 32 -- grade grossa de parâmetros
local VOX = 4 -- resolução do terreno

local floor, abs, sqrt, min, max, atan2, sin, cos = math.floor, math.abs, math.sqrt, math.min, math.max, math.atan2, math.sin, math.cos
local noise = math.noise

-- Materiais (ids numéricos; o escritor do Studio converte para Enum.Material)
local M = {
	Grass = 1, LeafyGrass = 2, Ground = 3, Rock = 4, Slate = 5, Snow = 6, Glacier = 7, Sand = 8, Mud = 9,
	Basalt = 10, CrackedLava = 11, Limestone = 12, Sandstone = 13, Cobblestone = 14, Salt = 15, Ice = 16, Pavement = 17,
}
WorldGen.MATERIALS = M
WorldGen.MATERIAL_NAMES = {}
for name, id in pairs(M) do
	WorldGen.MATERIAL_NAMES[id] = name
end

local function clamp01(t: number): number
	return if t < 0 then 0 elseif t > 1 then 1 else t
end

local function smoothstep(a: number, b: number, x: number): number
	local t = clamp01((x - a) / (b - a))
	return t * t * (3 - 2 * t)
end

-- Curva Catmull-Rom fechada (mesma do mapa conceitual), amostrada em pontos
local function sampleClosed(pts, perSeg: number)
	local out = {}
	local n = #pts
	for i = 1, n do
		local p0 = pts[(i - 2) % n + 1]
		local p1 = pts[i]
		local p2 = pts[i % n + 1]
		local p3 = pts[(i + 1) % n + 1]
		for s = 0, perSeg - 1 do
			local t = s / perSeg
			local t2, t3 = t * t, t * t * t
			local x = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
			local y = 0.5 * ((2 * p1[2]) + (-p0[2] + p2[2]) * t + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t2 + (-p0[2] + 3 * p1[2] - 3 * p2[2] + p3[2]) * t3)
			table.insert(out, { x, y })
		end
	end
	return out
end
WorldGen.sampleClosed = sampleClosed

-- Curva Catmull-Rom aberta para rios e estradas; mantém o 3º valor (nível) interpolado
local function sampleOpen(pts, step: number)
	local out = {}
	local n = #pts
	for i = 1, n - 1 do
		local p0 = pts[max(1, i - 1)]
		local p1 = pts[i]
		local p2 = pts[i + 1]
		local p3 = pts[min(n, i + 2)]
		local len = sqrt((p2[1] - p1[1]) ^ 2 + (p2[2] - p1[2]) ^ 2)
		local k = max(1, floor(len / step))
		for s = 0, k - 1 do
			local t = s / k
			local t2, t3 = t * t, t * t * t
			local x = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
			local y = 0.5 * ((2 * p1[2]) + (-p0[2] + p2[2]) * t + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t2 + (-p0[2] + 3 * p1[2] - 3 * p2[2] + p3[2]) * t3)
			local l = (p1[3] or 0) + ((p2[3] or 0) - (p1[3] or 0)) * t
			table.insert(out, { x, y, l })
		end
	end
	local last = pts[n]
	table.insert(out, { last[1], last[2], last[3] or 0 })
	return out
end
WorldGen.sampleOpen = sampleOpen

--------------------------------------------------------------------------
-- Construção da grade grossa
--------------------------------------------------------------------------
local PARAM_KEYS = { "B", "Ah", "Am", "Ar", "Ad", "Ac" }

local function boxBlur(src: buffer, tmp: buffer, n: number, r: number)
	-- desfoque separável (média móvel), bordas repetidas; resultado em src
	local inv = 1 / (2 * r + 1)
	for pass = 1, 2 do
		-- horizontal: src -> tmp
		for j = 0, n - 1 do
			local row = j * n
			local acc = 0
			for k = -r, r do
				local i = if k < 0 then 0 elseif k > n - 1 then n - 1 else k
				acc += buffer.readf32(src, (row + i) * 4)
			end
			for i = 0, n - 1 do
				buffer.writef32(tmp, (row + i) * 4, acc * inv)
				local iOut = i - r
				local iIn = i + r + 1
				if iOut < 0 then iOut = 0 end
				if iIn > n - 1 then iIn = n - 1 end
				acc += buffer.readf32(src, (row + iIn) * 4) - buffer.readf32(src, (row + iOut) * 4)
			end
		end
		-- vertical: tmp -> src
		for i = 0, n - 1 do
			local acc = 0
			for k = -r, r do
				local j = if k < 0 then 0 elseif k > n - 1 then n - 1 else k
				acc += buffer.readf32(tmp, (j * n + i) * 4)
			end
			for j = 0, n - 1 do
				buffer.writef32(src, (j * n + i) * 4, acc * inv)
				local jOut = j - r
				local jIn = j + r + 1
				if jOut < 0 then jOut = 0 end
				if jIn > n - 1 then jIn = n - 1 end
				acc += buffer.readf32(tmp, (jIn * n + i) * 4) - buffer.readf32(tmp, (jOut * n + i) * 4)
			end
		end
	end
end

function WorldGen.new(data, yieldFn: (() -> ())?)
	local self = setmetatable({}, WorldGen)
	self.data = data
	local half = data.SIZE / 2
	self.origin = -half
	local n = floor(data.SIZE / CELL)
	self.n = n

	-- tipos de região: 1 = land (padrão) + os ids usados nas regiões
	local types = { "land" }
	local typeIndex = { land = 1 }
	for _, r in ipairs(data.REGIONS) do
		if not typeIndex[r.id] then
			table.insert(types, r.id)
			typeIndex[r.id] = #types
		end
	end
	self.types = types
	self.typeIndex = typeIndex

	-- rasterização por linhas de varredura
	local ids = buffer.create(n * n)
	buffer.fill(ids, 0, 1)
	for _, r in ipairs(data.REGIONS) do
		local poly = sampleClosed(r.pts, 10)
		local t = typeIndex[r.id]
		local m = #poly
		for j = 0, n - 1 do
			local yc = self.origin + (j + 0.5) * CELL
			local xs = {}
			for a = 1, m do
				local p, q = poly[a], poly[a % m + 1]
				if (p[2] <= yc and q[2] > yc) or (q[2] <= yc and p[2] > yc) then
					table.insert(xs, p[1] + (yc - p[2]) / (q[2] - p[2]) * (q[1] - p[1]))
				end
			end
			table.sort(xs)
			for k = 1, #xs - 1, 2 do
				local i0 = max(0, math.ceil((xs[k] - self.origin) / CELL - 0.5))
				local i1 = min(n - 1, floor((xs[k + 1] - self.origin) / CELL - 0.5))
				for i = i0, i1 do
					buffer.writeu8(ids, j * n + i, t)
				end
			end
		end
	end
	self.ids = ids
	if yieldFn then yieldFn() end

	-- pesos suavizados por tipo e parâmetros misturados
	local nn = n * n
	local params = {}
	for _, key in ipairs(PARAM_KEYS) do
		params[key] = buffer.create(nn * 4)
	end
	local wsum = buffer.create(nn * 4)
	local dom = buffer.create(nn)
	local domW = buffer.create(nn * 4)
	local tmp = buffer.create(nn * 4)
	self.lakeW = buffer.create(nn * 4)
	self.swampW = buffer.create(nn * 4)
	for t, id in ipairs(types) do
		local P = data.REGION_PARAMS[id]
		local w = buffer.create(nn * 4)
		local any = false
		for c = 0, nn - 1 do
			if buffer.readu8(ids, c) == t then
				buffer.writef32(w, c * 4, 1)
				any = true
			end
		end
		if any then
			boxBlur(w, tmp, n, P.blur)
			for c = 0, nn - 1 do
				local wv = buffer.readf32(w, c * 4)
				if wv > 0.0001 then
					local o = c * 4
					buffer.writef32(wsum, o, buffer.readf32(wsum, o) + wv)
					for _, key in ipairs(PARAM_KEYS) do
						local b = params[key]
						buffer.writef32(b, o, buffer.readf32(b, o) + wv * P[key])
					end
					if wv > buffer.readf32(domW, o) then
						buffer.writef32(domW, o, wv)
						buffer.writeu8(dom, c, t)
					end
					if id == "lake" then
						buffer.writef32(self.lakeW, o, wv)
					elseif id == "swamp" or id == "swampcore" then
						buffer.writef32(self.swampW, o, buffer.readf32(self.swampW, o) + wv)
					end
				end
			end
		end
		if yieldFn then yieldFn() end
	end
	for c = 0, nn - 1 do
		local o = c * 4
		local s = buffer.readf32(wsum, o)
		if s > 0 then
			for _, key in ipairs(PARAM_KEYS) do
				local b = params[key]
				buffer.writef32(b, o, buffer.readf32(b, o) / s)
			end
		end
	end
	self.params = params
	self.dom = dom

	-- rios: amostras densas convertidas em segmentos
	self.riverSegs = {}
	for _, rv in ipairs(data.RIVERS) do
		local pts = sampleOpen(rv.pts, 60)
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local dx, dy = b[1] - a[1], b[2] - a[2]
			table.insert(self.riverSegs, { ax = a[1], ay = a[2], dx = dx, dy = dy, len2 = max(1e-6, dx * dx + dy * dy), l1 = a[3], l2 = b[3], hw = rv.hw, depth = rv.depth })
		end
	end
	self.roadSegs = {}
	for _, rd in ipairs(data.ROADS) do
		local pts = sampleOpen(rd, 40)
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local dx, dy = b[1] - a[1], b[2] - a[2]
			table.insert(self.roadSegs, { ax = a[1], ay = a[2], dx = dx, dy = dy, len2 = max(1e-6, dx * dx + dy * dy) })
		end
	end

	-- áreas planas (Hub, fazendas, acampamentos, waypoints, vale da dungeon)
	self.pads = {}
	local H = data.HUB
	table.insert(self.pads, { kind = "hub", x = H.x, y = H.y, r0 = H.r0, r1 = H.r1, target = H.target })
	for _, f in ipairs(data.FARMS) do
		table.insert(self.pads, { kind = "farm", id = f.id, biome = f.biome, x = f.x, y = f.y, r0 = data.FARM_R0, r1 = data.FARM_R1, target = f.target })
	end
	for _, c in ipairs(data.CAMPS) do
		table.insert(self.pads, { kind = "camp", x = c.x, y = c.y, r0 = 40, r1 = 100 })
	end
	for _, w in ipairs(data.WAYPOINTS) do
		table.insert(self.pads, { kind = "waypoint", x = w.x, y = w.y, r0 = 18, r1 = 55 })
	end
	local D = data.DUNGEON
	table.insert(self.pads, { kind = "dungeon", x = D.x, y = D.y, r0 = D.r0, r1 = D.r1, depthBelow = D.depth })
	-- alvo de cada área plana: altura natural no centro (média de 5 pontos)
	for _, p in ipairs(self.pads) do
		if not p.target then
			local s = 0
			local offs = { { 0, 0 }, { 60, 0 }, { -60, 0 }, { 0, 60 }, { 0, -60 } }
			for _, o in ipairs(offs) do
				s += self:naturalHeight(p.x + o[1], p.y + o[2])
			end
			local h = s / #offs
			if p.depthBelow then
				h -= p.depthBelow
			end
			p.target = max(h, 6)
		end
	end
	return self
end

--------------------------------------------------------------------------
-- Funções por coluna
--------------------------------------------------------------------------
function WorldGen:sampleParams(x: number, y: number)
	local n = self.n
	local fx = (x - self.origin) / CELL - 0.5
	local fy = (y - self.origin) / CELL - 0.5
	local i0 = floor(fx)
	local j0 = floor(fy)
	if i0 < 0 then i0 = 0 elseif i0 > n - 2 then i0 = n - 2 end
	if j0 < 0 then j0 = 0 elseif j0 > n - 2 then j0 = n - 2 end
	local tx = clamp01(fx - i0)
	local ty = clamp01(fy - j0)
	local c00 = (j0 * n + i0) * 4
	local c10 = c00 + 4
	local c01 = c00 + n * 4
	local c11 = c01 + 4
	local w00, w10, w01, w11 = (1 - tx) * (1 - ty), tx * (1 - ty), (1 - tx) * ty, tx * ty
	local P = self.params
	local function bl(b: buffer): number
		return buffer.readf32(b, c00) * w00 + buffer.readf32(b, c10) * w10 + buffer.readf32(b, c01) * w01 + buffer.readf32(b, c11) * w11
	end
	return bl(P.B), bl(P.Ah), bl(P.Am), bl(P.Ar), bl(P.Ad), bl(P.Ac), bl(self.lakeW), bl(self.swampW)
end

function WorldGen:domAt(x: number, y: number): number
	local n = self.n
	local i = floor((x - self.origin) / CELL)
	local j = floor((y - self.origin) / CELL)
	if i < 0 then i = 0 elseif i > n - 1 then i = n - 1 end
	if j < 0 then j = 0 elseif j > n - 1 then j = n - 1 end
	return buffer.readu8(self.dom, j * n + i)
end

-- Distância (positiva fora) até a costa, aproximada em studs
function WorldGen:coastDist(x: number, y: number): number
	local C = self.data.CONTINENT
	local u = x / C.rx
	local v = (y - C.cy) / C.ry
	local a = atan2(v, u)
	local rn = sqrt(u * u + v * v)
	local r = 1 + 0.045 * sin(3 * a + 0.7) + 0.03 * sin(7 * a + 1.9) + 0.02 * sin(13 * a)
	return (rn - r) * 7200 + 420 * noise(x / 1600, y / 1600, 10.7) + 150 * noise(x / 420, y / 420, 11.3) + 60 * noise(x / 130, y / 130, 12.9)
end

-- Termos de ruído do relevo; devolve altura e valores auxiliares
local function reliefNoise(x: number, y: number, B: number, Ah: number, Am: number, Ar: number, Ad: number, Ac: number)
	local nh = noise(x / 1100, y / 1100, 0.31) * 1.5 + noise(x / 520, y / 520, 1.73) * 0.6
	local nm = noise(x / 320, y / 320, 3.37) * 1.5 + noise(x / 150, y / 150, 4.11) * 0.5
	local h = B + Ah * nh + Am * nm
	if Ar > 0.5 then
		local r1 = 1 - abs(noise(x / 1400, y / 1400, 5.13) * 1.8)
		if r1 < 0 then r1 = 0 end
		local r2 = 1 - abs(noise(x / 520, y / 520, 6.27) * 1.8)
		if r2 < 0 then r2 = 0 end
		h += Ar * (r1 * r1 * (0.65 + 0.35 * r2 * r2) - 0.25)
	end
	local cut = 0
	if Ac > 0.5 then
		local c = abs(noise(x / 760, y / 760, 7.71) * 1.6)
		cut = 1 - smoothstep(0.02, 0.16, c)
		h -= Ac * cut
		if h < 18 then
			h = 18 + (h - 18) * 0.15 -- fundo do cânion acima do mar (lava, não água)
		end
	end
	local det = noise(x / 70, y / 70, 8.83) * 1.4 + noise(x / 28, y / 28, 9.41) * 0.4
	return h, det, cut
end

local function shapeHeight(s, x: number, y: number, h: number): number
	local dx, dy = x - s.x, y - s.y
	local d = sqrt(dx * dx + dy * dy)
	if s.kind == "cone" then
		if d < s.R then
			local t = 1 - d / s.R
			h += s.H * t ^ s.exp
			if s.crater and d < s.crater * 1.6 then
				local c = 1 - smoothstep(s.crater * 0.4, s.crater * 1.6, d)
				h -= s.craterDepth * c
			end
		end
	elseif s.kind == "hill" then
		if d < s.R then
			local t = 1 - d / s.R
			h += s.H * t * t * (3 - 2 * t)
		end
	elseif s.kind == "mesa" then
		if d < s.R then
			local edge = s.rTop + 18 * noise(x / 60, y / 60, 13.7)
			local t = 1 - smoothstep(edge, s.R, d)
			local f = smoothstep(0, 0.55, t)
			local top = s.top + 4 * noise(x / 40, y / 40, 14.2)
			h = max(h, h + (top - h) * f)
		end
	end
	return h
end

-- Altura natural (sem áreas planas e rios), usada para calcular o alvo das áreas planas
function WorldGen:naturalHeight(x: number, y: number): number
	local B, Ah, Am, Ar, Ad, Ac = self:sampleParams(x, y)
	local h, det = reliefNoise(x, y, B, Ah, Am, Ar, Ad, Ac)
	h += Ad * det
	for _, s in ipairs(self.data.SHAPES) do
		if s.kind ~= "mesa" then
			h = shapeHeight(s, x, y, h)
		end
	end
	local cd = self:coastDist(x, y)
	local cf = smoothstep(-260, 260, cd)
	h = h + (-45 - h) * cf
	for _, s in ipairs(self.data.SHAPES) do
		if s.kind == "mesa" then
			h = shapeHeight(s, x, y, h)
		end
	end
	return h
end

--------------------------------------------------------------------------
-- Bloco de colunas
--------------------------------------------------------------------------
local function segDist(s, x: number, y: number): (number, number)
	local t = ((x - s.ax) * s.dx + (y - s.ay) * s.dy) / s.len2
	if t < 0 then t = 0 elseif t > 1 then t = 1 end
	local px, py = s.ax + s.dx * t - x, s.ay + s.dy * t - y
	return sqrt(px * px + py * py), t
end

local function nearRect(cx: number, cy: number, x0: number, y0: number, x1: number, y1: number, r: number): boolean
	return cx > x0 - r and cx < x1 + r and cy > y0 - r and cy < y1 + r
end

local function segNearRect(s, x0: number, y0: number, x1: number, y1: number, r: number): boolean
	local sx0, sx1 = min(s.ax, s.ax + s.dx), max(s.ax, s.ax + s.dx)
	local sy0, sy1 = min(s.ay, s.ay + s.dy), max(s.ay, s.ay + s.dy)
	return sx1 > x0 - r and sx0 < x1 + r and sy1 > y0 - r and sy0 < y1 + r
end

-- Calcula um bloco de (n+2) x (n+2) colunas (com borda de 1 para a inclinação).
-- Devolve tabela com arrays planos indexados por (j * (n+2) + i + 1):
--   h (altura da superfície), wl (nível da água ou -1e9), mat (material da superfície), sub (material de baixo)
function WorldGen:computeChunk(x0: number, y0: number, n: number, step: number?)
	local VOX = step or VOX
	local W = n + 2
	local data = self.data
	local bx0, by0 = x0 - VOX, y0 - VOX
	local bx1, by1 = x0 + (n + 1) * VOX, y0 + (n + 1) * VOX

	-- limite superior grosseiro de altura no bloco (para filtrar rios)
	local ub = -1e9
	for jj = 0, 2 do
		for ii = 0, 2 do
			local B, Ah, Am, Ar = self:sampleParams(bx0 + (bx1 - bx0) * ii / 2, by0 + (by1 - by0) * jj / 2)
			ub = max(ub, B + abs(Ah) * 2.1 + abs(Am) * 2 + Ar * 0.75 + 40)
		end
	end
	local shapes = {}
	for _, s in ipairs(data.SHAPES) do
		if nearRect(s.x, s.y, bx0, by0, bx1, by1, s.R) then
			table.insert(shapes, s)
			ub += (s.H or s.top or 0)
		end
	end
	local rivers = {}
	for _, s in ipairs(self.riverSegs) do
		local lvl = min(s.l1, s.l2)
		local rise = ub - lvl
		local reach
		if rise <= 71 then
			reach = s.hw + max(0, rise) / 0.35 + 8
		else
			reach = s.hw + 200 + (rise - 71) / 1.2 + 8
		end
		if segNearRect(s, bx0, by0, bx1, by1, reach) then
			table.insert(rivers, s)
		end
	end
	local roads = {}
	local rhw = data.ROAD_HW
	for _, s in ipairs(self.roadSegs) do
		if segNearRect(s, bx0, by0, bx1, by1, rhw + 10) then
			table.insert(roads, s)
		end
	end
	local pads = {}
	for _, p in ipairs(self.pads) do
		if nearRect(p.x, p.y, bx0, by0, bx1, by1, p.r1) then
			table.insert(pads, p)
		end
	end

	local hA, wlA, domA, flagA, cutA = table.create(W * W, 0), table.create(W * W, -1e9), table.create(W * W, 1), table.create(W * W, 0), table.create(W * W, 0)
	local lakeLevel, swampLevel = data.LAKE_LEVEL, data.SWAMP_LEVEL
	for j = 0, W - 1 do
		local y = by0 + j * VOX
		for i = 0, W - 1 do
			local x = bx0 + i * VOX
			local idx = j * W + i + 1
			local B, Ah, Am, Ar, Ad, Ac, lakeW, swampW = self:sampleParams(x, y)
			local h, det, cut = reliefNoise(x, y, B, Ah, Am, Ar, Ad, Ac)
			-- estrada: tira o detalhe fino
			local road = 0
			for _, s in ipairs(roads) do
				local d = segDist(s, x, y)
				local m = 1 - smoothstep(rhw - 2 + 2 * noise(x / 23, y / 23, 15.1), rhw + 6, d)
				if m > road then road = m end
			end
			h += Ad * det * (1 - road)
			for _, s in ipairs(shapes) do
				if s.kind ~= "mesa" then
					h = shapeHeight(s, x, y, h)
				end
			end
			local cd = self:coastDist(x, y)
			local cf = smoothstep(-260, 260, cd)
			local seaFloor = -45 + 10 * noise(x / 300, y / 300, 16.6)
			h = h + (seaFloor - h) * cf
			for _, s in ipairs(shapes) do
				if s.kind == "mesa" then
					h = shapeHeight(s, x, y, h)
				end
			end
			-- áreas planas
			local flag = 0
			for _, p in ipairs(pads) do
				local dx, dy = x - p.x, y - p.y
				local d = sqrt(dx * dx + dy * dy)
				if d < p.r1 then
					local wob = (p.r1 - p.r0) * 0.12 * noise(x / 90, y / 90, 17.3)
					local t = 1 - smoothstep(p.r0 + wob, p.r1 + wob, d)
					t = t * t * (3 - 2 * t)
					h = h + (p.target + det * 0.6 - h) * t
					if d < p.r0 then
						flag = if p.kind == "hub" then 2 elseif p.kind == "farm" then 3 elseif p.kind == "dungeon" then 5 else 4
					end
				end
			end
			-- rios
			local wl = -1e9
			local inChannel = false
			local nearLevel, nearD = 0, 1e9
			for _, s in ipairs(rivers) do
				local d, t = segDist(s, x, y)
				local lvl = s.l1 + (s.l2 - s.l1) * t
				local hw = s.hw * (1 + 0.15 * noise(x / 140, y / 140, 18.9))
				local tgt
				if d < hw then
					local q = d / hw
					tgt = lvl - s.depth * (1 - q * q)
				elseif d < hw + 200 then
					tgt = lvl + 1 + (d - hw) * 0.35
				else
					tgt = lvl + 71 + (d - hw - 200) * 1.2
				end
				if tgt < h then h = tgt end
				if d - hw < nearD then
					nearD = d - hw
					nearLevel = lvl
				end
				if d < hw + 2 then inChannel = true end
			end
			if nearD < 8 then
				wl = nearLevel
			elseif nearD < 40 and not inChannel and h < nearLevel + 1 then
				h = nearLevel + 1 -- margem (dique natural)
			end
			-- lago e pântano: anel de margem garante que a água fique contida
			if lakeW > 0.4 then
				if lakeLevel > wl then wl = lakeLevel end
			elseif lakeW > 0.02 and h < lakeLevel + 0.6 and not inChannel and cd < -300 then
				h = lakeLevel + 0.6
			end
			if swampW > 0.4 then
				if swampLevel > wl then wl = swampLevel end
			elseif swampW > 0.02 and h < swampLevel + 0.6 and not inChannel and cd < -300 then
				h = swampLevel + 0.6
			end
			if h < 0 and wl < 0 then
				wl = 0 -- mar
			end
			if cd > 0 and wl < 0 then wl = 0 end
			if road > 0.5 and (flag == 0 or flag == 4) then flag = 1 end
			hA[idx] = h
			wlA[idx] = wl
			cutA[idx] = cut
			flagA[idx] = flag
			-- região dominante com borda irregular
			domA[idx] = self:domAt(x + 220 * noise(x / 700, y / 700, 19.5) + 70 * noise(x / 170, y / 170, 23.1), y + 220 * noise(x / 700, y / 700, 20.7) + 70 * noise(x / 170, y / 170, 24.9))
		end
	end

	-- materiais
	local types = self.types
	local matA, subA = table.create(W * W, M.Grass), table.create(W * W, M.Ground)
	for j = 1, W - 2 do
		for i = 1, W - 2 do
			local idx = j * W + i + 1
			local x, y = bx0 + i * VOX, by0 + j * VOX
			local h = hA[idx]
			local gx = (hA[idx + 1] - hA[idx - 1]) / (2 * VOX)
			local gy = (hA[idx + W] - hA[idx - W]) / (2 * VOX)
			local slope = sqrt(gx * gx + gy * gy) -- tangente
			local region = types[domA[idx]]
			local wl = wlA[idx]
			local flag = flagA[idx]
			local nz = noise(x / 45, y / 45, 21.1) + 0.5 * noise(x / 13, y / 13, 22.3)
			local mat, sub = M.Grass, M.Ground
			local steepMat = M.Rock
			if region == "volcanic" or region == "castle" then
				steepMat = M.Basalt
				sub = M.Basalt
			elseif region == "ruins" then
				steepMat = M.Limestone
				sub = M.Limestone
			elseif region == "crystal" then
				steepMat = M.Slate
			elseif region == "coast" then
				steepMat = if nz > 0 then M.Sandstone else M.Rock
			end
			-- base por região
			if region == "forest" then
				mat = if nz > 0.5 then M.Ground else M.LeafyGrass
			elseif region == "enchanted" then
				mat = if nz > 0.2 then M.Grass else M.LeafyGrass
			elseif region == "swamp" or region == "swampcore" then
				mat = if nz > 0.1 then M.Mud else M.LeafyGrass
				sub = M.Mud
			elseif region == "snow" then
				mat = if h > 260 + 60 * nz then M.Snow else (if nz > 0 then M.Grass else M.Ground)
			elseif region == "volcanic" then
				mat = if nz > 0.25 then M.Ground elseif nz < -0.3 then M.Rock else M.Basalt
				if cutA[idx] > 0.55 or (h < 120 and nz > 0.45) then mat = M.CrackedLava end
			elseif region == "crystal" then
				mat = if nz > 0.62 then M.Glacier elseif nz < -0.62 then M.Salt else M.Grass
			elseif region == "ruins" then
				mat = if nz > 0.35 then M.Limestone else M.Grass
			elseif region == "castle" then
				mat = if nz > 0.3 then M.Ground elseif nz < -0.25 then M.Slate else M.Basalt
			elseif region == "mountain" then
				if h < 300 + 40 * nz then
					mat = if nz > 0.3 then M.Ground else M.Grass
				elseif h < 520 + 60 * nz then
					mat = if nz > 0 then M.Rock else M.Grass
				else
					mat = if nz > 0.2 then M.Slate else M.Rock
				end
			elseif region == "coast" then
				mat = if nz > 0.55 then M.LeafyGrass else M.Grass
			else
				mat = if nz > 0.55 then M.LeafyGrass else M.Grass
			end
			-- neve em altitude
			if h > 760 + 50 * nz then
				mat = M.Snow
			end
			-- encostas íngremes
			if slope > 1.0 + 0.15 * nz then
				mat = if mat == M.Snow and slope < 1.5 then M.Glacier else steepMat
			elseif slope > 0.7 + 0.15 * nz and mat ~= M.Snow then
				mat = if nz > 0 then steepMat else M.Ground
			end
			-- praias e fundo da água
			if wl > -1e8 then
				if h < wl + 0.5 then
					if region == "swamp" or region == "swampcore" then
						mat = M.Mud
					elseif wl <= 0.01 or region == "lake" then
						mat = M.Sand
					else
						mat = if nz > 0 then M.Ground else M.Slate
					end
				elseif h < wl + 4 and (wl <= 0.01 or region == "lake" or region == "lakeland") and slope < 0.5 then
					mat = M.Sand
				end
			end
			if h < 8 and self:coastDist(x, y) > -320 and slope < 0.6 and not (region == "swamp" or region == "swampcore") then
				mat = M.Sand
			end
			-- estradas e áreas especiais
			if flag == 1 then
				mat = if region == "ruins" or region == "castle" then M.Cobblestone elseif region == "snow" then M.Snow elseif region == "swamp" or region == "swampcore" then M.Mud else M.Ground
			elseif flag == 2 then
				mat = M.Grass
			elseif flag == 3 then
				if region == "snow" or h > 700 then
					mat = M.Snow
				elseif region == "volcanic" then
					mat = if nz > 0 then M.Ground else M.Grass
				else
					mat = M.Grass
				end
			end
			matA[idx] = mat
			subA[idx] = sub
		end
	end
	return { n = n, W = W, x0 = x0, y0 = y0, h = hA, wl = wlA, mat = matA, sub = subA }
end

return WorldGen
