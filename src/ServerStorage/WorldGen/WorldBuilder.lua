-- Constrói o conteúdo do mundo aberto sobre o terreno gerado (WorldGen/TerrainWriter):
-- Hub na ilha fluvial, pontes, 18 fazendas com bosques, acampamentos, waypoints,
-- marcos, castelo, portão da dungeon, ilhas flutuantes, florestas e iluminação.
-- Cada etapa apaga o que ela mesma criou e reconstrói (pode rodar de novo).
-- Executar no modo Edit; as etapas longas cedem (task.wait) para não travar o Studio.

local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local WorldBuilder = {}
WorldBuilder.__index = WorldBuilder

local Terrain = workspace.Terrain
local WOOD = Color3.fromRGB(124, 92, 60)
local DARKWOOD = Color3.fromRGB(86, 60, 40)
local STONE = Color3.fromRGB(150, 146, 138)

-- escala base de cada modelo gerado (ajusta o tamanho entregue pela IA)
local BASE_SCALE = {
	Pine = 2.2, Tree2 = 1.6, Arch = 1.6, QuestBoard = 1.4, Blossom = 1.1, Boulder = 1.6,
	Waypoint = 1.3, Camp = 1.4, Castle = 2.8, Lighthouse = 1.5, Ruins = 2.2, Cottage = 1.3, Crystal = 1.0,
	SnowPine = 1.8, DeadTree = 1.5, FruitBush = 1.0, Mushroom = 1.0, TallPine = 2.2, Flowers = 1.0,
}

--------------------------------------------------------------------------
-- Contexto
--------------------------------------------------------------------------
function WorldBuilder.new(folder: Instance)
	local self = setmetatable({}, WorldBuilder)
	self.folder = folder
	self.data = require((folder :: any).WorldData:Clone())
	local WorldGen = require((folder :: any).WorldGen:Clone())
	self.gen = WorldGen.new(self.data)
	self.assets = ServerStorage:FindFirstChild("WorldAssets")
	self.Props = require((folder :: any).Props:Clone())
	self.rng = Random.new(20261012)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { Terrain }
	rp.IgnoreWater = false
	self.rayWater = rp
	local rs = RaycastParams.new()
	rs.FilterType = Enum.RaycastFilterType.Include
	rs.FilterDescendantsInstances = { Terrain }
	rs.IgnoreWater = true
	self.raySolid = rs
	-- índice espacial das estradas (células de 256 studs)
	self.roadCells = {}
	for _, s in ipairs(self.gen.roadSegs) do
		local x0, x1 = math.min(s.ax, s.ax + s.dx) - 30, math.max(s.ax, s.ax + s.dx) + 30
		local y0, y1 = math.min(s.ay, s.ay + s.dy) - 30, math.max(s.ay, s.ay + s.dy) + 30
		for cx = math.floor(x0 / 256), math.floor(x1 / 256) do
			for cy = math.floor(y0 / 256), math.floor(y1 / 256) do
				local key = cx .. "," .. cy
				self.roadCells[key] = self.roadCells[key] or {}
				table.insert(self.roadCells[key], s)
			end
		end
	end
	return self
end

-- mapa (x leste, y norte) -> mundo Roblox
local function V(x: number, y: number, h: number?): Vector3
	return Vector3.new(x, h or 0, -y)
end
WorldBuilder.V = V

function WorldBuilder:status(text: string)
	self.folder:SetAttribute("BuildStatus", text)
end

function WorldBuilder:container(name: string, parent: Instance?): Folder
	parent = parent or workspace
	local old = (parent :: Instance):FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function WorldBuilder:worldFolder(): Folder
	local w = workspace:FindFirstChild("World")
	if not w then
		w = Instance.new("Folder")
		w.Name = "World"
		w.Parent = workspace
	end
	return w :: Folder
end

-- Superfície (sólida ou água) no ponto do mapa
function WorldBuilder:surface(x: number, y: number, ignoreWater: boolean?): RaycastResult?
	return workspace:Raycast(Vector3.new(x, 3000, -y), Vector3.new(0, -3200, 0), if ignoreWater then self.raySolid else self.rayWater)
end

function WorldBuilder:groundY(x: number, y: number): number
	local hit = self:surface(x, y, true)
	return hit and hit.Position.Y or 0
end

function WorldBuilder:roadDist(x: number, y: number): number
	local list = self.roadCells[math.floor(x / 256) .. "," .. math.floor(y / 256)]
	if not list then
		return math.huge
	end
	local best = math.huge
	for _, s in ipairs(list) do
		local t = ((x - s.ax) * s.dx + (y - s.ay) * s.dy) / s.len2
		t = math.clamp(t, 0, 1)
		local px, py = s.ax + s.dx * t - x, s.ay + s.dy * t - y
		local d = math.sqrt(px * px + py * py)
		if d < best then
			best = d
		end
	end
	return best
end

-- Pinta o material da superfície (sem mudar o relevo) numa célula de ~8 studs
local PAINT_SOURCES = {
	Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud, Enum.Material.Sand,
	Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Snow, Enum.Material.Basalt, Enum.Material.Limestone,
	Enum.Material.Glacier, Enum.Material.Salt, Enum.Material.Cobblestone, Enum.Material.Pavement, Enum.Material.CrackedLava,
}
function WorldBuilder:paintCell(wx: number, wz: number, half: number, mat: Enum.Material)
	local hit = workspace:Raycast(Vector3.new(wx, 3000, wz), Vector3.new(0, -3200, 0), self.raySolid)
	if not hit then
		return
	end
	local g = hit.Position.Y
	local region = Region3.new(Vector3.new(wx - half, g - 8, wz - half), Vector3.new(wx + half, g + 4, wz + half)):ExpandToGrid(4)
	for _, src in ipairs(PAINT_SOURCES) do
		if src ~= mat then
			Terrain:ReplaceMaterial(region, 4, src, mat)
		end
	end
end

-- disco no mapa (x, y) de raio r
function WorldBuilder:paintDisc(x: number, y: number, r: number, mat: Enum.Material)
	for gx = -r, r, 8 do
		for gy = -r, r, 8 do
			if gx * gx + gy * gy <= r * r then
				self:paintCell(x + gx, -(y + gy), 4, mat)
			end
		end
	end
end

-- faixa entre dois pontos do mundo (Vector3), largura w
function WorldBuilder:paintStrip(a: Vector3, b: Vector3, w: number, mat: Enum.Material)
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = d.Magnitude
	if len < 0.1 then
		return
	end
	local dir = d / len
	local side = Vector3.new(-dir.Z, 0, dir.X)
	for t = 0, len, 6 do
		for o = -w / 2 + 3, w / 2 - 3 + 0.01, 6 do
			local p = a + dir * t + side * o
			self:paintCell(p.X, p.Z, 4, mat)
		end
	end
end

--------------------------------------------------------------------------
-- Peças e modelos
--------------------------------------------------------------------------
local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end
WorldBuilder.part = part

-- Clona um modelo de WorldAssets apoiado no chão em cf.Position
function WorldBuilder:placeAsset(name: string, cf: CFrame, scale: number?, parent: Instance, sink: number?): Model?
	local src = self.assets and self.assets:FindFirstChild(name)
	if not src then
		return nil
	end
	local m = src:Clone()
	local total = (scale or 1) * (BASE_SCALE[name] or 1)
	if math.abs(total - 1) > 0.001 then
		m:ScaleTo(m:GetScale() * total)
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	m:PivotTo(CFrame.new(cf.Position) * cf.Rotation * m:GetPivot().Rotation)
	local bcf, size = m:GetBoundingBox()
	local bottomCenter = bcf.Position - Vector3.new(0, size.Y / 2, 0)
	m:PivotTo(m:GetPivot() + (cf.Position - bottomCenter) - Vector3.new(0, sink or 0, 0))
	m.Parent = parent
	return m
end

local LEAF = {
	default = Color3.fromRGB(76, 140, 62),
	pine = Color3.fromRGB(40, 92, 56),
	snow = Color3.fromRGB(226, 236, 240),
	blossom = Color3.fromRGB(240, 170, 210),
	enchanted = Color3.fromRGB(150, 110, 230),
	crystal = Color3.fromRGB(110, 170, 210),
	dead = Color3.fromRGB(90, 70, 60),
	swamp = Color3.fromRGB(70, 100, 60),
}

-- Árvore de peças simples (usada quando não existe o modelo gerado para o tipo)
function WorldBuilder:simpleTree(kind: string, pos: Vector3, scale: number, parent: Instance, leaf: Color3?)
	local m = Instance.new("Model")
	m.Name = kind
	local rot = CFrame.Angles(0, self.rng:NextNumber(0, math.pi * 2), 0)
	if kind == "Bush" or kind == "FruitBush" then
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 4.5, 7) * scale, CFrame = CFrame.new(pos + Vector3.new(0, 1.6 * scale, 0)), Material = Enum.Material.Grass, Color = leaf or LEAF.default, CastShadow = false }, m)
		if kind == "FruitBush" then
			for i = 1, 6 do
				local a = i / 6 * math.pi * 2
				part({ Name = "Fruit", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9) * scale, CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 3.2 * scale, 2.2 * scale, math.sin(a) * 3.2 * scale)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(210, 40, 60), CanCollide = false, CastShadow = false }, m)
			end
		end
		m.Parent = parent
		return m
	end
	local isPine = kind == "Pine" or kind == "SnowPine" or kind == "CrystalPine"
	local h = (if isPine then 34 else 24) * scale
	local trunkColor = if kind == "DeadTree" then Color3.fromRGB(70, 58, 50) else Color3.fromRGB(105, 74, 48)
	part({ Name = "Trunk", Size = Vector3.new(2.4 * scale, h * 0.55, 2.4 * scale), CFrame = CFrame.new(pos + Vector3.new(0, h * 0.27, 0)) * rot, Material = Enum.Material.Wood, Color = trunkColor }, m)
	if kind == "DeadTree" then
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2 + self.rng:NextNumber(0, 1)
			part({ Name = "Branch", Size = Vector3.new(0.9 * scale, 8 * scale, 0.9 * scale), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 2 * scale, h * 0.5, math.sin(a) * 2 * scale)) * CFrame.Angles(math.cos(a) * 0.7, 0, math.sin(a) * 0.7), Material = Enum.Material.Wood, Color = trunkColor }, m)
		end
	elseif isPine then
		local c = if kind == "SnowPine" then LEAF.snow elseif kind == "CrystalPine" then LEAF.crystal else (leaf or LEAF.pine)
		for i = 0, 3 do
			local s = (13 - i * 3) * scale
			local cone = Instance.new("Part")
			cone.Name = "Leaves"
			cone.Anchored = true
			cone.Shape = Enum.PartType.Ball
			cone.Size = Vector3.new(s, s * 0.7, s)
			cone.CFrame = CFrame.new(pos + Vector3.new(0, h * (0.32 + i * 0.17), 0))
			cone.Material = if kind == "SnowPine" then Enum.Material.Snow else Enum.Material.Grass
			cone.Color = c
			cone.CastShadow = i < 2
			cone.Parent = m
		end
	else
		local s = 15 * scale
		local c = leaf or LEAF.default
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.75, s), CFrame = CFrame.new(pos + Vector3.new(0, h * 0.72, 0)), Material = Enum.Material.Grass, Color = c }, m)
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(s * 0.7, s * 0.55, s * 0.7), CFrame = CFrame.new(pos + Vector3.new(s * 0.3, h * 0.6, s * 0.15)), Material = Enum.Material.Grass, Color = c, CastShadow = false }, m)
	end
	m.Parent = parent
	return m
end

-- Modelos realistas (PBR) por tipo: {nome em WorldAssets, escala base}
local VARIANTS = {
	TallPine = { { "Pond1", 2.8 }, { "Pond2", 2.8 }, { "Pond3", 2.7 }, { "Pond4", 2.7 }, { "Pond5", 2.5 }, { "Pond6", 2.6 } },
	Pine = { { "Pond1", 1.3 }, { "Pond2", 1.3 }, { "Pond3", 1.25 }, { "Pond4", 1.25 } },
	Oak = { { "RealOak1", 1.4 }, { "RealOak2", 1.2 }, { "RealOak3", 1.3 }, { "RealOak5", 1.3 } },
	Tree2 = { { "RealOak1", 0.9 }, { "RealOak3", 0.9 }, { "RealOak5", 0.85 } },
	Bush = { { "RealOak4", 0.17 }, { "RealOak6", 0.15 }, { "Fern", 0.3 }, { "Fern", 0.3 } },
	Fern = { { "Fern", 0.3 } },
	Blossom = { { "Sakura", 0.62 } },
}
WorldBuilder.VARIANTS = VARIANTS

-- Rocha feita de terreno (2–3 bolas sobrepostas, meio enterradas): natural e leve
function WorldBuilder:terrainRock(pos: Vector3, scale: number)
	local rng = self.rng
	local mat = if rng:NextNumber() < 0.6 then Enum.Material.Rock else Enum.Material.Slate
	local r = 3.2 * scale
	Terrain:FillBall(pos + Vector3.new(0, -r * 0.35, 0), r, mat)
	for _ = 1, rng:NextInteger(1, 2) do
		local o = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * r
		Terrain:FillBall(pos + o + Vector3.new(0, -r * 0.5, 0), r * rng:NextNumber(0.55, 0.8), mat)
	end
end

local CollectionService = game:GetService("CollectionService")
local TREE_KINDS = { TallPine = true, Pine = true, Oak = true, Tree2 = true, Blossom = true, DeadTree = true, SnowPine = true, CrystalPine = true, Mushroom = true }
local SMALL_KINDS = { Bush = true, Fern = true, Flowers = true, FruitBush = true }
-- Log e Stump: sem vento e com colisão normal

