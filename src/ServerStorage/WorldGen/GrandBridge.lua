-- Pontes grandes da Baía do Coração (ligam o Hub às regiões).
-- Estilo da imagem aprovada: pedra escura, runas brilhantes, pilares com cristais, estátuas de
-- dragão, torres-portal nas cabeceiras com arco brilhante — só que bem maiores (escala do mapa).
-- Cada ponte tem: tabuleiro largo em curva, parapeitos com runas, pilones com cristais,
-- lanternas, pilares com arcos sobre a água, mirante no meio com estátuas e braseiro,
-- e um portal de torres em cada ponta com o nome da ponte.

local GrandBridge = {}

local DARK = Color3.fromRGB(62, 64, 72)
local DARK2 = Color3.fromRGB(78, 80, 90)
local PAVE = Color3.fromRGB(104, 104, 110)
local TRIM = Color3.fromRGB(150, 140, 120)

export type Spec = {
	name: string,
	a: Vector3, -- ponta do Hub (no chão)
	b: Vector3, -- ponta da margem (no chão)
	width: number,
	accent: Color3,
	waterY: number,
	floorY: number,
}

local function P(props, parent): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Slate
	p.Color = DARK
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function light(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
end

-- cristal brilhante (dois blocos girados) com luz opcional
local function crystal(cf: CFrame, s: number, color: Color3, parent: Instance, withLight: boolean)
	local c = P({ Name = "Crystal", Size = Vector3.new(s, s * 1.8, s), CFrame = cf * CFrame.Angles(0, math.rad(45), math.rad(12)), Material = Enum.Material.Neon, Color = color, CanCollide = false, CastShadow = false }, parent)
	P({ Name = "Crystal", Size = Vector3.new(s * 0.7, s * 1.3, s * 0.7), CFrame = cf * CFrame.new(s * 0.5, -s * 0.2, 0) * CFrame.Angles(0, 0, math.rad(-20)), Material = Enum.Material.Neon, Color = color, CanCollide = false, CastShadow = false }, parent)
	if withLight then
		light(c, color, 28, 1.6)
	end
	return c
end

local function nameplate(part: BasePart, text: string, face: Enum.NormalId, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0.4
	gui.Parent = part
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.Fantasy
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.3
	t.Text = text
	t.Parent = gui
end

-- Portal de torres numa cabeceira. cf: no chão, olhando para FORA da ponte.
local function gate(cf: CFrame, spec: Spec, Props: any, statue: any, parent: Instance)
	local m = Instance.new("Model")
	m.Name = "Gate"
	m.Parent = parent
	local W = spec.width
	local half = W / 2 + 7
	for _, sx in ipairs({ -1, 1 }) do
		local tcf = cf * CFrame.new(sx * half, 0, 0)
		Props.roundTower(tcf, 9, 46, m, true)
		-- faixa de runas e cristal no alto da torre
		P({ Name = "RuneBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 18.6, 18.6), CFrame = tcf * CFrame.new(0, 30, 0) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = spec.accent, CastShadow = false }, m)
		-- estátua de dragão do lado de fora, sobre pedestal
		local ped = tcf * CFrame.new(sx * 16, 0, -10)
		P({ Name = "Pedestal", Size = Vector3.new(12, 8, 16), CFrame = ped * CFrame.new(0, 4, 0), Material = Enum.Material.Slate, Color = DARK2 }, m)
		P({ Name = "PedestalTrim", Size = Vector3.new(13, 1, 17), CFrame = ped * CFrame.new(0, 8.5, 0), Material = Enum.Material.Slate, Color = TRIM }, m)
		if statue then
			statue(ped * CFrame.new(0, 9, 0) * CFrame.Angles(0, math.rad(if sx > 0 then -25 else 25), 0), 22, m)
		end
	end
	-- arco entre as torres
	local lintel = P({ Name = "Lintel", Size = Vector3.new(W + 14, 9, 12), CFrame = cf * CFrame.new(0, 38, 0), Material = Enum.Material.Slate, Color = DARK2 }, m)
	P({ Name = "LintelTrim", Size = Vector3.new(W + 16, 1.4, 13), CFrame = cf * CFrame.new(0, 43, 0), Material = Enum.Material.Slate, Color = TRIM }, m)
	nameplate(lintel, spec.name, Enum.NormalId.Front, Color3.fromRGB(236, 222, 190))
	nameplate(lintel, spec.name, Enum.NormalId.Back, Color3.fromRGB(236, 222, 190))
	-- arco brilhante (portal decorativo, não bloqueia)
	local segs = 9
	for i = 0, segs do
		local a = math.pi * i / segs
		local x = math.cos(a) * (W / 2 + 1)
		local y = 18 + math.sin(a) * 15
		P({ Name = "PortalArc", Size = Vector3.new(2.2, 2.2, 1.2), CFrame = cf * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, a), Material = Enum.Material.Neon, Color = spec.accent, CanCollide = false, CastShadow = false }, m)
	end
	local glow = P({ Name = "PortalGlow", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, 26, 0), Transparency = 1, CanCollide = false, CanQuery = false }, m)
	light(glow, spec.accent, 46, 2.2)
	-- estandartes grandes pendurados no arco, dos dois lados
	for _, sz in ipairs({ -6.2, 6.2 }) do
		for _, sx in ipairs({ -W / 3, W / 3 }) do
			Props.wallBanner(cf * CFrame.new(sx, 27, sz) * CFrame.Angles(0, if sz > 0 then 0 else math.pi, 0), 6, 14, m)
		end
	end
	return m
end

function GrandBridge.build(spec: Spec, parent: Instance, Props: any, statue: ((CFrame, number, Instance) -> any)?, rng: Random): Model
	local model = Instance.new("Model")
	model.Name = spec.name
	local W = spec.width
	local a, b = spec.a, spec.b
	local flatDir = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local L = flatDir.Magnitude
	flatDir = flatDir.Unit
	local right = flatDir:Cross(Vector3.yAxis).Unit
	-- perfil: sobe em curva suave até o meio (bem acima da água) e desce
	local midTarget = spec.waterY + 50
	local base0, base1 = a.Y + 0.5, b.Y + 0.5
	local rise = math.max(0, midTarget - (base0 + base1) / 2)
	local function deckAt(t: number): Vector3
		local p = a:Lerp(b, t)
		local y = base0 + (base1 - base0) * t + rise * math.sin(math.pi * t)
		return Vector3.new(p.X, y, p.Z)
	end
	local SEG = 24
	local n = math.max(4, math.floor(L / SEG))
	local deck = Instance.new("Model")
	deck.Name = "Deck"
	deck.Parent = model
	local details = Instance.new("Model")
	details.Name = "Details"
	details.Parent = model
	local plazaT0, plazaT1 = 0.5 - 30 / L, 0.5 + 30 / L
	for i = 0, n - 1 do
		local t0, t1 = i / n, (i + 1) / n
		local p0, p1 = deckAt(t0), deckAt(t1)
		local mid = (p0 + p1) / 2
		local len = (p1 - p0).Magnitude + 0.6
		local cf = CFrame.lookAt(mid, p1)
		P({ Name = "DeckSlab", Size = Vector3.new(W, 3, len), CFrame = cf * CFrame.new(0, -1.5, 0), Color = DARK }, deck)
		P({ Name = "Paving", Size = Vector3.new(W - 7, 0.4, len), CFrame = cf * CFrame.new(0, 0.2, 0), Material = Enum.Material.Cobblestone, Color = PAVE }, deck)
		-- faixa central de pedra clara e runas no chão
		P({ Name = "CenterLine", Size = Vector3.new(3, 0.45, len), CFrame = cf * CFrame.new(0, 0.22, 0), Material = Enum.Material.Slate, Color = TRIM }, deck)
		local tm = (t0 + t1) / 2
		local inPlaza = tm > plazaT0 and tm < plazaT1
		for _, sx in ipairs({ -1, 1 }) do
			local off = sx * (W / 2 - 1.2)
			if not inPlaza then
				P({ Name = "Parapet", Size = Vector3.new(2.4, 4.6, len), CFrame = cf * CFrame.new(off, 2.3, 0), Color = DARK2 }, deck)
				P({ Name = "ParapetCap", Size = Vector3.new(3.2, 0.8, len), CFrame = cf * CFrame.new(off, 5, 0), Color = TRIM }, deck)
				P({ Name = "Runes", Size = Vector3.new(0.3, 0.6, len * 0.9), CFrame = cf * CFrame.new(off - sx * 1.25, 1.4, 0), Material = Enum.Material.Neon, Color = spec.accent, CanCollide = false, CastShadow = false }, details)
			end
			-- moldura externa (cornija) por baixo do parapeito
			P({ Name = "Cornice", Size = Vector3.new(1.6, 1.4, len), CFrame = cf * CFrame.new(sx * (W / 2 + 0.6), -2.4, 0), Color = TRIM }, deck)
		end
		-- pilones com cristais (a cada 3 segmentos) e lanternas entre eles
		if not inPlaza and i % 3 == 1 then
			for _, sx in ipairs({ -1, 1 }) do
				local pcf = cf * CFrame.new(sx * (W / 2 - 1.2), 0, 0)
				P({ Name = "Pylon", Size = Vector3.new(4.6, 13, 4.6), CFrame = pcf * CFrame.new(0, 6.5, 0), Color = DARK2 }, details)
				P({ Name = "PylonCap", Size = Vector3.new(5.6, 1.2, 5.6), CFrame = pcf * CFrame.new(0, 13.4, 0), Color = TRIM }, details)
				crystal(pcf * CFrame.new(0, 16, 0), 2.2, spec.accent, details, (i // 3) % 2 == 0)
				if i % 6 == 1 then
					Props.banner(pcf * CFrame.new(sx * 2.8, 0, 0), details, 18, Color3.fromRGB(30, 32, 44))
				end
			end
		elseif not inPlaza and i % 3 == 2 then
			for _, sx in ipairs({ -1, 1 }) do
				local lcf = cf * CFrame.new(sx * (W / 2 - 1.2), 5.4, 0) * CFrame.Angles(0, if sx > 0 then math.rad(90) else math.rad(-90), 0)
				local lp = Props.lanternPost(lcf, details, 9)
				if (i // 3) % 2 == 1 then
					local glass = lp:FindFirstChild("LanternGlass")
					local l = glass and glass:FindFirstChildOfClass("PointLight")
					if l then
						l:Destroy() -- metade das lanternas só brilha (economiza luzes)
					end
				end
			end
		end
	end

	-- pilares e arcos sobre a água
	local piers = Instance.new("Model")
	piers.Name = "Piers"
	piers.Parent = model
	local SPAN = 96
	local np = math.max(1, math.floor((L - 60) / SPAN))
	local tPiers = {}
	for k = 0, np do
		local t = (30 + k * (L - 60) / np) / L
		table.insert(tPiers, t)
	end
	for _, t in ipairs(tPiers) do
		local top = deckAt(t)
		local bottomY = spec.floorY - 2
		local h = top.Y - 3 - bottomY
		if h > 6 then
			local cf = CFrame.lookAt(Vector3.new(top.X, bottomY + h / 2, top.Z), Vector3.new(top.X, bottomY + h / 2, top.Z) + flatDir)
			P({ Name = "Pier", Size = Vector3.new(W - 2, h, 18), CFrame = cf, Color = DARK2 }, piers)
			-- quebra-mar (proas) nas laterais, cortando a água
			for _, sx in ipairs({ -1, 1 }) do
				local w = Instance.new("WedgePart")
				w.Anchored = true
				w.Size = Vector3.new(18, h, 10)
				w.CFrame = cf * CFrame.new(sx * ((W - 2) / 2 + 5), 0, 0) * CFrame.Angles(0, math.rad(if sx > 0 then -90 else 90), 0)
				w.Material = Enum.Material.Slate
				w.Color = DARK2
				w.Parent = piers
			end
			-- anel de pedra na linha d'água e capitel no alto do pilar
			P({ Name = "PierBand", Size = Vector3.new(W + 2, 1.6, 20), CFrame = CFrame.new(top.X, spec.waterY + 2, top.Z) * cf.Rotation, Color = TRIM }, piers)
			P({ Name = "PierCap", Size = Vector3.new(W + 1, 2, 21), CFrame = CFrame.new(top.X, top.Y - 5, top.Z) * cf.Rotation, Color = TRIM }, piers)
		end
	end
	-- arcos entre pilares (anel de pedra + paredes laterais até o tabuleiro)
	for k = 1, #tPiers - 1 do
		local ta, tb = tPiers[k], tPiers[k + 1]
		local segs = 8
		local spring = math.min(38, (deckAt((ta + tb) / 2).Y - 6) - (spec.waterY + 4))
		if spring > 4 then
			for s = 0, segs - 1 do
				local u0, u1 = s / segs, (s + 1) / segs
				local function archPoint(u: number): Vector3
					local t = ta + (tb - ta) * u
					local d = deckAt(t)
					local x = u * 2 - 1
					local y = d.Y - 3 - spring + spring * math.sqrt(math.max(0, 1 - x * x))
					return Vector3.new(d.X, y, d.Z)
				end
				local q0, q1 = archPoint(u0), archPoint(u1)
				local m = (q0 + q1) / 2
				local acf = CFrame.lookAt(m, q1)
				local alen = (q1 - q0).Magnitude + 0.8
				P({ Name = "Arch", Size = Vector3.new(W - 2, 4, alen), CFrame = acf, Color = TRIM }, piers)
				-- parede (tímpano) entre o arco e o tabuleiro, nas duas faces
				local deckY = deckAt(ta + (tb - ta) * (u0 + u1) / 2).Y - 3
				local hh = deckY - m.Y
				if hh > 1 then
					for _, sx in ipairs({ -1, 1 }) do
						P({ Name = "Spandrel", Size = Vector3.new(1.6, hh, alen), CFrame = CFrame.lookAt(Vector3.new(m.X, m.Y + hh / 2, m.Z), Vector3.new(q1.X, m.Y + hh / 2, q1.Z)) * CFrame.new(sx * (W / 2 - 0.8), 0, 0), Color = DARK }, piers)
					end
				end
			end
		end
	end

	-- mirante no meio: plataforma larga, estátuas, braseiro de cristal e bancos
	local plaza = Instance.new("Model")
	plaza.Name = "Overlook"
	plaza.Parent = model
	local pc = deckAt(0.5)
	local pcf = CFrame.lookAt(pc, pc + flatDir)
	local PW = W + 30
	P({ Name = "PlazaFloor", Size = Vector3.new(PW, 3, 64), CFrame = pcf * CFrame.new(0, -1.5, 0), Color = DARK }, plaza)
	P({ Name = "PlazaPaving", Size = Vector3.new(PW - 4, 0.4, 60), CFrame = pcf * CFrame.new(0, 0.22, 0), Material = Enum.Material.Cobblestone, Color = PAVE }, plaza)
	for _, sx in ipairs({ -1, 1 }) do
		P({ Name = "PlazaRail", Size = Vector3.new(2.4, 4.6, 64), CFrame = pcf * CFrame.new(sx * (PW / 2 - 1.2), 2.3, 0), Color = DARK2 }, plaza)
		P({ Name = "PlazaRailCap", Size = Vector3.new(3.2, 0.8, 64), CFrame = pcf * CFrame.new(sx * (PW / 2 - 1.2), 5, 0), Color = TRIM }, plaza)
		P({ Name = "Runes", Size = Vector3.new(0.3, 0.6, 58), CFrame = pcf * CFrame.new(sx * (PW / 2 - 2.5), 1.4, 0), Material = Enum.Material.Neon, Color = spec.accent, CanCollide = false, CastShadow = false }, plaza)
		-- balcão saliente com estátua de dragão olhando para o mar
		local scf = pcf * CFrame.new(sx * (PW / 2 + 7), 0, 0)
		P({ Name = "Balcony", Size = Vector3.new(14, 3, 22), CFrame = scf * CFrame.new(0, -1.5, 0), Color = DARK }, plaza)
		P({ Name = "Corbel", Size = Vector3.new(10, 10, 16), CFrame = scf * CFrame.new(-sx * 2, -8, 0), Color = DARK2 }, plaza)
		if statue then
			statue(scf * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, if sx > 0 then math.rad(-90) else math.rad(90), 0), 18, plaza)
		end
		for _, z in ipairs({ -18, 18 }) do
			P({ Name = "Bench", Size = Vector3.new(2.2, 1.6, 8), CFrame = pcf * CFrame.new(sx * (PW / 2 - 6), 0.8, z), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(110, 78, 50) }, plaza)
		end
	end
	-- braseiro de cristal no centro
	P({ Name = "BrazierBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 9, 9), CFrame = pcf * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = DARK2 }, plaza)
	P({ Name = "BrazierBowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 11, 11), CFrame = pcf * CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = TRIM, Material = Enum.Material.Metal }, plaza)
	crystal(pcf * CFrame.new(0, 8, 0), 3.4, spec.accent, plaza, true)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(spec.accent)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(0.4, 0)
	sparks.Rate = 6
	sparks.Lifetime = NumberRange.new(2, 3)
	sparks.Speed = NumberRange.new(2, 4)
	sparks.SpreadAngle = Vector2.new(30, 30)
	sparks.Parent = plaza:FindFirstChild("Crystal") :: Instance

	-- portais nas duas cabeceiras (olhando para fora)
	local ga = deckAt(0.02)
	local gb = deckAt(0.98)
	gate(CFrame.lookAt(Vector3.new(ga.X, a.Y, ga.Z), Vector3.new(ga.X, a.Y, ga.Z) - flatDir), spec, Props, statue, model)
	gate(CFrame.lookAt(Vector3.new(gb.X, b.Y, gb.Z), Vector3.new(gb.X, b.Y, gb.Z) + flatDir), spec, Props, statue, model)

	local _ = right
	local _r = rng
	model:SetAttribute("Landmark", spec.name)
	model.Parent = parent
	return model
end

return GrandBridge