-- Vegetação: folhas sem colisão (dá para atravessar), tronco com colisor simples,
-- e marcas para o vento do cliente (folhas balançando).
function WorldBuilder:finishVegetation(m: Instance, kind: string)
	if not m:IsA("Model") then
		return
	end
	local parts = {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	if #parts == 0 then
		return
	end
	if kind == "Log" or kind == "Stump" then
		return -- troncos caídos e tocos continuam sólidos
	end
	local bcf, size = m:GetBoundingBox()
	local base = bcf.Position - Vector3.new(0, size.Y / 2, 0)
	for _, p in ipairs(parts) do
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
	end
	if TREE_KINDS[kind] then
		local trunk, low = nil, math.huge
		if #parts >= 2 then
			for _, p in ipairs(parts) do
				local b = p.Position.Y - p.Size.Y / 2
				local foot = p.Size.X * p.Size.Z
				local score = b + foot * 0.002
				if p.Name == "Trunk" then
					score = -math.huge
				end
				if score < low then
					low, trunk = score, p
				end
			end
		end
		for _, p in ipairs(parts) do
			if p ~= trunk and #parts >= 2 then
				p:SetAttribute("SwayBase", base)
				p:SetAttribute("SwayH", size.Y)
				CollectionService:AddTag(p, "WindLeaf")
			end
		end
		local w = math.clamp(size.Y * 0.045, 1.6, 8)
		local ch = math.min(size.Y * 0.5, 45)
		part({ Name = "TrunkCollider", Shape = Enum.PartType.Cylinder, Size = Vector3.new(ch, w, w), CFrame = CFrame.new(base + Vector3.new(0, ch / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 1, CanCollide = true, CanQuery = false, CanTouch = false }, m)
	elseif SMALL_KINDS[kind] then
		for _, p in ipairs(parts) do
			p:SetAttribute("SwayBase", base)
			p:SetAttribute("SwayH", math.max(size.Y, 2))
			CollectionService:AddTag(p, "WindBush")
		end
	end
end

-- Planta árvore/arbusto/rocha no chão (pos já na superfície)
function WorldBuilder:plant(kind: string, pos: Vector3, scale: number, parent: Instance, leaf: Color3?)
	local m = self:plantRaw(kind, pos, scale, parent, leaf)
	if m then
		self:finishVegetation(m, kind)
	end
	return m
end

function WorldBuilder:plantRaw(kind: string, pos: Vector3, scale: number, parent: Instance, leaf: Color3?)
	local cf = CFrame.new(pos) * CFrame.Angles(0, self.rng:NextNumber(0, math.pi * 2), 0)
	if kind == "Boulder" then
		self:terrainRock(pos, scale)
		return nil
	end
	if kind == "Crystal" then
		return self.Props.crystalCluster(cf, parent, scale * 1.6, self.rng)
	elseif kind == "DeadTree" then
		return self.Props.deadTree(cf, parent, scale, self.rng)
	elseif kind == "CrystalPine" then
		return self:plantRaw("TallPine", pos, scale * 0.45, parent, leaf)
	end
	local vs = VARIANTS[kind]
	if vs then
		local v = vs[self.rng:NextInteger(1, #vs)]
		local m = self:placeAsset(v[1], cf, scale * v[2], parent, 0.5)
		if m then
			m.Name = kind
			return m
		end
	end
	local m = self:placeAsset(kind, cf, scale, parent, 0.6 * scale)
	if m then
		return m
	end
	if kind == "Log" or kind == "Stump" then
		local mm = Instance.new("Model")
		mm.Name = kind
		local bark = Color3.fromRGB(78 + self.rng:NextInteger(-8, 8), 58, 42)
		if kind == "Log" then
			local len = self.rng:NextNumber(12, 22) * scale
			local d = self.rng:NextNumber(2.2, 3.4) * scale
			local rot = CFrame.Angles(0, self.rng:NextNumber(0, math.pi * 2), 0)
			part({ Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, d, d), CFrame = CFrame.new(pos + Vector3.new(0, d * 0.35, 0)) * rot * CFrame.Angles(0, 0, math.rad(self.rng:NextNumber(-4, 4))), Material = Enum.Material.Wood, Color = bark }, mm)
			part({ Name = "Moss", Size = Vector3.new(len * 0.7, 0.3, d * 0.6), CFrame = CFrame.new(pos + Vector3.new(0, d * 0.82, 0)) * rot, Material = Enum.Material.Grass, Color = Color3.fromRGB(78, 112, 52), CanCollide = false, CastShadow = false }, mm)
		else
			local d = self.rng:NextNumber(3, 4.5) * scale
			part({ Name = "Stump", Shape = Enum.PartType.Cylinder, Size = Vector3.new(d * 0.8, d, d), CFrame = CFrame.new(pos + Vector3.new(0, d * 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Wood, Color = bark }, mm)
			for k = 0, 3 do
				local a = k / 4 * math.pi * 2 + self.rng:NextNumber(0, 1)
				part({ Name = "Root", Size = Vector3.new(d * 0.7, d * 0.25, d * 0.3), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * d * 0.55, d * 0.08, math.sin(a) * d * 0.55)) * CFrame.Angles(0, -a, math.rad(-15)), Material = Enum.Material.Wood, Color = bark }, mm)
			end
		end
		mm.Parent = parent
		return mm
	end
	if kind == "Flowers" then
		local mm = Instance.new("Model")
		mm.Name = "Flowers"
		self:flowers(pos, 2.5 * scale, 6, mm)
		mm.Parent = parent
		return mm
	elseif kind == "TallPine" then
		return self:simpleTree("Pine", pos, scale * 2, parent, leaf)
	end
	if kind == "Boulder" then
		local r = part({ Name = "Boulder", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 6, 8) * scale, CFrame = cf * CFrame.new(0, 1.5 * scale, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(118, 118, 112) }, parent)
		return r
	elseif kind == "Mushroom" then
		local mm = Instance.new("Model")
		mm.Name = "Mushroom"
		part({ Name = "Stem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(9 * scale, 2.4 * scale, 2.4 * scale), CFrame = CFrame.new(pos + Vector3.new(0, 4.5 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(235, 228, 210) }, mm)
		local cap = part({ Name = "Cap", Shape = Enum.PartType.Ball, Size = Vector3.new(11, 5, 11) * scale, CFrame = CFrame.new(pos + Vector3.new(0, 9.4 * scale, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(190, 90, 230), Transparency = 0.15 }, mm)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(200, 120, 255)
		l.Range = 14
		l.Brightness = 0.8
		l.Shadows = false
		l.Parent = cap
		mm.Parent = parent
		return mm
	end
	return self:simpleTree(kind, pos, scale, parent, leaf)
end

function WorldBuilder:lantern(pos: Vector3, facing: Vector3, parent: Instance)
	-- poste de madeira com lanterna pendurada, virado para `facing`
	local cf = CFrame.lookAt(pos, Vector3.new(facing.X, pos.Y, facing.Z))
	return self.Props.lanternPost(cf, parent)
end

-- estátua de dragão em pedra (modelo de dragão adulto sem textura, cor de pedra)
function WorldBuilder:dragonStatue(cf: CFrame, height: number, parent: Instance, alive: boolean?)
	local da = ServerStorage:FindFirstChild("DragonAssets")
	local wd = da and da:FindFirstChild("WesternDragon")
	local adult = wd and wd:FindFirstChild("Adult")
	if not adult then
		return nil
	end
	local st = adult:Clone()
	st.Name = if alive then "RestingDragon" else "DragonStatue"
	if not st:IsA("Model") then
		return nil
	end
	local _, s = st:GetBoundingBox()
	st:ScaleTo(st:GetScale() * (height / math.max(s.Y, 1)))
	for _, d in ipairs(st:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			if not alive then
				if d:IsA("MeshPart") then
					d.TextureID = ""
				end
				d.Material = Enum.Material.Slate
				d.Color = Color3.fromRGB(78, 76, 82)
			end
		elseif d:IsA("SurfaceAppearance") and not alive then
			d:Destroy()
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local yaw = st:GetAttribute("YawDegrees") or wd:GetAttribute("YawDegrees") or -15
	st:PivotTo(cf * CFrame.Angles(0, math.rad(yaw), 0))
	local bcf, sz = st:GetBoundingBox()
	st:PivotTo(st:GetPivot() + Vector3.new(0, cf.Position.Y - (bcf.Position.Y - sz.Y / 2), 0))
	st.Parent = parent
	return st
end

function WorldBuilder:flowers(center: Vector3, radius: number, count: number, parent: Instance)
	local colors = { Color3.fromRGB(250, 120, 160), Color3.fromRGB(255, 220, 90), Color3.fromRGB(170, 130, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 150, 70) }
	local rng = self.rng
	for _ = 1, count do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0, radius)
		local p = center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		part({ Name = "Flower", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = CFrame.new(p + Vector3.new(0, 0.6, 0)), Color = colors[rng:NextInteger(1, #colors)], Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, CastShadow = false }, parent)
	end
end

-- marcador invisível de zona (lido pelos sistemas de PvP/zonas)
local function zoneMarker(name: string, kind: string, pos: Vector3, radius: number, parent: Instance)
	local z = part({ Name = name, Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false }, parent)
	z:SetAttribute("Zone", kind)
	z:SetAttribute("Radius", radius)
	return z
end

--------------------------------------------------------------------------
-- Kits de bioma (bosques das fazendas e florestas)
--------------------------------------------------------------------------
-- {tipo, peso, escala mín, escala máx, cor da folha opcional}
local KITS = {
	meadow = { { "Oak", 5, 1.2, 1.6 }, { "Tree2", 3, 1.6, 2.1 }, { "Blossom", 1, 1.1, 1.4 }, { "TallPine", 2, 0.9, 1.2 } },
	pine = { { "TallPine", 8, 0.9, 1.3 }, { "Pine", 2, 1.6, 2.1 }, { "Oak", 1, 1.2, 1.5 } },
	lake = { { "Tree2", 6, 1.6, 2.2 }, { "Oak", 3, 1.2, 1.6 }, { "TallPine", 1, 0.9, 1.1 } },
	blossom = { { "Blossom", 6, 1.1, 1.5 }, { "Oak", 3, 1.1, 1.5 }, { "Tree2", 1, 1.5, 1.9 } },
	orchard = { { "Oak", 4, 1.0, 1.3 }, { "Tree2", 4, 1.4, 1.8 }, { "Blossom", 2, 1.0, 1.3 }, { "FruitBush", 2, 1.3, 1.8 } },
	oak = { { "Oak", 9, 1.6, 2.4 }, { "Tree2", 2, 1.6, 2.0 } },
	rainforest = { { "Tree2", 5, 1.8, 2.4 }, { "Oak", 3, 1.5, 2.0 }, { "TallPine", 3, 1.0, 1.4 } },
	enchanted = { { "Blossom", 4, 1.4, 2.0, LEAF.enchanted }, { "Tree2", 3, 1.6, 2.2 }, { "Mushroom", 3, 1.2, 2.4 } },
	fir = { { "TallPine", 7, 0.9, 1.3 }, { "Pine", 3, 1.5, 2.0 } },
	swamp = { { "Tree2", 6, 1.6, 2.2, LEAF.swamp }, { "DeadTree", 3, 1.4, 2.0 } },
	coast = { { "TallPine", 4, 0.8, 1.1 }, { "Pine", 4, 1.3, 1.8 }, { "Oak", 1, 1.0, 1.3 } },
	redrock = { { "TallPine", 5, 0.8, 1.1 }, { "DeadTree", 2, 1.3, 1.8 }, { "Pine", 2, 1.3, 1.7 } },
	snow = { { "TallPine", 6, 0.7, 1.0 }, { "Pine", 4, 1.0, 1.5 } },
	volcanic = { { "DeadTree", 6, 1.4, 2.2 }, { "Tree2", 1, 1.4, 1.8 } },
	crystal = { { "CrystalPine", 5, 1.4, 2.0 }, { "TallPine", 3, 0.9, 1.2 }, { "Crystal", 2, 0.6, 1.2 } },
	ruins = { { "Oak", 5, 1.5, 2.2 }, { "Tree2", 3, 1.6, 2.2 }, { "TallPine", 2, 0.9, 1.2 } },
	hidden = { { "Oak", 5, 1.8, 2.6 }, { "Blossom", 3, 1.4, 1.9 }, { "TallPine", 2, 1.1, 1.4 } },
	dark = { { "DeadTree", 5, 1.5, 2.4 }, { "TallPine", 3, 0.9, 1.2, Color3.fromRGB(36, 52, 40) } },
	mixed = { { "TallPine", 4, 0.9, 1.2 }, { "Oak", 4, 1.2, 1.6 }, { "Tree2", 3, 1.5, 2.0 } },
}
-- sub-bosque por kit (arbustos, rochas e flores nas bordas e clareiras)
local UNDER = {
	default = { { "Bush", 4, 1.0, 1.6 }, { "Fern", 4, 0.8, 1.3 }, { "Boulder", 1, 0.9, 2.2 }, { "Flowers", 3, 1.2, 2.0 }, { "Log", 1, 0.9, 1.3 }, { "Stump", 1, 0.8, 1.2 } },
	snow = { { "Boulder", 1, 1.0, 2.4 } },
	volcanic = { { "Boulder", 1, 1.0, 2.6 } },
	dark = { { "Boulder", 2, 1.0, 2.6 }, { "Bush", 1, 0.9, 1.3 } },
	swamp = { { "Bush", 4, 1.0, 1.6, LEAF.swamp }, { "Mushroom", 1, 0.5, 0.9 } },
	enchanted = { { "Mushroom", 3, 0.6, 1.2 }, { "Flowers", 4, 1.2, 2.0 }, { "Bush", 2, 1.0, 1.4 } },
	crystal = { { "Crystal", 1, 0.4, 0.8 }, { "Boulder", 2, 1.0, 2.0 } },
}
WorldBuilder.KITS = KITS

-- Escolha agrupada: pontos próximos tendem a receber a mesma espécie (bosquetes de 3–9)
function WorldBuilder:pickAt(kit, x: number, y: number)
	local total = 0
	for _, e in ipairs(kit) do
		total += e[2]
	end
	local u = math.clamp((math.noise(x / 55, y / 55, 41.3) * 1.6 + 1) / 2, 0, 0.999)
	u = (u + self.rng:NextNumber(-0.08, 0.08)) % 1
	local r = u * total
	for _, e in ipairs(kit) do
		r -= e[2]
		if r <= 0 then
			return e
		end
	end
	return kit[#kit]
end

function WorldBuilder:pick(kit)
	local total = 0
	for _, e in ipairs(kit) do
		total += e[2]
	end
	local r = self.rng:NextNumber(0, total)
	for _, e in ipairs(kit) do
		r -= e[2]
		if r <= 0 then
			return e
		end
	end
	return kit[1]
end

--------------------------------------------------------------------------
-- Pontes: onde estradas cruzam água
--------------------------------------------------------------------------
function WorldBuilder:waterAlong(x: number, y: number): (boolean, number, number)
	local c = self.gen:computeChunk(x, y, 1)
	local idx = 1 * c.W + 1 + 1
	return c.wl[idx] > c.h[idx] + 0.5, c.h[idx], c.wl[idx]
end

function WorldBuilder:buildBridge(a: Vector3, b: Vector3, deckY: number, width: number, parent: Instance, style: string)
	local m = Instance.new("Model")
	m.Name = "Bridge"
	local flatA = Vector3.new(a.X, deckY, a.Z)
	local flatB = Vector3.new(b.X, deckY, b.Z)
	local len = (flatB - flatA).Magnitude
	local dir = (flatB - flatA).Unit
	local side = dir:Cross(Vector3.yAxis).Unit
	local stone = style == "stone"
	local deckMat = if stone then Enum.Material.Cobblestone else Enum.Material.WoodPlanks
	local deckCol = if stone then STONE else Color3.fromRGB(140, 104, 66)
	local n = math.max(1, math.ceil(len / 12))
	for i = 0, n - 1 do
		local p0 = flatA:Lerp(flatB, i / n)
		local p1 = flatA:Lerp(flatB, (i + 1) / n)
		local mid = (p0 + p1) / 2
		part({ Name = "Deck", Size = Vector3.new(width, 1.2, (p1 - p0).Magnitude + 0.2), CFrame = CFrame.lookAt(mid, p1 + Vector3.new(0, 0, 0)), Material = deckMat, Color = deckCol }, m)
	end
	-- corrimãos e postes
	for _, s in ipairs({ -1, 1 }) do
		local off = side * s * (width / 2 - 0.4)
		local mid = (flatA + flatB) / 2 + off + Vector3.new(0, 2.6, 0)
		part({ Name = "Rail", Size = Vector3.new(0.6, 0.6, len), CFrame = CFrame.lookAt(mid, flatB + off + Vector3.new(0, 2.6, 0)), Material = if stone then Enum.Material.Cobblestone else Enum.Material.Wood, Color = if stone then STONE else WOOD }, m)
		local posts = math.max(2, math.floor(len / 10))
		for k = 0, posts do
			local p = flatA:Lerp(flatB, k / posts) + off
			part({ Name = "Post", Size = Vector3.new(0.9, 3.4, 0.9), CFrame = CFrame.new(p + Vector3.new(0, 1.5, 0)), Material = if stone then Enum.Material.Cobblestone else Enum.Material.Wood, Color = if stone then STONE else DARKWOOD }, m)
		end
	end
	-- pilares até o fundo a cada ~24 studs
	local piers = math.floor(len / 24)
	for k = 1, piers do
		local p = flatA:Lerp(flatB, k / (piers + 1))
		local hit = workspace:Raycast(p, Vector3.new(0, -80, 0), self.raySolid)
		local bottom = hit and hit.Position.Y or (deckY - 30)
		local h = deckY - bottom
		if h > 2 then
			for _, s in ipairs({ -1, 1 }) do
				local q = p + side * s * (width / 2 - 1.2)
				part({ Name = "Pier", Size = Vector3.new(1.6, h, 1.6), CFrame = CFrame.new(q.X, bottom + h / 2 - 0.6, q.Z), Material = if stone then Enum.Material.Cobblestone else Enum.Material.Wood, Color = if stone then STONE else DARKWOOD }, m)
			end
		end
	end
	m.Parent = parent
	return m
end

function WorldBuilder:buildBridges()
	self:status("bridges")
	local folder = self:container("Bridges", self:worldFolder())
	local count = 0
	for ri, road in ipairs(self.data.ROADS) do
		local WorldGen = require((self.folder :: any).WorldGen:Clone())
		local pts = WorldGen.sampleOpen(road, 6)
		local inWater = false
		local startIdx = 0
		for i, p in ipairs(pts) do
			local wet = self:waterAlong(p[1], p[2])
			if wet and not inWater then
				inWater = true
				startIdx = i
			elseif (not wet or i == #pts) and inWater then
				inWater = false
				local i0 = math.max(1, startIdx - 3)
				local i1 = math.min(#pts, i + 2)
				local a, b = pts[i0], pts[i1]
				local ya = self:groundY(a[1], a[2])
				local yb = self:groundY(b[1], b[2])
				local _, _, wl = self:waterAlong(pts[startIdx][1], pts[startIdx][2])
				local deckY = math.max(ya, yb, wl + 5) + 0.6
				local len = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
				local style = if len < 140 and ri % 2 == 0 then "stone" else "wood"
				local br = self:buildBridge(V(a[1], a[2]), V(b[1], b[2]), deckY, if len > 200 then 10 else 14, folder, style)
				br:SetAttribute("Road", ri)
				-- rampas de terra nas pontas para subir até o tabuleiro
				for _, e in ipairs({ { a, ya }, { b, yb } }) do
					if deckY - e[2] > 1.5 then
						Terrain:FillBall(V(e[1][1], e[1][2], deckY - 6), 7, Enum.Material.Ground)
					end
				end
				count += 1
			end
		end
		task.wait()
	end
	return count
end

--------------------------------------------------------------------------
-- Hub — Ilha do Coração
--------------------------------------------------------------------------
function WorldBuilder:buildHub()
	self:status("hub")
	local H = self.data.HUB
	local hub = self:container("Hub", workspace)
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = hub
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = hub
	local gy = self:groundY(H.x, H.y)
	local C = V(H.x, H.y, gy)
	local function at(dx: number, dy: number): Vector3
		return V(H.x + dx, H.y + dy, self:groundY(H.x + dx, H.y + dy))
	end
	-- praça de pedra e anel de calçada
	self:paintDisc(H.x, H.y, 96, Enum.Material.Cobblestone)
	self:paintDisc(H.x, H.y, 70, Enum.Material.Pavement)
	-- ruas de pedra da praça até a beira da ilha (seguindo as estradas)
	for _, road in ipairs(self.data.ROADS) do
		if road[1][1] == H.x and road[1][2] == H.y then
			local p1 = road[2]
			local dx, dy = p1[1] - H.x, p1[2] - H.y
			local L = math.sqrt(dx * dx + dy * dy)
			dx, dy = dx / L, dy / L
			self:paintStrip(V(H.x + dx * 90, H.y + dy * 90), V(H.x + dx * (H.r0 + 60), H.y + dy * (H.r0 + 60)), 14, Enum.Material.Cobblestone)
		end
	end
	task.wait()
	-- chafariz central
	if not self.Props.fountain(CFrame.new(C), plaza) then
		part({ Name = "Fountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 22, 22), CFrame = CFrame.new(C + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Cobblestone, Color = STONE }, plaza)
	end
	-- Torre do Dragão (marco visível de longe), ao norte da praça
	local towerBase = at(0, 135)
	local tower = Instance.new("Model")
	tower.Name = "DragonTower"
	part({ Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 34, 34), CFrame = CFrame.new(towerBase + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(128, 124, 118) }, tower)
	part({ Name = "Shaft", Shape = Enum.PartType.Cylinder, Size = Vector3.new(86, 24, 24), CFrame = CFrame.new(towerBase + Vector3.new(0, 47, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(160, 154, 144) }, tower)
	part({ Name = "Crown", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 30, 30), CFrame = CFrame.new(towerBase + Vector3.new(0, 92, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(128, 124, 118) }, tower)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		part({ Name = "Merlon", Size = Vector3.new(4, 5, 4), CFrame = CFrame.new(towerBase + Vector3.new(math.cos(a) * 13, 97.5, math.sin(a) * 13)), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(128, 124, 118) }, tower)
	end
	local beacon = part({ Name = "Beacon", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), CFrame = CFrame.new(towerBase + Vector3.new(0, 99, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 170, 70) }, tower)
	local bl = Instance.new("PointLight")
	bl.Range = 60
	bl.Brightness = 2
	bl.Color = Color3.fromRGB(255, 170, 90)
	bl.Shadows = false
	bl.Parent = beacon
	local banner = part({ Name = "Banner", Size = Vector3.new(0.3, 14, 8), CFrame = CFrame.new(towerBase + Vector3.new(0, 72, 12.4)) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(160, 40, 40) }, tower)
	banner.CastShadow = false
	-- estátua de dragão no alto (modelo de dragão adulto, se existir)
	local da = ServerStorage:FindFirstChild("DragonAssets")
	local wd = da and da:FindFirstChild("WesternDragon")
	local adult = wd and wd:FindFirstChild("Adult")
	if adult then
		local st = adult:Clone()
		st.Name = "DragonStatue"
		if st:IsA("Model") then
			local _, s = st:GetBoundingBox()
			st:ScaleTo(st:GetScale() * (22 / math.max(s.X, s.Z)))
			for _, d in ipairs(st:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			st:PivotTo(CFrame.new(towerBase + Vector3.new(0, 95, 0)) * CFrame.Angles(0, math.rad(-15 + 180), 0))
			local bcf, sz = st:GetBoundingBox()
			st:PivotTo(st:GetPivot() + Vector3.new(0, (towerBase.Y + 95) - (bcf.Position.Y - sz.Y / 2), 0))
			st.Parent = tower
		end
	end
	tower.Parent = plaza
	-- estações dos NPCs (mesmo layout já aprovado)
	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "NPCs"
	npcFolder.Parent = hub
	local STATIONS = {
		{ Id = "Merchant", Angle = 45, Asset = "Stall" },
		{ Id = "QuestMaster", Angle = 135, Asset = "QuestBoard" },
		{ Id = "Caretaker", Angle = 225, Asset = "Stall" },
		{ Id = "Guard", Angle = 315, Asset = nil },
	}
	for _, st in ipairs(STATIONS) do
		local a = math.rad(st.Angle)
		local pos = C + Vector3.new(math.cos(a) * 52, 0, math.sin(a) * 52)
		local facing = CFrame.lookAt(pos, C)
		if st.Asset == "Stall" then
			self.Props.stall(facing * CFrame.new(0, 0, 5), plaza, self.rng)
		elseif st.Asset == "QuestBoard" then
			self.Props.noticeBoard(facing * CFrame.new(0, 0, 5) * CFrame.Angles(0, math.rad(180), 0), plaza)
		end
		local marker = part({ Name = st.Id, Size = Vector3.new(2, 1, 2), CFrame = facing * CFrame.new(0, 0.5, -2), Transparency = 1, CanCollide = false, CanQuery = false }, npcFolder)
		marker:SetAttribute("NpcId", st.Id)
	end
	-- mesa do cartógrafo (único mapa do jogo, D8)
	local mapTable = part({ Name = "MapTable", Size = Vector3.new(10, 3.2, 6), CFrame = CFrame.new(C + Vector3.new(-22, 1.6, -28)), Material = Enum.Material.WoodPlanks, Color = WOOD }, plaza)
	mapTable:SetAttribute("MapTable", true)
	part({ Name = "MapSheet", Size = Vector3.new(8.6, 0.1, 4.6), CFrame = CFrame.new(C + Vector3.new(-22, 3.25, -28)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(226, 208, 160) }, plaza)
	-- bancos, flores e lanternas da praça
	for i = 0, 7 do
		local a = (i / 8) * math.pi * 2 + math.rad(22.5)
		local p = C + Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30)
		local cf = CFrame.lookAt(p, C)
		part({ Name = "BenchSeat", Size = Vector3.new(6, 0.5, 1.8), CFrame = cf * CFrame.new(0, 1.6, 0), Material = Enum.Material.WoodPlanks, Color = WOOD }, plaza)
		part({ Name = "BenchBack", Size = Vector3.new(6, 1.6, 0.3), CFrame = cf * CFrame.new(0, 2.6, 0.9), Material = Enum.Material.WoodPlanks, Color = WOOD }, plaza)
		self:flowers(C + Vector3.new(math.cos(a + 0.35) * 38, 0, math.sin(a + 0.35) * 38), 3, 10, decor)
	end
	for k = 0, 15 do
		local a = (k + 0.5) / 16 * math.pi * 2
		self:lantern(C + Vector3.new(math.cos(a) * 98, 0, math.sin(a) * 98), C, plaza)
	end
	task.wait()
	-- casas da vila ao longo das ruas que saem da praça, viradas para a rua
	local houses = Instance.new("Folder")
	houses.Name = "Village"
	houses.Parent = hub
	local placedAt = {}
	local placed = 0
	local function freeSpot(x: number, y: number, minD: number): boolean
		if self:roadDist(x, y) < 17 then
			return false
		end
		if math.abs(x - H.x) < 34 and y > H.y + 100 and y < H.y + 175 then
			return false -- torre
		end
		for _, q in ipairs(placedAt) do
			if (q[1] - x) ^ 2 + (q[2] - y) ^ 2 < minD * minD then
				return false
			end
		end
		return true
	end
	local function house(x: number, y: number, faceX: number, faceY: number)
		local pos = V(x, y, self:groundY(x, y))
		local cf = CFrame.lookAt(pos, V(faceX, faceY, pos.Y))
		if not self.Props.house(cf * CFrame.new(0, -0.6, 0), houses, self.rng) then
			part({ Name = "Cottage", Size = Vector3.new(18, 11, 14), CFrame = cf * CFrame.new(0, 5.5, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(196, 170, 130) }, houses)
		end
		table.insert(placedAt, { x, y })
		placed += 1
		-- quintal: cerca baixa, barril ou canteiro
		local back = cf * CFrame.new(0, 0, 16)
		if self.rng:NextNumber() < 0.5 then
			self:flowers(back.Position, 4, 8, decor)
		else
			part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.4, 2.6, 2.6), CFrame = (cf * CFrame.new(9, 1.7, -6)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 46) }, decor)
		end
	end
	for _, road in ipairs(self.data.ROADS) do
		if road[1][1] == H.x and road[1][2] == H.y then
			local p1 = road[2]
			local dx, dy = p1[1] - H.x, p1[2] - H.y
			local Ld = math.sqrt(dx * dx + dy * dy)
			dx, dy = dx / Ld, dy / Ld
			local px, py = -dy, dx
			for r = 120, 300, 42 do
				for _, s in ipairs({ -1, 1 }) do
					local sx, sy = H.x + dx * r, H.y + dy * r
					local x, y = sx + px * s * 26, sy + py * s * 26
					if freeSpot(x, y, 32) then
						house(x, y, sx, sy)
						if self.rng:NextNumber() < 0.5 then
							self:lantern(V(sx + px * s * 11, sy + py * s * 11, self:groundY(sx + px * s * 11, sy + py * s * 11)), V(sx, sy, 0), decor)
						end
					end
				end
			end
			task.wait()
		end
	end
	-- casas soltas entre as ruas
	for _ = 1, 120 do
		if placed >= 70 then
			break
		end
		local a = self.rng:NextNumber(0, math.pi * 2)
		local R = self.rng:NextNumber(125, 285)
		local x, y = H.x + math.cos(a) * R, H.y + math.sin(a) * R
		if freeSpot(x, y, 30) then
			house(x, y, H.x, H.y)
		end
	end
	-- barracas de mercado em volta da praça
	for k = 0, 11 do
		local a = (k + 0.5) / 12 * math.pi * 2
		local x, y = H.x + math.cos(a) * 84, H.y + math.sin(a) * 84
		if self:roadDist(x, y) > 12 and self.rng:NextNumber() < 0.75 then
			local pos = V(x, y, self:groundY(x, y))
			self.Props.stall(CFrame.lookAt(pos, Vector3.new(C.X, pos.Y, C.Z)), decor, self.rng)
		end
	end
	task.wait()
	-- árvores floridas e arbustos na borda da ilha
	for k = 0, 59 do
		local a = k / 60 * math.pi * 2 + self.rng:NextNumber(-0.03, 0.03)
		local R = self.rng:NextNumber(300, 345)
		local x, y = H.x + math.cos(a) * R, H.y + math.sin(a) * R
		if self:roadDist(x, y) > 18 then
			local hit = self:surface(x, y)
			if hit and hit.Material ~= Enum.Material.Water then
				local kind = if k % 3 == 0 then "Blossom" elseif k % 3 == 1 then "Oak" else "Bush"
				self:plant(kind, hit.Position, self.rng:NextNumber(0.8, 1.1), decor)
			end
		end
	end
	-- ponto de nascimento padrão (antes de receber a fazenda)
	local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if not sp then
		sp = Instance.new("SpawnLocation")
		sp.Parent = workspace
	end
	local spawn = sp :: SpawnLocation
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(C + Vector3.new(0, 0.5, 24))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	zoneMarker("HubSafeZone", "Safe", C, H.r1 + 30, hub)
	return placed
end

--------------------------------------------------------------------------
-- Fazendas
--------------------------------------------------------------------------
local FARM = 200
local HALF = FARM / 2
local S = 1.45 -- espalha o layout interno (projetado para 130 x 130)

function WorldBuilder:farmEntrance(f): (number, number)
	-- direção da estrada que chega na fazenda (ponto da estrada a ~350 studs do centro)
	local best, bx, by = math.huge, nil, nil
	local WorldGen = require((self.folder :: any).WorldGen:Clone())
	for _, road in ipairs(self.data.ROADS) do
		local pts = WorldGen.sampleOpen(road, 20)
		for _, p in ipairs(pts) do
			local d = math.sqrt((p[1] - f.x) ^ 2 + (p[2] - f.y) ^ 2)
			local hubD = math.sqrt((p[1] - self.data.HUB.x) ^ 2 + (p[2] - self.data.HUB.y) ^ 2)
			local score = hubD + math.abs(d - 360) * 4 -- lado da estrada que vem do Hub
			if d > 250 and d < 480 and score < best then
				best, bx, by = score, p[1], p[2]
			end
		end
	end
	if not bx then
		bx, by = self.data.HUB.x, self.data.HUB.y
	end
	local dx, dy = bx - f.x, by - f.y
	local L = math.sqrt(dx * dx + dy * dy)
	return dx / L, dy / L
end

function WorldBuilder:buildFarm(f, parent: Instance): Model
	local rng = self.rng
	local gy = self:groundY(f.x, f.y)
	local ex, ey = self:farmEntrance(f)
	local center = V(f.x, f.y, gy)
	local F = CFrame.lookAt(center, center + Vector3.new(ex, 0, -ey)) -- -Z aponta para a entrada
	local model = Instance.new("Model")
	model.Name = string.format("Plot%02d", f.id)
	local function L(x, y, z)
		return F * CFrame.new(x * S, y, z * S)
	end
	local function W(x, z)
		local p = (F * CFrame.new(x * S, 0, z * S)).Position
		return Vector3.new(p.X, self:groundY(p.X, -p.Z), p.Z)
	end
	local function Wraw(x, z) -- sem escala (para a cerca)
		local p = (F * CFrame.new(x, 0, z)).Position
		return Vector3.new(p.X, self:groundY(p.X, -p.Z), p.Z)
	end
	local base = part({ Name = "Base", Size = Vector3.new(FARM, 1, FARM), CFrame = F * CFrame.new(0, 0.5, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false }, model)
	model.PrimaryPart = base
	local function att(name: string, cf: CFrame)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Parent = base
		a.WorldCFrame = cf
	end
	-- caminho interno de pedras da entrada ao centro
	self:paintStrip((F * CFrame.new(0, 0, -HALF - 6)).Position, (F * CFrame.new(0, 0, -6)).Position, 10, Enum.Material.Cobblestone)
	-- cerca com abertura na entrada
	local fence = Instance.new("Model")
	fence.Name = "Fence"
	fence.Parent = model
	local corners = { Vector3.new(-HALF, 0, -HALF), Vector3.new(HALF, 0, -HALF), Vector3.new(HALF, 0, HALF), Vector3.new(-HALF, 0, HALF) }
	local function rail(a: Vector3, b: Vector3)
		local n = math.max(1, math.floor((b - a).Magnitude / 8))
		local prev = Wraw(a.X, a.Z)
		for i = 1, n do
			local q = a:Lerp(b, i / n)
			local cur = Wraw(q.X, q.Z)
			local len = (cur - prev).Magnitude
			local mid = (cur + prev) / 2
			for _, yy in ipairs({ 1.4, 2.8 }) do
				part({ Name = "Rail", Size = Vector3.new(0.5, 0.45, len), CFrame = CFrame.lookAt(mid + Vector3.new(0, yy, 0), cur + Vector3.new(0, yy, 0)), Material = Enum.Material.Wood, Color = WOOD }, fence)
			end
			part({ Name = "Post", Size = Vector3.new(0.9, 3.8, 0.9), CFrame = CFrame.new(cur + Vector3.new(0, 1.6, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, fence)
			prev = cur
		end
	end
	rail(corners[2], corners[3])
	rail(corners[3], corners[4])
	rail(corners[4], corners[1])
	rail(corners[1], Vector3.new(-12, 0, -HALF))
	rail(Vector3.new(12, 0, -HALF), corners[2])
	-- arco de entrada com placa
	local archPos = Wraw(0, -HALF - 1)
	local archCF = CFrame.new(archPos) * F.Rotation
	do -- arco de madeira (peças com material real)
		part({ Name = "ArchPillar", Size = Vector3.new(1.6, 14, 1.6), CFrame = archCF * CFrame.new(-10, 7, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
		part({ Name = "ArchPillar", Size = Vector3.new(1.6, 14, 1.6), CFrame = archCF * CFrame.new(10, 7, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
		part({ Name = "ArchBeam", Size = Vector3.new(23, 1.6, 2), CFrame = archCF * CFrame.new(0, 14.5, 0), Material = Enum.Material.Wood, Color = WOOD }, model)
	end
	local sign = part({ Name = "Sign", Size = Vector3.new(11, 2.6, 0.35), CFrame = archCF * CFrame.new(0, 12.5, -2.2), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 108, 66) }, model)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "SignGui"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Name = "Owner"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 244, 220)
		label.TextStrokeTransparency = 0.5
		label.Text = "Fazenda livre"
		label.Parent = gui
	end
	self:lantern(Wraw(-15, -HALF - 5), center, model)
	self:lantern(Wraw(15, -HALF - 5), center, model)
	-- habitat do ovo
	local nestPos = W(-38, 38)
	local nest = self.Props.nest(CFrame.new(nestPos), model, 1.1, rng)
	local nestTop = nestPos.Y + 2.2
	if nest then
		nest.Name = "Nest"
		local _, s = nest:GetBoundingBox()
		nestTop = nestPos.Y + s.Y * 0.55
	else
		part({ Name = "Nest", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 12, 12), CFrame = CFrame.new(nestPos + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(196, 160, 90) }, model)
	end
	local shelter = Instance.new("Model")
	shelter.Name = "NestShelter"
	shelter.Parent = model
	for _, o in ipairs({ { -10, -10 }, { 10, -10 }, { -10, 10 }, { 10, 10 } }) do
		part({ Name = "Post", Size = Vector3.new(1.2, 13, 1.2), CFrame = CFrame.new(nestPos + Vector3.new(o[1], 6.5, o[2])), Material = Enum.Material.Wood, Color = DARKWOOD }, shelter)
	end
	local roofRot = F.Rotation
	local w1 = Instance.new("WedgePart")
	w1.Name = "Roof"
	w1.Anchored = true
	w1.Size = Vector3.new(24, 5, 12)
	w1.CFrame = CFrame.new(nestPos + Vector3.new(0, 15.5, 0)) * roofRot * CFrame.new(0, 0, -6) * CFrame.Angles(0, math.rad(180), 0)
	w1.Material = Enum.Material.Fabric
	w1.Color = Color3.fromRGB(200, 168, 98)
	w1.Parent = shelter
	local w2 = w1:Clone()
	w2.CFrame = CFrame.new(nestPos + Vector3.new(0, 15.5, 0)) * roofRot * CFrame.new(0, 0, 6)
	w2.Parent = shelter
	local warm = part({ Name = "NestWarmth", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(nestPos + Vector3.new(0, 3, 0)), Transparency = 1, CanCollide = false, CanQuery = false }, model)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 90)
	light.Brightness = 0.8
	light.Range = 12
	light.Parent = warm
	att("EggSpot", CFrame.new(nestPos.X, nestTop + 2.2, nestPos.Z) * F.Rotation)
	self:flowers(nestPos, 14, 10, model)
	-- celeiro
	local barnPos = W(40, 44)
	if not self.Props.barn(CFrame.new(barnPos) * F.Rotation * CFrame.Angles(0, math.rad(180), 0), model, 1.1) then
		part({ Name = "Barn", Size = Vector3.new(26, 16, 20), CFrame = CFrame.new(barnPos + Vector3.new(0, 8, 0)) * F.Rotation, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 70, 50) }, model)
	end
	-- cocho, bebedouro e baú
	local function onGround(x, y, z)
		local p = W(x, z)
		return CFrame.new(p + Vector3.new(0, y, 0)) * F.Rotation
	end
	part({ Name = "FoodTrough", Size = Vector3.new(9, 2, 3.5), CFrame = onGround(14, 1, 26), Material = Enum.Material.WoodPlanks, Color = WOOD }, model)
	part({ Name = "Hay", Size = Vector3.new(8, 0.6, 3), CFrame = onGround(14, 2.1, 26), Material = Enum.Material.Fabric, Color = Color3.fromRGB(214, 182, 96), CanCollide = false }, model)
	part({ Name = "WaterTrough", Size = Vector3.new(9, 2, 3.5), CFrame = onGround(26, 1, 18), Material = Enum.Material.Slate, Color = Color3.fromRGB(122, 124, 130) }, model)
	part({ Name = "Water", Size = Vector3.new(8, 0.3, 2.8), CFrame = onGround(26, 2.05, 18), Material = Enum.Material.Glass, Color = Color3.fromRGB(70, 150, 230), Transparency = 0.25, CanCollide = false }, model)
	part({ Name = "StorageChest", Size = Vector3.new(5, 3.4, 3.4), CFrame = onGround(24, 1.7, 34), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 96, 52) }, model)
	part({ Name = "ChestBand", Size = Vector3.new(5.1, 0.4, 3.5), CFrame = onGround(24, 2.6, 34), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 170, 80) }, model)
	for i, o in ipairs({ { 56, 26 }, { 58, 31 }, { 54, 30 } }) do
		part({ Name = "HayBale", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 3.6, 3.6), CFrame = onGround(o[1], 1.8 + (if i == 3 then 3.2 else 0), o[2]) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(222, 190, 100) }, model)
	end
	for _, o in ipairs({ { 24, 46 }, { 27, 47 } }) do
		part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.6, 2.8, 2.8), CFrame = onGround(o[1], 1.8, o[2]) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 46) }, model)
	end
	-- área de treino
	do
		local c = L(44, 0, -30).Position
		self:paintDisc(c.X, -c.Z, 15 * S, Enum.Material.Sand)
	end
	part({ Name = "TrainingPost", Size = Vector3.new(2, 8, 2), CFrame = onGround(44, 4, -30), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
	for _, o in ipairs({ { 36, -22 }, { 52, -38 } }) do
		local dummy = Instance.new("Model")
		dummy.Name = "TrainingDummy"
		dummy.Parent = model
		part({ Name = "Stake", Size = Vector3.new(0.8, 6, 0.8), CFrame = onGround(o[1], 3, o[2]), Material = Enum.Material.Wood, Color = DARKWOOD }, dummy)
		part({ Name = "Body", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 2.6, 2.6), CFrame = onGround(o[1], 5, o[2]) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(210, 180, 120) }, dummy)
		part({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = onGround(o[1], 7.8, o[2]), Material = Enum.Material.Fabric, Color = Color3.fromRGB(210, 180, 120) }, dummy)
	end
	-- horta
	for row = 0, 2 do
		self:paintStrip(L(-60, 0, -40 + row * 8).Position, L(-28, 0, -40 + row * 8).Position, 6, Enum.Material.Mud)
		for c = 0, 4 do
			part({ Name = "Crop", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.6, 1.8), CFrame = onGround(-52 + c * 4, 1.2, -40 + row * 8), Material = Enum.Material.Grass, Color = if row == 1 then Color3.fromRGB(230, 120, 60) else Color3.fromRGB(110, 180, 70), CanCollide = false }, model)
		end
	end
	-- 8 lugares para dragões
	local pens = { { 0, 4 }, { -22, 0 }, { 22, 0 }, { -12, 20 }, { 12, 22 }, { -22, -18 }, { 22, -16 }, { 0, -22 } }
	for i, o in ipairs(pens) do
		local p = W(o[1], o[2])
		att("Pen" .. i, CFrame.new(p) * F.Rotation)
		part({ Name = "StrawBed", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 10, 10), CFrame = CFrame.new(p + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(214, 184, 110), CanCollide = false, CastShadow = false }, model)
	end
	-- laguinho
	local pond = L(2, 0, 50)
	Terrain:FillCylinder(pond * CFrame.new(0, 2, 0), 14, 12, Enum.Material.Air)
	Terrain:FillCylinder(pond * CFrame.new(0, -7, 0), 4, 13.5, Enum.Material.Slate)
	Terrain:FillCylinder(pond * CFrame.new(0, -2.5, 0), 5, 12, Enum.Material.Water)
	pond = pond * CFrame.new(0, -5, 0)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local p = (pond * CFrame.new(math.cos(a) * 13.5, 0, math.sin(a) * 13.5)).Position
		part({ Name = "PondStone", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 1.6, 2.2) * rng:NextNumber(0.8, 1.3), CFrame = CFrame.new(p.X, self:groundY(p.X, -p.Z) + 0.3, p.Z), Material = Enum.Material.Slate, Color = Color3.fromRGB(128, 132, 124) }, model)
	end
	-- poço
	local wellPos = W(-54, 6)
	part({ Name = "WellRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 6, 6), CFrame = CFrame.new(wellPos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(140, 140, 136) }, model)
	part({ Name = "WellRoof", Size = Vector3.new(7, 0.5, 4.5), CFrame = CFrame.new(wellPos + Vector3.new(0, 7.6, 0)) * F.Rotation, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 70, 50) }, model)
	for _, s in ipairs({ -1, 1 }) do
		part({ Name = "WellPost", Size = Vector3.new(0.6, 6, 0.6), CFrame = CFrame.new(wellPos + (F.Rotation * Vector3.new(s * 2.6, 0, 0)) + Vector3.new(0, 4.5, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
	end
	-- lanternas nos cantos e arbustos na cerca
	for _, o in ipairs({ { -HALF + 5, -HALF + 5 }, { HALF - 5, -HALF + 5 }, { -HALF + 5, HALF - 5 }, { HALF - 5, HALF - 5 } }) do
		self:lantern(Wraw(o[1], o[2]), center, model)
	end
	local kit = KITS[f.biome] or KITS.mixed
	for t = -HALF + 12, HALF - 12, 16 do
		for _, pos in ipairs({ Wraw(-HALF + 5, t), Wraw(HALF - 5, t), Wraw(t, HALF - 5) }) do
			if rng:NextNumber() < 0.7 then
				self:plant("Bush", pos, rng:NextNumber(0.6, 0.95), model, (kit[1] and kit[1][5]) or nil)
			else
				self:flowers(pos, 2.5, 6, model)
			end
		end
	end
	att("Spawn", CFrame.new(Wraw(0, -HALF + 12) + Vector3.new(0, 3, 0)) * F.Rotation * CFrame.Angles(0, math.rad(180), 0))
	model:SetAttribute("PlotIndex", f.id)
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("FarmName", f.name)
	model:SetAttribute("Tier", f.tier)
	model:SetAttribute("Biome", f.biome)
	model:SetAttribute("MapX", f.x)
	model:SetAttribute("MapY", f.y)
	model.Parent = parent
	zoneMarker("SafeZone", "Safe", center, 145, model)
	return model
end

-- Bosque em camadas em volta da fazenda, com contorno irregular, bosquetes da mesma
-- espécie, sub-bosque de arbustos e um corredor de entrada voltado para a estrada.
function WorldBuilder:buildGrove(f, parent: Instance): number
	local rng = self.rng
	local ex, ey = self:farmEntrance(f)
	local kit = KITS[f.biome] or KITS.mixed
	local leaf = kit[1][5]
	local grove = Instance.new("Model")
	grove.Name = string.format("Grove%02d", f.id)
	local n = 0
	local SP = 22
	local seed = f.id * 7.31
	for gx = -380, 380, SP do
		for gy = -380, 380, SP do
			local ox, oy = gx + rng:NextNumber(-0.45, 0.45) * SP, gy + rng:NextNumber(-0.45, 0.45) * SP
			local r = math.sqrt(ox * ox + oy * oy)
			local a = math.atan2(oy, ox)
			local ca, sa = math.cos(a), math.sin(a)
			-- contorno irregular (ruído pelo ângulo)
			local rin = 150 + 18 * math.noise(ca * 1.7, sa * 1.7, seed)
			local rout = 300 + 55 * math.noise(ca * 1.3 + 5, sa * 1.3, seed + 3) + 25 * math.noise(ca * 4, sa * 4, seed + 9)
			if r > rin and r < rout + 70 then
				local along = (ox * ex + oy * ey) / r
				local lateral = math.abs(ox * ey - oy * ex)
				if not (along > 0 and lateral < 13) then
					local x, y = f.x + ox, f.y + oy
					local clump = math.noise(x / 45, y / 45, seed + 17)
					local p
					if r < rout then
						p = 0.5 + 0.3 * clump -- denso com pequenas clareiras
					else
						p = 0.12 * (1 - (r - rout) / 70) + 0.1 * clump -- árvores soltas além da borda
					end
					if rng:NextNumber() < p then
						local hit = self:surface(x, y)
						if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y > 0.72 and self:roadDist(x, y) > 11 then
							local e
							if r < rin + 14 then
								e = { "Bush", 1, 0.7, 1.2, leaf } -- borda interna baixa (deixa ver só relances)
							else
								e = self:pickAt(kit, x, y)
							end
							self:plant(e[1], hit.Position, rng:NextNumber(e[3], e[4]), grove, e[5])
							n += 1
							if e[1] ~= "Bush" and rng:NextNumber() < 0.35 then
								local bx, by = x + rng:NextNumber(-6, 6), y + rng:NextNumber(-6, 6)
								local bh = self:surface(bx, by)
								if bh and bh.Material ~= Enum.Material.Water then
									self:plant("Bush", bh.Position, rng:NextNumber(0.6, 1.0), grove, leaf)
									n += 1
								end
							end
						end
					end
				end
			end
		end
	end
	grove.Parent = parent
	return n
end

function WorldBuilder:buildFarms(only: { number }?)
	local farms = workspace:FindFirstChild("Farms")
	if not farms or not only then
		farms = self:container("Farms", workspace)
	end
	local groves = workspace:FindFirstChild("World") and (workspace :: any).World:FindFirstChild("Groves")
	if not groves or not only then
		groves = self:container("Groves", self:worldFolder())
	end
	local total = 0
	for _, f in ipairs(self.data.FARMS) do
		if not only or table.find(only, f.id) then
			self:status("farm " .. f.id)
			local old = (farms :: Instance):FindFirstChild(string.format("Plot%02d", f.id))
			if old then
				old:Destroy()
			end
			local oldG = (groves :: Instance):FindFirstChild(string.format("Grove%02d", f.id))
			if oldG then
				oldG:Destroy()
			end
			self:buildFarm(f, farms :: Instance)
			task.wait()
			total += self:buildGrove(f, groves :: Instance)
			task.wait()
		end
	end
	return total
end

--------------------------------------------------------------------------
-- Acampamentos, waypoints, marcos, castelo, dungeon
--------------------------------------------------------------------------
-- Direção (no mapa) da estrada mais próxima de um ponto
function WorldBuilder:roadDirection(x: number, y: number): (number, number)
	local best, bx, by = math.huge, nil, nil
	local WorldGen = require((self.folder :: any).WorldGen:Clone())
	for _, road in ipairs(self.data.ROADS) do
		for _, p in ipairs(WorldGen.sampleOpen(road, 10)) do
			local d = (p[1] - x) ^ 2 + (p[2] - y) ^ 2
			if d < best then
				best, bx, by = d, p[1], p[2]
			end
		end
	end
	if not bx then
		return 0, -1
	end
	local dx, dy = bx - x, by - y
	local L = math.max(1, math.sqrt(dx * dx + dy * dy))
	return dx / L, dy / L
end

-- Acampamentos para dragões (D10): área cercada de ~180 studs ao lado da estrada, com
-- portão, círculo de pouso, lagoa-bebedouro, área de alimentação, estábulo aberto com
-- baias e camas de palha, torres-poleiro, cabana do tratador e braseiros.
function WorldBuilder:buildCamps()
	self:status("camps")
	local folder = self:container("Camps", self:worldFolder())
	local rng = self.rng
	local WOODC, DARK = WOOD, DARKWOOD
	for i, c in ipairs(self.data.CAMPS) do
		local m = Instance.new("Model")
		m.Name = string.format("DragonCamp%02d", i)
		local ex, ey = self:roadDirection(c.x, c.y)
		local gy = self:groundY(c.x, c.y)
		local C = V(c.x, c.y, gy)
		-- -Z local aponta para a estrada (portão)
		local R = CFrame.lookAt(C, C + Vector3.new(ex, 0, -ey))
		local function at(dx: number, dz: number): Vector3
			local p = (R * CFrame.new(dx, 0, dz)).Position
			return Vector3.new(p.X, self:groundY(p.X, -p.Z), p.Z)
		end
		local function cfAt(dx: number, dz: number, yaw: number?): CFrame
			return CFrame.new(at(dx, dz)) * R.Rotation * CFrame.Angles(0, math.rad(yaw or 0), 0)
		end
		local function p(props)
			return part(props, m)
		end

		-- chão: terra batida, círculo de pouso de pedra e caminho até o portão
		self:paintDisc(c.x, c.y, 88, Enum.Material.Ground)
		self:paintDisc(c.x, c.y, 26, Enum.Material.Cobblestone)
		self:paintStrip(at(0, -24), at(0, -96), 12, Enum.Material.Cobblestone)

		-- cerca de madeira em volta, com abertura no portão
		local fence = Instance.new("Model")
		fence.Name = "Fence"
		fence.Parent = m
		local N = 56
		for k = 0, N - 1 do
			local a0, a1 = k / N * math.pi * 2, (k + 1) / N * math.pi * 2
			local mid = (a0 + a1) / 2
			-- abertura de ~20 studs na frente (-Z local)
			if math.abs(((mid - math.rad(270)) + math.pi) % (2 * math.pi) - math.pi) > 0.13 then
				local q0 = at(math.cos(a0) * 90, math.sin(a0) * 90)
				local q1 = at(math.cos(a1) * 90, math.sin(a1) * 90)
				local len = (q1 - q0).Magnitude
				for _, hh in ipairs({ 1.6, 3.3 }) do
					part({ Name = "Rail", Size = Vector3.new(0.6, 0.5, len + 0.4), CFrame = CFrame.lookAt((q0 + q1) / 2 + Vector3.new(0, hh, 0), q1 + Vector3.new(0, hh, 0)), Material = Enum.Material.Wood, Color = WOODC }, fence)
				end
				part({ Name = "Post", Size = Vector3.new(1, 4.6, 1), CFrame = CFrame.new(q0 + Vector3.new(0, 1.8, 0)), Material = Enum.Material.Wood, Color = DARK }, fence)
			end
		end
		-- portão alto com placa
		for _, sx in ipairs({ -12, 12 }) do
			p({ Name = "GatePost", Size = Vector3.new(2.6, 24, 2.6), CFrame = cfAt(sx, -90) * CFrame.new(0, 12, 0), Material = Enum.Material.Wood, Color = DARK })
			local flag = p({ Name = "Banner", Size = Vector3.new(0.3, 9, 4), CFrame = cfAt(sx, -90) * CFrame.new(0, 17, -1.6) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(150, 44, 40) })
			flag.CastShadow = false
		end
		p({ Name = "GateBeam", Size = Vector3.new(30, 2.2, 2.6), CFrame = cfAt(0, -90) * CFrame.new(0, 23, 0), Material = Enum.Material.Wood, Color = WOODC })
		local sign = p({ Name = "Sign", Size = Vector3.new(20, 4, 0.5), CFrame = cfAt(0, -90) * CFrame.new(0, 19.5, -1.5), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 108, 66) })
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 30
			gui.Parent = sign
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.fromRGB(255, 240, 210)
			label.TextStrokeTransparency = 0.5
			label.Text = c.name
			label.Parent = gui
		end
		self:lantern(at(-16, -94), C, m)
		self:lantern(at(16, -94), C, m)

		-- círculo de pouso: pedras em pé e braseiros
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			if k % 3 == 0 then
				local bp = at(math.cos(a) * 30, math.sin(a) * 30)
				p({ Name = "BrazierStand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 4, 4), CFrame = CFrame.new(bp + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Basalt, Color = Color3.fromRGB(62, 58, 58) })
				local bowl = p({ Name = "Brazier", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 6, 6), CFrame = CFrame.new(bp + Vector3.new(0, 6.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 45) })
				local f = Instance.new("Fire")
				f.Size = 6
				f.Heat = 10
				f.Parent = bowl
				local pl = Instance.new("PointLight")
				pl.Color = Color3.fromRGB(255, 160, 80)
				pl.Range = 32
				pl.Brightness = 1.5
				pl.Shadows = false
				pl.Parent = bowl
			else
				p({ Name = "StandingStone", Size = Vector3.new(3.2, rng:NextNumber(7, 11), 2.4), CFrame = cfAt(math.cos(a) * 30, math.sin(a) * 30, math.deg(-a)) * CFrame.new(0, 3.5, 0) * CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), 0, math.rad(rng:NextNumber(-5, 5))), Material = Enum.Material.Slate, Color = Color3.fromRGB(104, 106, 110) })
			end
		end
		local landing = p({ Name = "LandingCircle", Size = Vector3.new(50, 1, 50), CFrame = cfAt(0, 0), Transparency = 1, CanCollide = false, CanQuery = false })
		landing:SetAttribute("DragonLanding", true)

		-- lagoa-bebedouro grande com borda de rochas, à esquerda
		do
			local wp = at(-56, 6)
			local wg = wp.Y
			Terrain:FillCylinder(CFrame.new(wp.X, wg + 2, wp.Z), 16, 23, Enum.Material.Air)
			Terrain:FillCylinder(CFrame.new(wp.X, wg - 8, wp.Z), 4, 25, Enum.Material.Slate)
			Terrain:FillCylinder(CFrame.new(wp.X, wg - 3, wp.Z), 6, 22.5, Enum.Material.Water)
			for k = 0, 21 do
				local a = k / 22 * math.pi * 2
				Terrain:FillBall(Vector3.new(wp.X + math.cos(a) * 24.5, wg - 0.5 + rng:NextNumber(-0.5, 1.2), wp.Z + math.sin(a) * 24.5), rng:NextNumber(3, 4.6), Enum.Material.Rock)
			end
			-- rochas altas atrás da lagoa (de onde cai um fio d'água)
			local back = at(-80, 14)
			Terrain:FillBall(back + Vector3.new(0, 4, 0), 11, Enum.Material.Rock)
			Terrain:FillBall(back + Vector3.new(4, 12, 6), 8, Enum.Material.Rock)
			self.Props.waterfall(back + Vector3.new(7, 15, 0), Vector3.new(back.X + 9, wg, back.Z), 6, (wp - back) * Vector3.new(1, 0, 1), m)
			local water = p({ Name = "DragonWater", Size = Vector3.new(44, 1, 44), CFrame = CFrame.new(wp), Transparency = 1, CanCollide = false, CanQuery = false })
			water:SetAttribute("DragonWater", true)
			for k = 1, 10 do
				local a = rng:NextNumber(0, math.pi * 2)
				local fp = wp + Vector3.new(math.cos(a) * 28, 0, math.sin(a) * 28)
				local hit = workspace:Raycast(fp + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), self.raySolid)
				if hit then
					self:plant("Fern", hit.Position, rng:NextNumber(0.7, 1.1), m)
				end
			end
		end

		-- área de alimentação à direita: plataforma de pedra, cochos e varais de carne
		do
			local base = cfAt(52, 4, 90)
			p({ Name = "FeedingPlatform", Size = Vector3.new(44, 1.6, 26), CFrame = base * CFrame.new(0, 0.6, 0), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(122, 118, 110) })
			for t = -1, 1 do
				local tc = base * CFrame.new(t * 14, 1.4, 0)
				p({ Name = "TroughBase", Size = Vector3.new(10, 2, 20), CFrame = tc * CFrame.new(0, 1, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(100, 100, 104) })
				p({ Name = "TroughWallL", Size = Vector3.new(1.4, 3.6, 20), CFrame = tc * CFrame.new(-4.3, 3, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(112, 112, 116) })
				p({ Name = "TroughWallR", Size = Vector3.new(1.4, 3.6, 20), CFrame = tc * CFrame.new(4.3, 3, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(112, 112, 116) })
				for k = -3, 3 do
					p({ Name = "Meat", Shape = Enum.PartType.Ball, Size = Vector3.new(4.5, 3, 5) * rng:NextNumber(0.8, 1.2), CFrame = tc * CFrame.new(rng:NextNumber(-1.5, 1.5), 3.4, k * 2.6) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(122, 46, 40), CanCollide = false })
				end
				local food = p({ Name = "DragonFood", Size = Vector3.new(10, 1, 20), CFrame = tc * CFrame.new(0, 3, 0), Transparency = 1, CanCollide = false, CanQuery = false })
				food:SetAttribute("DragonFood", true)
			end
			for _, dz in ipairs({ -22, 22 }) do
				local rc = base * CFrame.new(0, 0, dz)
				for _, sx in ipairs({ -14, 14 }) do
					p({ Name = "RackPost", Size = Vector3.new(2, 24, 2), CFrame = rc * CFrame.new(sx, 12, 0), Material = Enum.Material.Wood, Color = DARK })
				end
				p({ Name = "RackBar", Size = Vector3.new(31, 1.6, 1.6), CFrame = rc * CFrame.new(0, 23, 0), Material = Enum.Material.Wood, Color = DARK })
				for k = -5, 5, 2 do
					p({ Name = "HangingMeat", Size = Vector3.new(3, 7, 2.2), CFrame = rc * CFrame.new(k * 2.4, 18, 0) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(110, 48, 40), CanCollide = false })
				end
			end
			-- barris e caixotes de provisões
			for k = 1, 6 do
				local q = base * CFrame.new(rng:NextNumber(-20, 20), 0, 16 + rng:NextNumber(0, 6))
				p({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.8, 3.2, 3.2), CFrame = CFrame.new(q.Position.X, self:groundY(q.Position.X, -q.Position.Z) + 1.9, q.Position.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Wood, Color = Color3.fromRGB(116, 80, 48) })
			end
		end

		-- estábulo aberto para dragões no fundo: 4 baias com camas de palha
		do
			local sc = cfAt(0, 52)
			local W2, D2, H = 72, 36, 30
			p({ Name = "StableBackWall", Size = Vector3.new(W2, H, 1.6), CFrame = sc * CFrame.new(0, H / 2, D2 / 2), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(116, 84, 56) })
			for _, sx in ipairs({ -W2 / 2, W2 / 2 }) do
				p({ Name = "StableSideWall", Size = Vector3.new(1.6, H, D2), CFrame = sc * CFrame.new(sx, H / 2, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(116, 84, 56) })
			end
			for k = 0, 4 do
				local x = -W2 / 2 + k * (W2 / 4)
				p({ Name = "StablePost", Size = Vector3.new(2.6, H + 2, 2.6), CFrame = sc * CFrame.new(x, (H + 2) / 2, -D2 / 2), Material = Enum.Material.Wood, Color = DARK })
				if k > 0 and k < 4 then
					p({ Name = "StallDivider", Size = Vector3.new(1.2, 8, D2 - 4), CFrame = sc * CFrame.new(x, 4, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(128, 94, 62) })
				end
			end
			for _, sz in ipairs({ -1, 1 }) do
				local roof = Instance.new("WedgePart")
				roof.Name = "StableRoof"
				roof.Anchored = true
				roof.Size = Vector3.new(W2 + 6, 10, D2 / 2 + 4)
				roof.CFrame = sc * CFrame.new(0, H + 6, sz * (D2 / 4 + 1)) * (if sz < 0 then CFrame.Angles(0, math.rad(180), 0) else CFrame.new())
				roof.Material = Enum.Material.Fabric
				roof.Color = Color3.fromRGB(176, 146, 88)
				roof.Parent = m
			end
			for k = 0, 3 do
				local x = -W2 / 2 + (k + 0.5) * (W2 / 4)
				local bed = (sc * CFrame.new(x, 0, 2)).Position
				bed = Vector3.new(bed.X, self:groundY(bed.X, -bed.Z), bed.Z)
				if not self.Props.nest(CFrame.new(bed) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), m, 1.7, rng) then
					p({ Name = "StrawBed", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 16, 16), CFrame = CFrame.new(bed + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(214, 184, 110), CanCollide = false })
				end
				local bale = (sc * CFrame.new(x + 6, 0, D2 / 2 - 4)).Position
				p({ Name = "HayBale", Size = Vector3.new(5, 3.4, 3.4), CFrame = CFrame.new(bale.X, self:groundY(bale.X, -bale.Z) + 1.7, bale.Z) * sc.Rotation, Material = Enum.Material.Fabric, Color = Color3.fromRGB(214, 182, 96) })
			end
		end

		-- torres-poleiro nas laterais do fundo
		for _, sx in ipairs({ -64, 64 }) do
			local tc = cfAt(sx, 52)
			for _, o in ipairs({ { -6, -6 }, { 6, -6 }, { -6, 6 }, { 6, 6 } }) do
				p({ Name = "PerchLeg", Size = Vector3.new(2.2, 34, 2.2), CFrame = tc * CFrame.new(o[1], 17, o[2]), Material = Enum.Material.Wood, Color = DARK })
			end
			p({ Name = "PerchPlatform", Size = Vector3.new(18, 1.6, 18), CFrame = tc * CFrame.new(0, 34.6, 0), Material = Enum.Material.WoodPlanks, Color = WOODC })
			for _, hh in ipairs({ 10, 22 }) do
				p({ Name = "PerchBrace", Size = Vector3.new(14, 1, 1), CFrame = tc * CFrame.new(0, hh, -6), Material = Enum.Material.Wood, Color = DARK })
				p({ Name = "PerchBrace", Size = Vector3.new(14, 1, 1), CFrame = tc * CFrame.new(0, hh, 6), Material = Enum.Material.Wood, Color = DARK })
			end
			local perch = p({ Name = "Perch", Size = Vector3.new(16, 1, 16), CFrame = tc * CFrame.new(0, 35.8, 0), Transparency = 1, CanCollide = false, CanQuery = false })
			perch:SetAttribute("DragonPerch", true)
		end
		-- rocha-poleiro natural
		self:terrainRock(at(-62, -48), 4.2)

		-- cabana do tratador perto do portão, com quadro de avisos
		do
			local hc = cfAt(44, -60, 200)
			if not self.Props.house(hc * CFrame.new(0, -0.6, 0), m, rng, 18, 14, "thatch") then
				p({ Name = "Hut", Size = Vector3.new(16, 10, 12), CFrame = hc * CFrame.new(0, 5, 0), Material = Enum.Material.WoodPlanks, Color = WOODC })
			end
			self.Props.noticeBoard(cfAt(26, -70, 160), m)
			for k = 1, 4 do
				local q = at(36 + rng:NextNumber(-6, 6), -46 + rng:NextNumber(-4, 4))
				p({ Name = "Crate", Size = Vector3.new(3.4, 3.4, 3.4), CFrame = CFrame.new(q + Vector3.new(0, 1.7, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(160, 120, 76) })
			end
		end

		-- árvores em volta, do lado de fora da cerca
		for k = 1, 26 do
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(100, 135)
			local dx, dz = math.cos(a) * r, math.sin(a) * r
			if not (dz < -60 and math.abs(dx) < 40) then
				local q = (R * CFrame.new(dx, 0, dz)).Position
				local hit = self:surface(q.X, -q.Z)
				if hit and hit.Material ~= Enum.Material.Water and self:roadDist(q.X, -q.Z) > 14 then
					self:plant(if k % 3 == 0 then "Oak" else "TallPine", hit.Position, rng:NextNumber(0.8, 1.1), m)
				end
			end
		end

		-- clima da referência: fogueira com toldos e barracas, dragão descansando,
		-- píer na lagoa, estandartes com emblema, postes de lanterna e tochas
		do
			local Props = self.Props
			local fireCF = cfAt(-22, -46)
			Props.campfire(fireCF, m, 1.3)
			Props.tarp(cfAt(-6, -56, -15), 16, 12, 9, m)
			Props.tarp(cfAt(-36, -58, 20), 14, 10, 8, m)
			Props.tent(cfAt(-44, -36, 70), m, 1.1)
			Props.tent(cfAt(-48, -66, -30), m, 1)
			for k = 1, 5 do
				local q = cfAt(-10 + rng:NextNumber(-6, 6), -62 + rng:NextNumber(-3, 3), rng:NextNumber(0, 90))
				if k % 2 == 0 then
					Props.barrel(q, m)
				else
					Props.crate(q, m, rng:NextNumber(0.8, 1.1))
				end
			end
			-- o dragão do tratador, deitado perto do fogo
			self:dragonStatue(cfAt(-30, -30, 140), 14, m, true)
			-- píer entrando na lagoa
			local wp = at(-56, 6)
			local dir = (at(0, 0) - wp) * Vector3.new(1, 0, 1)
			if dir.Magnitude > 1 then
				dir = dir.Unit
				Props.pier(wp + dir * 30, wp + dir * 8, wp.Y + 0.6, 5, m)
			end
			for k = 0, 3 do
				local a = k / 4 * math.pi * 2 + 0.4
				Props.torch(CFrame.new(wp + Vector3.new(math.cos(a) * 28, 0, math.sin(a) * 28)), m)
			end
			-- estandartes e postes de lanterna no caminho do portão
			for _, o in ipairs({ { -22, -84 }, { 22, -84 }, { -36, 4 }, { 36, 4 } }) do
				Props.banner(cfAt(o[1], o[2]), m, 16)
			end
			for _, z in ipairs({ -40, -66 }) do
				for _, sx in ipairs({ -9, 9 }) do
					local q = at(sx, z)
					Props.lanternPost(CFrame.lookAt(q, at(0, z)), m)
				end
			end
		end

		m:SetAttribute("CampName", c.name)
		m:SetAttribute("DragonFood", true)
		m:SetAttribute("DragonWater", true)
		zoneMarker("SafeZone", "Safe", C, 95, m)
		m.Parent = folder
		task.wait()
	end
end

function WorldBuilder:buildWaypoints()
	self:status("waypoints")
	local folder = self:container("Waypoints", self:worldFolder())
	for i, w in ipairs(self.data.WAYPOINTS) do
		local gy = self:groundY(w.x, w.y)
		local pos = V(w.x, w.y, gy)
		local m = self.Props.obelisk(CFrame.new(pos - Vector3.new(0, 0.6, 0)), folder)
		if not m then
			m = Instance.new("Model")
			part({ Name = "Obelisk", Size = Vector3.new(5, 24, 5), CFrame = CFrame.new(pos + Vector3.new(0, 12, 0)), Material = Enum.Material.Slate, Color = Color3.fromRGB(90, 96, 104) }, m)
			part({ Name = "Rune", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(pos + Vector3.new(0, 26, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(90, 170, 255) }, m)
			m.Parent = folder
		end
		local model = m :: Model
		model.Name = string.format("Waypoint%02d", i)
		model:SetAttribute("WaypointId", i)
		model:SetAttribute("WaypointName", w.name)
		local bcf, size = model:GetBoundingBox()
		local glow = part({ Name = "Glow", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(bcf.Position + Vector3.new(0, size.Y * 0.42, 0)), Transparency = 1, CanCollide = false, CanQuery = false }, model)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(110, 180, 255)
		l.Range = 30
		l.Brightness = 2
		l.Shadows = false
		l.Parent = glow
		-- anel de pedras em volta
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			local x, y = w.x + math.cos(a) * 16, w.y + math.sin(a) * 16
			part({ Name = "RingStone", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 2, 3), CFrame = CFrame.new(V(x, y, self:groundY(x, y) + 0.4)), Material = Enum.Material.Slate, Color = Color3.fromRGB(110, 112, 118) }, model)
		end
	end
end

-- procura terra firme perto de (x, y), andando em direção ao centro do continente
function WorldBuilder:findLand(x: number, y: number): (number, number)
	for _ = 1, 40 do
		local hit = self:surface(x, y)
		if hit and hit.Material ~= Enum.Material.Water and hit.Position.Y > 2 then
			return x, y
		end
		local L = math.sqrt(x * x + y * y)
		x -= x / L * 25
		y -= y / L * 25
	end
	return x, y
end

function WorldBuilder:buildLandmarks()
	self:status("landmarks")
	local folder = self:container("Landmarks", self:worldFolder())
	local rng = self.rng
	-- Castelo dos Dragões no topo do rochedo
	local castleShape
	for _, s in ipairs(self.data.SHAPES) do
		if s.kind == "mesa" then
			castleShape = s
		end
	end
	if castleShape then
		local gy = self:groundY(castleShape.x, castleShape.y)
		local pos = V(castleShape.x, castleShape.y, gy)
		-- frente do castelo virada para a estrada em serpentina que sobe
		local rx, ry = self:roadDirection(castleShape.x, castleShape.y)
		local ccf = CFrame.lookAt(pos, pos + Vector3.new(rx, 0, -ry))
		local castle = self.Props.castle(ccf, folder, castleShape.rTop * 0.72, function(scf: CFrame, h: number)
			self:dragonStatue(scf, h, folder)
		end)
		castle:SetAttribute("Landmark", "Castelo dos Dragões")
		self:paintDisc(castleShape.x, castleShape.y, castleShape.rTop * 0.68, Enum.Material.Cobblestone)
		for k = 1, 6 do
			local a = k / 6 * math.pi * 2
			local x, y = castleShape.x + math.cos(a) * 150, castleShape.y + math.sin(a) * 150
			local hit = self:surface(x, y)
			if hit then
				local fire = part({ Name = "Brazier", Size = Vector3.new(3, 5, 3), CFrame = CFrame.new(hit.Position + Vector3.new(0, 2.5, 0)), Material = Enum.Material.Basalt, Color = Color3.fromRGB(50, 46, 46) }, folder)
				local f = Instance.new("Fire")
				f.Size = 6
				f.Color = Color3.fromRGB(255, 120, 40)
				f.Parent = fire
			end
		end
	end
	-- Farol na costa sul
	local lx, ly = self:findLand(-700, -6850)
	local lh = self.Props.lighthouse(CFrame.new(V(lx, ly, self:groundY(lx, ly) - 1)), folder)
	lh:SetAttribute("Landmark", "Farol")
	-- Cúpula das Ruínas e colunas espalhadas
	local rx, ry = 5300, 4050
	local ruins = self.Props.ruins(CFrame.new(V(rx, ry, self:groundY(rx, ry))) * CFrame.Angles(0, math.rad(30), 0), folder, rng)
	ruins.Name = "RuinsDome"
	ruins:SetAttribute("Landmark", "Cúpula das Ruínas")
	for k = 1, 26 do
		local a = rng:NextNumber(0, math.pi * 2)
		local R = rng:NextNumber(120, 650)
		local x, y = rx + math.cos(a) * R, ry + math.sin(a) * R
		local hit = self:surface(x, y)
		if hit and hit.Material ~= Enum.Material.Water then
			local h = rng:NextNumber(8, 26)
			local col = part({ Name = "RuinColumn", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 4, 4), CFrame = CFrame.new(hit.Position + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, math.rad(90) + rng:NextNumber(-0.1, 0.1)), Material = Enum.Material.Limestone, Color = Color3.fromRGB(214, 206, 186) }, folder)
			col.CastShadow = true
		end
	end
	-- Árvore-Mãe (oeste) e Árvore de Luz (Floresta Encantada)
	for _, t in ipairs({ { "Árvore-Mãe", -3200, 1300, "Oak", 6.5 }, { "Árvore de Luz", 3300, 2800, "Blossom", 5 } }) do
		local x, y = t[2], t[3]
		local hit = self:surface(x, y, true)
		if hit then
			local m = self:plant(t[4], hit.Position, t[5], folder, if t[1] == "Árvore de Luz" then LEAF.enchanted else nil)
			if m then
				m.Name = t[1]
				m:SetAttribute("Landmark", t[1])
				if t[1] == "Árvore de Luz" then
					local p = part({ Name = "Glow", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(hit.Position + Vector3.new(0, 60, 0)), Transparency = 1, CanCollide = false, CanQuery = false }, m)
					local l = Instance.new("PointLight")
					l.Range = 60
					l.Brightness = 2
					l.Color = Color3.fromRGB(210, 150, 255)
					l.Parent = p
					local sp = Instance.new("ParticleEmitter")
					sp.LightEmission = 1
					sp.Color = ColorSequence.new(Color3.fromRGB(230, 190, 255))
					sp.Size = NumberSequence.new(0.6)
					sp.Rate = 6
					sp.Lifetime = NumberRange.new(4, 7)
					sp.Speed = NumberRange.new(1, 2)
					sp.SpreadAngle = Vector2.new(180, 180)
					sp.Parent = p
				end
			end
		end
	end
	-- Pilar de Cristal (cristais grandes no pico do leste)
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		local R = if k == 0 then 0 else 40
		local x, y = 6600 + math.cos(a) * R, 300 + math.sin(a) * R
		local hit = self:surface(x, y, true)
		if hit then
			local c = self.Props.crystalCluster(CFrame.new(hit.Position - Vector3.new(0, 1, 0)) * CFrame.Angles(0, a, 0), folder, if k == 0 then 9 else 4, rng)
			if not c then
				local h = if k == 0 then 120 else 50
				part({ Name = "Crystal", Size = Vector3.new(h * 0.18, h, h * 0.18), CFrame = CFrame.new(hit.Position + Vector3.new(0, h * 0.45, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), a, math.rad(rng:NextNumber(-12, 12))), Material = Enum.Material.Glass, Color = Color3.fromRGB(120, 180, 255), Transparency = 0.15 }, folder)
			end
		end
	end
	-- Cachoeira Grande (Rio das Cachoeiras), com rochas dos lados
	do
		local G = self.data.GREAT_WATERFALL
		if G then
			local down = Vector3.new(0, 0, 1) -- o rio desce para o sul
			local top = V(G.x, G.y, G.top + 0.5)
			self.Props.waterfall(top, V(G.x, G.y - 8, G.bottom), G.width, down, folder)
			for _, sx in ipairs({ -1, 1 }) do
				for k = 0, 3 do
					Terrain:FillBall(V(G.x + sx * (G.width / 2 + 6 + k * 3), G.y + rng:NextNumber(-6, 6), G.top + 4 - k * 3), rng:NextNumber(6, 9), Enum.Material.Rock)
				end
			end
		end
	end
	-- Portão da dungeon no fundo do vale escondido (sem marcador), encostado no paredão
	-- norte, atrás de uma cachoeira que cai num lago
	local D = self.data.DUNGEON
	local floorY = self:groundY(D.x, D.y)
	local gate = Instance.new("Model")
	gate.Name = "DungeonGate"
	local origin = V(D.x, D.y, floorY + 20)
	local north = Vector3.new(0, 0, -1)
	local wallHit = workspace:Raycast(origin, north * 300, self.raySolid)
	local wallP = if wallHit then wallHit.Position else origin + north * 120
	local south = -north
	local gp = Vector3.new(wallP.X, self:groundY(wallP.X, -(wallP.Z + 10)), wallP.Z + 10)
	local gcf = CFrame.lookAt(gp, gp + south)
	-- arco de pedra escura com runas
	for _, sx in ipairs({ -13, 13 }) do
		part({ Name = "Pillar", Size = Vector3.new(7, 34, 7), CFrame = gcf * CFrame.new(sx, 17, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(72, 76, 84) }, gate)
		for k = 0, 3 do
			part({ Name = "Rune", Size = Vector3.new(1, 2.4, 0.2), CFrame = gcf * CFrame.new(sx, 8 + k * 6, -3.6), Material = Enum.Material.Neon, Color = Color3.fromRGB(150, 110, 255), CastShadow = false }, gate)
		end
	end
	part({ Name = "Lintel", Size = Vector3.new(36, 7, 8), CFrame = gcf * CFrame.new(0, 37, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(64, 68, 76) }, gate)
	local portal = part({ Name = "Portal", Size = Vector3.new(19, 33, 1), CFrame = gcf * CFrame.new(0, 16.5, 1), Material = Enum.Material.Neon, Color = Color3.fromRGB(90, 60, 200), Transparency = 0.35, CanCollide = false }, gate)
	portal:SetAttribute("DungeonEntrance", true)
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(140, 100, 255)
	pl.Range = 45
	pl.Brightness = 2
	pl.Parent = portal
	-- cachoeira caindo do alto do paredão, na frente do portão
	local rim = workspace:Raycast(Vector3.new(gp.X, 3000, wallP.Z - 25), Vector3.new(0, -3200, 0), self.raySolid)
	local rimY = if rim then rim.Position.Y else gp.Y + 120
	local fallTop = Vector3.new(gp.X, rimY - 2, wallP.Z + 4)
	self.Props.waterfall(fallTop, Vector3.new(gp.X, gp.Y, wallP.Z + 16), 34, south, gate)
	-- lago na base da cachoeira
	local pc = gp + south * 34
	Terrain:FillCylinder(CFrame.new(pc.X, pc.Y + 2, pc.Z), 12, 24, Enum.Material.Air)
	Terrain:FillCylinder(CFrame.new(pc.X, pc.Y - 7, pc.Z), 4, 26, Enum.Material.Slate)
	Terrain:FillCylinder(CFrame.new(pc.X, pc.Y - 2.5, pc.Z), 5, 23.5, Enum.Material.Water)
	for k = 0, 17 do
		local a = k / 18 * math.pi * 2
		if math.sin(a) > -0.5 then -- borda aberta do lado do portão
			Terrain:FillBall(Vector3.new(pc.X + math.cos(a) * 25, pc.Y - 0.5, pc.Z + math.sin(a) * 25), rng:NextNumber(3, 4.5), Enum.Material.Rock)
		end
	end
	-- trilha de pedras até o portão, samambaias e tochas
	for k = 0, 6 do
		local q = gp + south * (8 + k * 4) + Vector3.new(26 + rng:NextNumber(-1, 1), 0, 0)
		part({ Name = "SteppingStone", Size = Vector3.new(4, 0.8, 3.4), CFrame = CFrame.new(q.X, self:groundY(q.X, -q.Z) + 0.1, q.Z) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(100, 102, 106) }, gate)
	end
	for _, sx in ipairs({ -22, 22 }) do
		local q = gp + Vector3.new(sx, 0, 8)
		self.Props.torch(CFrame.new(q.X, self:groundY(q.X, -q.Z), q.Z), gate)
	end
	for _ = 1, 24 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(30, 70)
		local q = pc + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local hit = self:surface(q.X, -q.Z)
		if hit and hit.Material ~= Enum.Material.Water then
			self:plant(if rng:NextNumber() < 0.6 then "Fern" else "Bush", hit.Position, rng:NextNumber(0.8, 1.3), gate)
		end
	end
	gate.Parent = folder
end

--------------------------------------------------------------------------
-- Ilhas flutuantes (terreno + comida + água)
--------------------------------------------------------------------------
function WorldBuilder:writeSkyIsland(isl)
	local r = isl.r
	local cx, cy = isl.x, isl.y
	local alt = isl.alt
	local depth = r * 0.95
	local x0 = math.floor((cx - r - 12) / 4) * 4
	local y0 = math.floor((cy - r - 12) / 4) * 4
	local nx = math.ceil((2 * r + 24) / 4)
	local yMin = math.floor((alt - depth - 8) / 4) * 4
	local yMax = math.ceil((alt + 24) / 4) * 4
	local ny = (yMax - yMin) // 4
	local pondX, pondY, pondR = cx + r * 0.22, cy - r * 0.1, r * 0.2
	local waterLevel = alt + 1
	local sm, so, lo = {}, {}, {}
	local grass, rock, ground, sand = Enum.Material.Grass, Enum.Material.Rock, Enum.Material.Ground, Enum.Material.Sand
	local snowy = isl.alt > 1200
	local topMat = if snowy then Enum.Material.Snow else grass
	for kx = 1, nx do
		sm[kx], so[kx], lo[kx] = {}, {}, {}
		for ky = 1, ny do
			sm[kx][ky], so[kx][ky], lo[kx][ky] = table.create(nx, Enum.Material.Air), table.create(nx, 0), table.create(nx, 0)
		end
		for kz = 1, nx do
			local x = x0 + (kx - 0.5) * 4
			local y = y0 + nx * 4 - (kz - 0.5) * 4
			local dx, dy = x - cx, y - cy
			local edge = r * (1 + 0.14 * math.noise(dx / 60, dy / 60, isl.alt * 0.01) + 0.06 * math.noise(dx / 20, dy / 20, 3.3))
			local d = math.sqrt(dx * dx + dy * dy) / edge
			if d < 1 then
				local top = alt + 10 * (1 - d * d) + 4 * math.noise(x / 40, y / 40, 1.7)
				local pd = math.sqrt((x - pondX) ^ 2 + (y - pondY) ^ 2) / pondR
				local inPond = pd < 1
				if inPond then
					top = math.min(top, alt - 4 + 5 * pd * pd)
				end
				local bottom = alt - depth * (1 - d) ^ 0.55 * (0.75 + 0.25 * math.noise(x / 30, y / 30, 2.9)) - 6
				for ky = 1, ny do
					local yb = yMin + (ky - 1) * 4
					local occTop = math.clamp((top - yb) / 4, 0, 1)
					local occBot = math.clamp((yb + 4 - bottom) / 4, 0, 1)
					local occ = math.min(occTop, occBot)
					if occ > 0.05 then
						so[kx][ky][kz] = occ
						local dd = top - yb
						sm[kx][ky][kz] = if dd < 6 then (if inPond then sand else topMat) elseif dd < 12 then ground else rock
					end
					if inPond and yb < waterLevel and yb + 4 > top - 2 then
						lo[kx][ky][kz] = math.clamp((waterLevel - yb) / 4, 0, 1)
					end
				end
			end
		end
	end
	local region = Region3.new(Vector3.new(x0, yMin, -(y0 + nx * 4)), Vector3.new(x0 + nx * 4, yMax, -y0))
	Terrain:WriteVoxelChannels(region, 4, { SolidMaterial = sm, SolidOccupancy = so, LiquidOccupancy = lo })
	return pondX, pondY, pondR
end

function WorldBuilder:buildSkyIslands()
	self:status("sky islands")
	local folder = self:container("SkyIslands", self:worldFolder())
	local rng = self.rng
	for i, isl in ipairs(self.data.SKY_ISLANDS) do
		local px, py, pr = self:writeSkyIsland(isl)
		task.wait()
		local m = Instance.new("Model")
		m.Name = string.format("SkyIsland%02d", i)
		m:SetAttribute("IslandName", isl.name)
		m:SetAttribute("DragonFood", true)
		m:SetAttribute("DragonWater", true)
		local snowy = isl.alt > 1200
		-- árvores frutíferas, arbustos de frutas e varal de carne (comida)
		for k = 1, math.floor(isl.r / 9) do
			local a = rng:NextNumber(0, math.pi * 2)
			local R = rng:NextNumber(0.15, 0.8) * isl.r
			local x, y = isl.x + math.cos(a) * R, isl.y + math.sin(a) * R
			if math.sqrt((x - px) ^ 2 + (y - py) ^ 2) > pr + 10 then
				local hit = workspace:Raycast(Vector3.new(x, isl.alt + 200, -y), Vector3.new(0, -260, 0), self.rayWater)
				if hit and hit.Material ~= Enum.Material.Water then
					local roll = rng:NextNumber()
					local kind = if snowy then (if roll < 0.6 then "SnowPine" else "FruitBush") elseif roll < 0.45 then "FruitBush" elseif roll < 0.75 then "Oak" else "Blossom"
					self:plant(kind, hit.Position, rng:NextNumber(0.8, 1.2), m)
				end
			end
		end
		local hit = workspace:Raycast(Vector3.new(isl.x - isl.r * 0.3, isl.alt + 200, -(isl.y + isl.r * 0.2)), Vector3.new(0, -260, 0), self.raySolid)
		if hit then
			local p = hit.Position
			part({ Name = "MeatRackPostL", Size = Vector3.new(0.8, 7, 0.8), CFrame = CFrame.new(p + Vector3.new(-5, 3.5, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
			part({ Name = "MeatRackPostR", Size = Vector3.new(0.8, 7, 0.8), CFrame = CFrame.new(p + Vector3.new(5, 3.5, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
			part({ Name = "MeatRackBar", Size = Vector3.new(11, 0.6, 0.6), CFrame = CFrame.new(p + Vector3.new(0, 6.8, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
			for k = -2, 2 do
				part({ Name = "Meat", Size = Vector3.new(1.6, 3, 1), CFrame = CFrame.new(p + Vector3.new(k * 2, 5, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(170, 70, 60), CanCollide = false }, m)
			end
		end
		-- queda-d'água pela borda (só visual)
		local edgeA = math.atan2(py - isl.y, px - isl.x)
		local ex, ey = isl.x + math.cos(edgeA) * (isl.r * 0.98), isl.y + math.sin(edgeA) * (isl.r * 0.98)
		local fallH = 140
		self.Props.waterfall(V(ex, ey, isl.alt + 1), V(ex, ey, isl.alt - fallH), 9, Vector3.new(math.cos(edgeA), 0, -math.sin(edgeA)), m)
		m.Parent = folder
		task.wait()
	end
end

--------------------------------------------------------------------------
-- Florestas e rochas espalhadas por região
--------------------------------------------------------------------------
-- espaçamento da grade, limiar do agrupamento (menor = mais denso), kit, altura máxima
-- Vegetação "na medida": manchas de floresta alta com clareiras, bordas mais ralas,
-- árvores solitárias nos campos e sub-bosque de arbustos, rochas e flores.
-- limiar (maior = menos floresta), kit, altura máxima, sub-bosque
local FOREST = {
	land = { 0.15, "mixed", 420, "default" },
	meadow = { 0.3, "meadow", 420, "default" },
	forest = { -0.15, "pine", 520, "default" },
	enchanted = { -0.05, "enchanted", 520, "enchanted" },
	lakeland = { 0.25, "lake", 320, "default" },
	coast = { 0.3, "coast", 320, "default" },
	swamp = { 0.1, "swamp", 220, "swamp" },
	swampcore = { 0.15, "swamp", 220, "swamp" },
	mountain = { 0.15, "fir", 560, "default" },
	snow = { 0.25, "snow", 760, "snow" },
	volcanic = { 0.45, "volcanic", 620, "volcanic" },
	crystal = { 0.25, "crystal", 620, "crystal" },
	ruins = { 0.25, "ruins", 520, "default" },
	castle = { 0.35, "dark", 720, "dark" },
}
WorldBuilder.UNDER = UNDER

function WorldBuilder:excluded(x: number, y: number): boolean
	for _, p in ipairs(self.gen.pads) do
		local dx, dy = x - p.x, y - p.y
		local r = if p.kind == "farm" then p.r1 + 15 elseif p.kind == "hub" then p.r1 + 30 else p.r1
		if dx * dx + dy * dy < r * r then
			return true
		end
	end
	for _, s in ipairs(self.data.SHAPES) do
		if s.kind == "mesa" then
			local dx, dy = x - s.x, y - s.y
			if dx * dx + dy * dy < (s.rTop + 30) ^ 2 then
				return true
			end
		end
	end
	return self:roadDist(x, y) < 16
end

-- Planta a vegetação de um bloco de 1024 x 1024 studs (bi, bj = índices de 0 a 15)
function WorldBuilder:forestBlock(bi: number, bj: number, parent: Instance): number
	local rng = self.rng
	local half = self.data.SIZE / 2
	local x0, y0 = -half + bi * 1024, -half + bj * 1024
	local block = Instance.new("Folder")
	block.Name = string.format("F_%02d_%02d", bi, bj)
	local detail = Instance.new("Folder")
	detail.Name = "Detail" -- arbustos, flores e rochas pequenas (a ferramenta de qualidade pode esconder)
	detail.Parent = block
	local n = 0
	local gen = self.gen
	local STEP = 30
	local function put(e, x: number, y: number, small: boolean)
		local hit = self:surface(x, y)
		if hit and hit.Material ~= Enum.Material.Water and hit.Position.Y > 1 and not self:excluded(x, y) then
			if hit.Normal.Y < 0.78 and e[1] ~= "Boulder" then
				return
			end
			local m = self:plant(e[1], hit.Position, rng:NextNumber(e[3], e[4]), if small then detail else block, e[5])
			if m and m:IsA("Model") and small then
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CastShadow = false
						if e[1] == "Flowers" then
							d.CanCollide = false
						end
					end
				end
			end
			n += 1
		end
	end
	for y = y0, y0 + 1024 - 1, STEP do
		for x = x0, x0 + 1024 - 1, STEP do
			local jx = x + rng:NextNumber(0, STEP)
			local jy = y + rng:NextNumber(0, STEP)
			local t = gen.types[gen:domAt(jx, jy)]
			local cfg = FOREST[t]
			if cfg then
				local m = math.noise(jx / 650, jy / 650, 51.3) * 1.5 + math.noise(jx / 210, jy / 210, 52.9) * 0.6
				local under = UNDER[cfg[4]] or UNDER.default
				local p
				if m > cfg[1] + 0.3 then
					p = 0.62 -- miolo da mancha de floresta
				elseif m > cfg[1] then
					p = 0.25 -- borda rala
				else
					p = 0.035 -- árvores soltas no campo
				end
				local hit0 = nil
				if rng:NextNumber() < p then
					hit0 = true
					local e = self:pickAt(KITS[cfg[2]], jx, jy)
					local hit = self:surface(jx, jy)
					if hit and hit.Position.Y < cfg[3] then
						put(e, jx, jy, false)
						-- camada intermediária: árvore jovem perto das grandes no miolo da floresta
						if m > cfg[1] + 0.3 and rng:NextNumber() < 0.3 then
							local e2 = self:pick(KITS[cfg[2]])
							put({ e2[1], 1, e2[3] * 0.5, e2[4] * 0.6, e2[5] }, jx + rng:NextNumber(-12, 12), jy + rng:NextNumber(-12, 12), false)
						end
					end
				end
				-- sub-bosque: mais na borda da floresta; flores e rochas nos campos, em grupos
				local u = if m > cfg[1] + 0.3 then 0.08 elseif m > cfg[1] - 0.15 then 0.18 else 0.06
				if rng:NextNumber() < u then
					local e = self:pickAt(under, jx + 300, jy)
					local count = if e[1] == "Flowers" then rng:NextInteger(3, 6) elseif e[1] == "Boulder" then 1 else rng:NextInteger(1, 3)
					for _ = 1, count do
						local ox, oy = rng:NextNumber(-9, 9), rng:NextNumber(-9, 9)
						if hit0 then
							ox, oy = ox + 8, oy + 8
						end
						put(e, jx + ox, jy + oy, e[1] ~= "Boulder" or e[4] < 1.6)
					end
				end
			end
		end
	end
	block.Parent = parent
	return n
end

function WorldBuilder:buildForests(first: number?, last: number?)
	local world = self:worldFolder()
	local forest = world:FindFirstChild("Forest")
	if not forest or not first then
		forest = self:container("Forest", world)
	end
	local total = 0
	local k0, k1 = first or 0, last or 255
	for k = k0, k1 do
		local bi, bj = k % 16, k // 16
		local old = (forest :: Instance):FindFirstChild(string.format("F_%02d_%02d", bi, bj))
		if old then
			old:Destroy()
		end
		total += self:forestBlock(bi, bj, forest :: Instance)
		self.folder:SetAttribute("ForestProgress", k)
		self.folder:SetAttribute("ForestCount", total)
		task.wait()
	end
	return total
end

--------------------------------------------------------------------------
-- Luz, céu e água (base visual; a ferramenta de qualidade vem depois)
--------------------------------------------------------------------------
function WorldBuilder:setupLighting()
	-- Base "Ultra" (a ferramenta de qualidade do cliente reduz a partir daqui)
	Lighting.ClockTime = 16.4 -- fim de tarde dourado (alvo visual §11.1)
	Lighting.GeographicLatitude = 23
	Lighting.Brightness = 3
	Lighting.ExposureCompensation = 0.1
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ShadowSoftness = 0.12
	Lighting.OutdoorAmbient = Color3.fromRGB(118, 128, 150) -- sombras azuladas
	Lighting.Ambient = Color3.fromRGB(64, 66, 76)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 212, 160) -- sol quente
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density = 0.3
	atm.Offset = 0.25
	atm.Haze = 2.1
	atm.Glare = 1.1
	atm.Color = Color3.fromRGB(206, 214, 228)
	atm.Decay = Color3.fromRGB(150, 128, 112)
	atm.Parent = Lighting
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.9
	bloom.Size = 32
	bloom.Threshold = 1.25
	bloom.Parent = Lighting
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	rays.Intensity = 0.16
	rays.Spread = 0.8
	rays.Parent = Lighting
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.1
	cc.Contrast = 0.16
	cc.Brightness = 0.02
	cc.TintColor = Color3.fromRGB(255, 242, 222)
	cc.Parent = Lighting
	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect")
	dof.FarIntensity = 0.12
	dof.NearIntensity = 0
	dof.FocusDistance = 70
	dof.InFocusRadius = 90
	dof.Enabled = true
	dof.Parent = Lighting
	local clouds = Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.6
	clouds.Density = 0.6
	clouds.Color = Color3.fromRGB(252, 252, 255)
	clouds.Parent = Terrain
	workspace.GlobalWind = Vector3.new(7, 0, 4) -- a grama alta balança com o vento
	-- grama padrão do Roblox (a textura gerada deixava manchas claras repetidas)
	pcall(function()
		game:GetService("MaterialService"):SetBaseMaterialOverride(Enum.Material.Grass, "")
	end)
	Terrain.WaterColor = Color3.fromRGB(34, 92, 104)
	Terrain.WaterTransparency = 0.75
	Terrain.WaterReflectance = 0.7
	Terrain.WaterWaveSize = 0.15
	Terrain.WaterWaveSpeed = 9
	pcall(function()
		(Terrain :: any).Decoration = true -- grama animada (nem sempre disponível por script)
	end)
	local colors = {
		Grass = Color3.fromRGB(104, 138, 58),
		LeafyGrass = Color3.fromRGB(82, 114, 46),
		Ground = Color3.fromRGB(104, 88, 66),
		Rock = Color3.fromRGB(118, 116, 110),
		Slate = Color3.fromRGB(96, 98, 102),
		Snow = Color3.fromRGB(238, 243, 247),
		Sand = Color3.fromRGB(212, 196, 152),
		Mud = Color3.fromRGB(86, 72, 54),
		Basalt = Color3.fromRGB(54, 52, 56),
		CrackedLava = Color3.fromRGB(232, 92, 40),
		Limestone = Color3.fromRGB(206, 196, 170),
		Cobblestone = Color3.fromRGB(128, 124, 116),
		Glacier = Color3.fromRGB(170, 214, 232),
		Salt = Color3.fromRGB(226, 226, 232),
	}
	for name, color in pairs(colors) do
		pcall(function()
			Terrain:SetMaterialColor((Enum.Material :: any)[name], color)
		end)
	end
	-- streaming para o mapa de 16.000 studs
	pcall(function()
		workspace.StreamingEnabled = true
		workspace.StreamingTargetRadius = 1024
		workspace.StreamingMinRadius = 256
	end)
	workspace.FallenPartsDestroyHeight = -400
end

return WorldBuilder
