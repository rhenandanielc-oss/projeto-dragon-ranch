-- Constrói o Hub Central (vila) com as 18 fazendas em volta, separadas por bosques.
-- Executar no modo Edit. Pode ser executado de novo: recria tudo.
-- Usa os modelos de ServerStorage.WorldAssets (gerados por IA); se algum faltar, usa peças simples.
--
-- Layout:
--   * Praça central (r < 75) com chafariz, 4 NPCs e bancos; anel de calçada (75..95).
--   * 18 caminhos radiais saindo da praça; o trecho final é um "bosque decorado" com
--     árvores floridas e lanternas, terminando no arco de entrada de cada fazenda.
--   * Fazendas de 130 x 130 a 650 studs do centro, de frente para a praça.
--   * Floresta densa entre as fazendas, para ninguém ver a fazenda do vizinho.

local CHS = game:GetService("ChangeHistoryService")
local ServerStorage = game:GetService("ServerStorage")
local rec = CHS:TryBeginRecording("Construir Hub e fazendas")

-- O terreno é preenchido até TERRAIN_TOP; o Roblox desenha a superfície ~2 studs acima disso.
-- Todos os objetos usam a superfície real (GROUND).
local TERRAIN_TOP = 20
local HUB = Vector3.new(0, TERRAIN_TOP + 2, 3000) -- centro da praça, na superfície
local GROUND = HUB.Y
local FARMS = 18
local R_FARM = 650
local FARM = 130
local HALF = FARM / 2
local PLAZA_R = 75
local RING_R = 95
local OUTER_R = 960
local PATH_W = 12
local GROVE_START = 300

local Terrain = workspace.Terrain
local rng = Random.new(20261012)
local assets = ServerStorage:FindFirstChild("WorldAssets")
-- escala base de cada peça gerada (ajusta o tamanho que a IA entregou ao tamanho desejado)
local BASE_SCALE = { Pine = 2.2, Tree2 = 1.6, Arch = 1.6, QuestBoard = 1.4, Blossom = 1.1 }

--------------------------------------------------------------------------
-- Utilidades
--------------------------------------------------------------------------
local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, GROUND, v.Z)
end

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- Clona um modelo de WorldAssets, apoiado no chão em `cf`, com escala opcional.
local function placeAsset(name: string, cf: CFrame, scale: number?, parent: Instance): Model?
	local src = assets and assets:FindFirstChild(name)
	if not src then
		return nil
	end
	local m = src:Clone()
	local total = (scale or 1) * (BASE_SCALE[name] or 1)
	if total ~= 1 then
		m:ScaleTo(m:GetScale() * total)
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	-- gira e posiciona; depois desloca para a base do modelo encostar no chão em cf.Position
	m:PivotTo(CFrame.new(cf.Position) * cf.Rotation * m:GetPivot().Rotation)
	local bcf, size = m:GetBoundingBox()
	local bottomCenter = bcf.Position - Vector3.new(0, size.Y / 2, 0)
	m:PivotTo(m:GetPivot() + (cf.Position - bottomCenter))
	m.Parent = parent
	return m
end

-- Árvore simples (reserva caso o modelo gerado não exista)
local function fallbackTree(kind: string, pos: Vector3, scale: number, parent: Instance)
	local m = Instance.new("Model")
	m.Name = kind
	if kind == "Bush" then
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 4.5, 7) * scale, CFrame = CFrame.new(pos + Vector3.new(0, 1.8 * scale, 0)), Material = Enum.Material.Grass, Color = Color3.fromRGB(70, 140, 60) }, m)
		m.Parent = parent
		return
	end
	local h = (kind == "Pine" and 30 or 20) * scale
	part({ Name = "Trunk", Size = Vector3.new(2.5, h * 0.5, 2.5) * Vector3.new(scale, 1, scale), CFrame = CFrame.new(pos + Vector3.new(0, h * 0.25, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(105, 74, 48) }, m)
	if kind == "Pine" then
		for i = 0, 2 do
			local s = (12 - i * 3.5) * scale
			local wedge = part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(pos + Vector3.new(0, h * (0.45 + i * 0.18), 0)), Material = Enum.Material.Grass, Color = Color3.fromRGB(40, 92, 56) }, m)
		end
	else
		local s = 16 * scale
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(pos + Vector3.new(0, h * 0.7, 0)), Material = Enum.Material.Grass, Color = kind == "Blossom" and Color3.fromRGB(240, 170, 210) or Color3.fromRGB(76, 150, 64) }, m)
	end
	m.Parent = parent
end

-- altura real do terreno (os montes deixam o chão mais alto em alguns pontos)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { Terrain }
local function groundAt(pos: Vector3): Vector3
	local hit = workspace:Raycast(Vector3.new(pos.X, GROUND + 200, pos.Z), Vector3.new(0, -400, 0), rayParams)
	return hit and hit.Position or pos
end

local function tree(kind: string, pos: Vector3, scale: number, parent: Instance)
	pos = groundAt(pos)
	local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	if not placeAsset(kind, cf, scale, parent) then
		fallbackTree(kind, pos, scale, parent)
	end
end

local function lantern(pos: Vector3, facing: Vector3, parent: Instance)
	local cf = CFrame.lookAt(pos, Vector3.new(facing.X, pos.Y, facing.Z))
	local m = placeAsset("Lantern", cf, 1, parent)
	local lightParent: BasePart
	if m then
		lightParent = m:FindFirstChildWhichIsA("BasePart", true) :: BasePart
	else
		local post = part({ Name = "LanternPost", Size = Vector3.new(0.6, 9, 0.6), CFrame = CFrame.new(pos + Vector3.new(0, 4.5, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(50, 50, 55) }, parent)
		lightParent = part({ Name = "Lantern", Size = Vector3.new(1.4, 1.8, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, 9.2, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 196, 110) }, post)
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 120)
	light.Brightness = 1.4
	light.Range = 18
	light.Shadows = false
	light.Parent = lightParent
end

local function flowers(center: Vector3, radius: number, count: number, parent: Instance)
	local colors = { Color3.fromRGB(250, 120, 160), Color3.fromRGB(255, 220, 90), Color3.fromRGB(170, 130, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 150, 70) }
	for _ = 1, count do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0, radius)
		local p = center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		part({ Name = "Flower", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = CFrame.new(p + Vector3.new(0, 0.7, 0)), Color = colors[rng:NextInteger(1, #colors)], Material = Enum.Material.SmoothPlastic, CanCollide = false, CastShadow = false }, parent)
	end
end

--------------------------------------------------------------------------
-- Limpeza
--------------------------------------------------------------------------
for _, name in ipairs({ "Farms", "Hub" }) do
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
-- remove o chão plano provisório da área antiga de fazendas
Terrain:FillBlock(CFrame.new(965, 0, 140), Vector3.new(980, 60, 480), Enum.Material.Air)

--------------------------------------------------------------------------
-- Terreno
--------------------------------------------------------------------------
local REGION = OUTER_R * 2 + 200
Terrain:FillBlock(CFrame.new(HUB.X, TERRAIN_TOP + 60, HUB.Z), Vector3.new(REGION, 120, REGION), Enum.Material.Air)
Terrain:FillBlock(CFrame.new(HUB.X, TERRAIN_TOP - 16, HUB.Z), Vector3.new(REGION, 32, REGION), Enum.Material.Grass)
Terrain:FillBlock(CFrame.new(HUB.X, TERRAIN_TOP - 44, HUB.Z), Vector3.new(REGION, 24, REGION), Enum.Material.Rock)
task.wait()

-- colinas suaves no anel externo (escondem a borda do mapa até a Fase 6)
for i = 0, 47 do
	local a = i / 48 * math.pi * 2
	local r = OUTER_R + rng:NextNumber(10, 90)
	local p = HUB + Vector3.new(math.cos(a) * r, -rng:NextNumber(10, 30), math.sin(a) * r)
	Terrain:FillBall(p, rng:NextNumber(70, 120), Enum.Material.Grass)
end
task.wait()

-- montes baixos dentro da floresta entre as fazendas (bloqueiam a visão)
for k = 0, FARMS - 1 do
	local a = (k + 0.5) / FARMS * math.pi * 2
	for _, r in ipairs({ 380, 560, 760 }) do
		local p = HUB + Vector3.new(math.cos(a) * r, -rng:NextNumber(22, 30), math.sin(a) * r)
		Terrain:FillBall(p, rng:NextNumber(34, 46), Enum.Material.Grass)
	end
end
task.wait()

-- praça e anel de calçada
Terrain:FillCylinder(CFrame.new(HUB.X, TERRAIN_TOP - 2, HUB.Z), 4, RING_R, Enum.Material.Cobblestone)
Terrain:FillCylinder(CFrame.new(HUB.X, TERRAIN_TOP - 2, HUB.Z), 4.2, PLAZA_R - 3, Enum.Material.Pavement)

--------------------------------------------------------------------------
-- Pastas
--------------------------------------------------------------------------
local hub = Instance.new("Folder")
hub.Name = "Hub"
local farmsFolder = Instance.new("Folder")
farmsFolder.Name = "Farms"
local forest = Instance.new("Folder")
forest.Name = "Forest"
forest.Parent = hub
local decor = Instance.new("Folder")
decor.Name = "Decor"
decor.Parent = hub
-- já no workspace: cada objeto entra aos poucos (evita travar o Studio com um único bloco gigante)
hub.Parent = workspace
farmsFolder.Parent = workspace

--------------------------------------------------------------------------
-- Fazendas
--------------------------------------------------------------------------
local farmFrames = {}
for k = 0, FARMS - 1 do
	local a = k / FARMS * math.pi * 2
	local center = HUB + Vector3.new(math.cos(a) * R_FARM, 0, math.sin(a) * R_FARM)
	farmFrames[k + 1] = CFrame.lookAt(center, HUB) -- -Z aponta para a praça
end

local function inAnyFarm(p: Vector3, margin: number): boolean
	for _, f in ipairs(farmFrames) do
		local l = f:PointToObjectSpace(p)
		if math.abs(l.X) < HALF + margin and math.abs(l.Z) < HALF + margin then
			return true
		end
	end
	return false
end

-- distância lateral ao caminho mais próximo (e o raio ao longo dele)
local function pathInfo(p: Vector3): (number, number)
	local d = flat(p) - HUB
	local r = d.Magnitude
	local best = math.huge
	for _, f in ipairs(farmFrames) do
		local dir = (f.Position - HUB).Unit
		local along = d:Dot(dir)
		if along > 0 then
			local lateral = (d - dir * along).Magnitude
			best = math.min(best, lateral)
		end
	end
	return best, r
end

local WOOD = Color3.fromRGB(124, 92, 60)
local DARKWOOD = Color3.fromRGB(86, 60, 40)

local function buildFarm(index: number, F: CFrame): Model
	local model = Instance.new("Model")
	model.Name = string.format("Plot%02d", index)
	local function L(x, y, z)
		return F * CFrame.new(x, y, z)
	end
	local function W(x, z) -- ponto no chão (mundo)
		return (F * CFrame.new(x, 0, z)).Position
	end

	-- chão da fazenda
	Terrain:FillBlock(L(0, -4, 0), Vector3.new(FARM, 4, FARM), Enum.Material.LeafyGrass)
	-- caminho interno de pedras
	Terrain:FillBlock(L(0, -4, -40), Vector3.new(8, 4.2, 50), Enum.Material.Cobblestone)

	-- Base invisível com os pontos de referência
	local base = part({ Name = "Base", Size = Vector3.new(FARM, 1, FARM), CFrame = L(0, 0.5, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false }, model)
	model.PrimaryPart = base
	local function att(name: string, cf: CFrame)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Parent = base -- primeiro o pai, depois a posição
		a.WorldCFrame = cf
	end

	-- Cerca de madeira com abertura na entrada
	local fence = Instance.new("Model")
	fence.Name = "Fence"
	fence.Parent = model
	local corners = { Vector3.new(-HALF, 0, -HALF), Vector3.new(HALF, 0, -HALF), Vector3.new(HALF, 0, HALF), Vector3.new(-HALF, 0, HALF) }
	local function rail(a: Vector3, b: Vector3)
		local wa, wb = W(a.X, a.Z), W(b.X, b.Z)
		local len = (wb - wa).Magnitude
		local mid = (wa + wb) / 2
		for _, y in ipairs({ 1.4, 2.8 }) do
			part({ Name = "Rail", Size = Vector3.new(0.5, 0.45, len), CFrame = CFrame.lookAt(mid + Vector3.new(0, y, 0), wb + Vector3.new(0, y, 0)), Material = Enum.Material.Wood, Color = WOOD }, fence)
		end
		local n = math.floor(len / 8)
		for i = 0, n do
			local p = wa:Lerp(wb, i / n)
			part({ Name = "Post", Size = Vector3.new(0.9, 3.8, 0.9), CFrame = CFrame.new(p + Vector3.new(0, 1.9, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, fence)
		end
	end
	rail(corners[2], corners[3])
	rail(corners[3], corners[4])
	rail(corners[4], corners[1])
	rail(corners[1], Vector3.new(-11, 0, -HALF))
	rail(Vector3.new(11, 0, -HALF), corners[2])

	-- Arco de entrada com placa
	local archCF = L(0, 0, -HALF - 1)
	local arch = placeAsset("Arch", archCF * CFrame.Angles(0, math.rad(180), 0), 1, model)
	if not arch then
		part({ Name = "ArchPillar", Size = Vector3.new(1.6, 14, 1.6), CFrame = L(-10, 7, -HALF - 1), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
		part({ Name = "ArchPillar", Size = Vector3.new(1.6, 14, 1.6), CFrame = L(10, 7, -HALF - 1), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
		part({ Name = "ArchBeam", Size = Vector3.new(23, 1.6, 2), CFrame = L(0, 14.5, -HALF - 1), Material = Enum.Material.Wood, Color = WOOD }, model)
	end
	local sign = part({ Name = "Sign", Size = Vector3.new(11, 2.6, 0.35), CFrame = L(0, 12.5, -HALF - 3.2), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 108, 66) }, model)
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
	lantern(W(-14, -HALF - 4), F.Position, model)
	lantern(W(14, -HALF - 4), F.Position, model)

	-- Habitat do ovo: ninho de galhos e palha sobre pedras, com abrigo e calor suave
	local nestPos = W(-38, 38)
	local nest = placeAsset("Nest", CFrame.new(nestPos), 1, model)
	local nestTop = GROUND + 2.2
	if nest then
		nest.Name = "Nest"
		local _, s = nest:GetBoundingBox()
		nestTop = GROUND + s.Y * 0.55
	else
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			part({ Name = "NestStone", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 2.4, 3), CFrame = CFrame.new(nestPos + Vector3.new(math.cos(a) * 7, 1, math.sin(a) * 7)), Material = Enum.Material.Slate, Color = Color3.fromRGB(120, 124, 116) }, model)
		end
		part({ Name = "Nest", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 12, 12), CFrame = CFrame.new(nestPos + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(196, 160, 90) }, model)
	end
	-- abrigo de madeira com telhado de palha
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
	flowers(nestPos + (F.Rotation * Vector3.new(0, 0, 0)), 14, 10, model)

	-- Celeiro
	local barnCF = L(40, 0, 44) * CFrame.Angles(0, math.rad(180), 0)
	if not placeAsset("Barn", barnCF, 1, model) then
		part({ Name = "Barn", Size = Vector3.new(26, 16, 20), CFrame = barnCF * CFrame.new(0, 8, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 70, 50) }, model)
	end

	-- Cocho, bebedouro e baú
	part({ Name = "FoodTrough", Size = Vector3.new(9, 2, 3.5), CFrame = L(14, 1, 26), Material = Enum.Material.WoodPlanks, Color = WOOD }, model)
	part({ Name = "Hay", Size = Vector3.new(8, 0.6, 3), CFrame = L(14, 2.1, 26), Material = Enum.Material.Fabric, Color = Color3.fromRGB(214, 182, 96), CanCollide = false }, model)
	part({ Name = "WaterTrough", Size = Vector3.new(9, 2, 3.5), CFrame = L(26, 1, 18), Material = Enum.Material.Slate, Color = Color3.fromRGB(122, 124, 130) }, model)
	part({ Name = "Water", Size = Vector3.new(8, 0.3, 2.8), CFrame = L(26, 2.05, 18), Material = Enum.Material.Glass, Color = Color3.fromRGB(70, 150, 230), Transparency = 0.25, CanCollide = false }, model)
	part({ Name = "StorageChest", Size = Vector3.new(5, 3.4, 3.4), CFrame = L(24, 1.7, 34), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 96, 52) }, model)
	part({ Name = "ChestBand", Size = Vector3.new(5.1, 0.4, 3.5), CFrame = L(24, 2.6, 34), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 170, 80) }, model)

	-- Fardos de feno, barris e caixotes perto do celeiro
	for i, o in ipairs({ { 56, 26 }, { 58, 31 }, { 54, 30 } }) do
		part({ Name = "HayBale", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 3.6, 3.6), CFrame = L(o[1], 1.8 + (i == 3 and 3.2 or 0), o[2]) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(222, 190, 100) }, model)
	end
	for _, o in ipairs({ { 24, 46 }, { 27, 47 } }) do
		part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.6, 2.8, 2.8), CFrame = L(o[1], 1.8, o[2]) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 46) }, model)
	end
	part({ Name = "Crate", Size = Vector3.new(3, 3, 3), CFrame = L(20, 1.5, 47) * CFrame.Angles(0, 0.3, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(170, 130, 80) }, model)

	-- Área de treino: círculo de areia, bonecos e poste
	Terrain:FillCylinder(L(44, -4, -30), 4.2, 15, Enum.Material.Sand)
	part({ Name = "TrainingPost", Size = Vector3.new(2, 8, 2), CFrame = L(44, 4, -30), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
	for _, o in ipairs({ { 36, -22 }, { 52, -38 } }) do
		local dummy = Instance.new("Model")
		dummy.Name = "TrainingDummy"
		dummy.Parent = model
		part({ Name = "Stake", Size = Vector3.new(0.8, 6, 0.8), CFrame = L(o[1], 3, o[2]), Material = Enum.Material.Wood, Color = DARKWOOD }, dummy)
		part({ Name = "Body", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 2.6, 2.6), CFrame = L(o[1], 5, o[2]) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(210, 180, 120) }, dummy)
		part({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = L(o[1], 7.8, o[2]), Material = Enum.Material.Fabric, Color = Color3.fromRGB(210, 180, 120) }, dummy)
		part({ Name = "Arms", Size = Vector3.new(5, 0.6, 0.6), CFrame = L(o[1], 5.8, o[2]), Material = Enum.Material.Wood, Color = DARKWOOD }, dummy)
	end

	-- Horta (cultivo de ingredientes)
	for row = 0, 2 do
		Terrain:FillBlock(L(-44, -4, -40 + row * 8), Vector3.new(22, 4.2, 4), Enum.Material.Mud)
		for c = 0, 4 do
			part({ Name = "Crop", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.6, 1.8), CFrame = L(-52 + c * 4, 1.4, -40 + row * 8), Material = Enum.Material.Grass, Color = row == 1 and Color3.fromRGB(230, 120, 60) or Color3.fromRGB(110, 180, 70), CanCollide = false }, model)
		end
	end

	-- Lanternas, banco e árvores nos cantos
	for _, o in ipairs({ { -HALF + 4, -HALF + 4 }, { HALF - 4, -HALF + 4 }, { -HALF + 4, HALF - 4 }, { HALF - 4, HALF - 4 } }) do
		lantern(W(o[1], o[2]), F.Position, model)
	end
	part({ Name = "BenchSeat", Size = Vector3.new(6, 0.5, 1.8), CFrame = L(-14, 1.6, -48), Material = Enum.Material.WoodPlanks, Color = WOOD }, model)
	part({ Name = "BenchLeg", Size = Vector3.new(0.6, 1.6, 1.6), CFrame = L(-16.5, 0.8, -48), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
	part({ Name = "BenchLeg", Size = Vector3.new(0.6, 1.6, 1.6), CFrame = L(-11.5, 0.8, -48), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
	tree("Blossom", W(-56, 56), 0.8, model)
	tree("Oak", W(58, 58), 0.7, model)
	tree("Bush", W(-58, -50), 1, model)
	tree("Bush", W(58, -52), 1, model)
	flowers(W(-20, -30), 6, 12, model)
	flowers(W(20, -46), 5, 10, model)

	-- 8 lugares para os dragões, virados para a entrada
	local pens = { { 0, 4 }, { -22, 0 }, { 22, 0 }, { -12, 20 }, { 12, 22 }, { -22, -18 }, { 22, -16 }, { 0, -22 } }
	for i, o in ipairs(pens) do
		local p = W(o[1], o[2])
		att("Pen" .. i, CFrame.new(p) * F.Rotation)
		-- cama de palha onde o dragão descansa
		part({ Name = "StrawBed", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 9, 9), CFrame = CFrame.new(p + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(214, 184, 110), CanCollide = false, CastShadow = false }, model)
	end

	-- Laguinho com pedras e flores (fundo da fazenda)
	-- a água não substitui terreno sólido: primeiro cava, depois enche
	Terrain:FillCylinder(L(2, -5, 50), 6, 9, Enum.Material.Air)
	Terrain:FillCylinder(L(2, -5, 50), 6, 9, Enum.Material.Water)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		part({ Name = "PondStone", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 1.6, 2.2) * rng:NextNumber(0.8, 1.3), CFrame = CFrame.new(W(2 + math.cos(a) * 10, 50 + math.sin(a) * 10) + Vector3.new(0, 0.4, 0)), Material = Enum.Material.Slate, Color = Color3.fromRGB(128, 132, 124) }, model)
	end
	flowers(W(2, 50), 14, 14, model)

	-- Poço de pedra com telhadinho
	local wellPos = W(-54, 6)
	part({ Name = "WellRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 6, 6), CFrame = CFrame.new(wellPos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(140, 140, 136) }, model)
	part({ Name = "WellWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 4.6, 4.6), CFrame = CFrame.new(wellPos + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Glass, Color = Color3.fromRGB(60, 120, 200), Transparency = 0.2, CanCollide = false }, model)
	for _, s in ipairs({ -1, 1 }) do
		part({ Name = "WellPost", Size = Vector3.new(0.6, 6, 0.6), CFrame = CFrame.new(wellPos + (F.Rotation * Vector3.new(s * 2.6, 0, 0)) + Vector3.new(0, 4.5, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
	end
	part({ Name = "WellRoof", Size = Vector3.new(7, 0.5, 4.5), CFrame = CFrame.new(wellPos + Vector3.new(0, 7.6, 0)) * F.Rotation, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 70, 50) }, model)

	-- Arbustos e flores ao longo da cerca, por dentro
	for t = -HALF + 12, HALF - 12, 18 do
		for _, pos in ipairs({ W(-HALF + 4, t), W(HALF - 4, t), W(t, HALF - 4) }) do
			if rng:NextNumber() < 0.75 then
				tree("Bush", pos, rng:NextNumber(0.6, 0.9), model)
			else
				flowers(pos, 2.5, 6, model)
			end
		end
	end
	-- ponto de chegada do dono, olhando para dentro da fazenda
	att("Spawn", CFrame.new(W(0, -HALF + 10) + Vector3.new(0, 3, 0)) * F.Rotation * CFrame.Angles(0, math.rad(180), 0))

	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("OwnerUserId", 0)
	return model
end

for i, F in ipairs(farmFrames) do
	local farm = buildFarm(i, F)
	farm.Parent = farmsFolder
	task.wait()
end

--------------------------------------------------------------------------
-- Caminhos e bosques decorados
--------------------------------------------------------------------------
for _, F in ipairs(farmFrames) do
	local dir = (F.Position - HUB).Unit
	local startR, endR = RING_R - 2, R_FARM - HALF - 2
	local a = HUB + dir * startR
	local b = HUB + dir * endR
	local mid = (a + b) / 2
	Terrain:FillBlock(CFrame.lookAt(mid - Vector3.new(0, 4, 0), b - Vector3.new(0, 4, 0)), Vector3.new(PATH_W, 4.2, (b - a).Magnitude), Enum.Material.Ground)
	local side = dir:Cross(Vector3.yAxis).Unit
	-- bosque decorado: fileiras de árvores floridas e lanternas ladeando o caminho
	local r = GROVE_START
	local i = 0
	while r < endR - 6 do
		for _, s in ipairs({ -1, 1 }) do
			local p = HUB + dir * r + side * s * (PATH_W / 2 + 9 + rng:NextNumber(-1.5, 1.5))
			local kind = (i % 3 == 0) and "Blossom" or "Oak"
			tree(kind, p, kind == "Blossom" and rng:NextNumber(0.75, 0.95) or rng:NextNumber(0.6, 0.8), forest)
			if i % 2 == 1 then
				tree("Bush", HUB + dir * (r + 7) + side * s * (PATH_W / 2 + 3), rng:NextNumber(0.7, 1), forest)
			end
		end
		if i % 2 == 0 then
			local s = (i % 4 == 0) and 1 or -1
			lantern(HUB + dir * (r + 4) + side * s * (PATH_W / 2 + 2), HUB + dir * (r + 4), forest)
		end
		flowers(HUB + dir * (r + 6) + side * (PATH_W / 2 + 4), 2.5, 4, decor)
		flowers(HUB + dir * (r + 6) - side * (PATH_W / 2 + 4), 2.5, 4, decor)
		r += 16
		i += 1
	end
	task.wait()
end

--------------------------------------------------------------------------
-- Floresta entre as fazendas
--------------------------------------------------------------------------
local placed = 0
local r = 190
while r < OUTER_R + 60 do
	local step = 24
	local count = math.floor(2 * math.pi * r / step)
	for k = 0, count - 1 do
		local a = (k + rng:NextNumber(-0.35, 0.35)) / count * math.pi * 2
		local rr = r + rng:NextNumber(-7, 7)
		local p = HUB + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr)
		local lateral = pathInfo(p)
		local dense = rr > GROVE_START - 20
		local chance = dense and 0.9 or 0.12
		if lateral > PATH_W / 2 + 18 and not inAnyFarm(p, 10) and rng:NextNumber() < chance then
			local roll = rng:NextNumber()
			local kind = roll < 0.35 and "Oak" or (roll < 0.5 and "Tree2" or (roll < 0.9 and "Pine" or "Blossom"))
			local scale = kind == "Pine" and rng:NextNumber(0.8, 1.25) or rng:NextNumber(0.7, 1.1)
			tree(kind, p, scale, forest)
			placed += 1
			if dense and rng:NextNumber() < 0.35 then
				tree("Bush", p + Vector3.new(rng:NextNumber(-8, 8), 0, rng:NextNumber(-8, 8)), rng:NextNumber(0.8, 1.3), forest)
			end
			if placed % 120 == 0 then
				task.wait()
			end
		end
	end
	r += step
end

--------------------------------------------------------------------------
-- Praça central
--------------------------------------------------------------------------
local plaza = Instance.new("Folder")
plaza.Name = "Plaza"
plaza.Parent = hub
if not placeAsset("Fountain", CFrame.new(HUB), 1, plaza) then
	part({ Name = "Fountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 22, 22), CFrame = CFrame.new(HUB + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(150, 150, 150) }, plaza)
end

-- Estações dos NPCs (barraca/quadro) a 50 studs, nas diagonais
local NPC_STATIONS = {
	{ Id = "Merchant", Angle = 45, Asset = "Stall" },
	{ Id = "QuestMaster", Angle = 135, Asset = "QuestBoard" },
	{ Id = "Caretaker", Angle = 225, Asset = "Stall" },
	{ Id = "Guard", Angle = 315, Asset = nil },
}
local npcFolder = Instance.new("Folder")
npcFolder.Name = "NPCs"
npcFolder.Parent = hub
for _, st in ipairs(NPC_STATIONS) do
	local a = math.rad(st.Angle)
	local pos = HUB + Vector3.new(math.cos(a) * 52, 0, math.sin(a) * 52)
	local facing = CFrame.lookAt(pos, HUB)
	if st.Asset then
		placeAsset(st.Asset, facing * CFrame.new(0, 0, 5) * CFrame.Angles(0, math.rad(180), 0), 1, plaza)
	end
	local marker = Instance.new("Part")
	marker.Name = st.Id
	marker.Anchored = true
	marker.CanCollide = false
	marker.Transparency = 1
	marker.Size = Vector3.new(2, 1, 2)
	marker.CFrame = facing * CFrame.new(0, 0.5, -2)
	marker:SetAttribute("NpcId", st.Id)
	marker.Parent = npcFolder
end

-- bancos, canteiros e lanternas da praça
for i = 0, 7 do
	local a = (i / 8) * math.pi * 2 + math.rad(22.5)
	local p = HUB + Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30)
	local cf = CFrame.lookAt(p, HUB)
	part({ Name = "BenchSeat", Size = Vector3.new(6, 0.5, 1.8), CFrame = cf * CFrame.new(0, 1.6, 0), Material = Enum.Material.WoodPlanks, Color = WOOD }, plaza)
	part({ Name = "BenchBack", Size = Vector3.new(6, 1.6, 0.3), CFrame = cf * CFrame.new(0, 2.6, 0.9), Material = Enum.Material.WoodPlanks, Color = WOOD }, plaza)
	flowers(HUB + Vector3.new(math.cos(a + 0.35) * 38, 0, math.sin(a + 0.35) * 38), 3, 10, plaza)
end
for k = 0, FARMS - 1 do
	local a = (k + 0.5) / FARMS * math.pi * 2
	lantern(HUB + Vector3.new(math.cos(a) * (RING_R + 3), 0, math.sin(a) * (RING_R + 3)), HUB, plaza)
end

-- Ponto de nascimento padrão: na praça, antes de receber a fazenda
local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
if sp then
	sp.CFrame = CFrame.new(HUB + Vector3.new(0, 0.5, 24))
	sp.Transparency = 1
	sp.CanCollide = false
	local decal = sp:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
end

if rec then
	CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
end
return string.format("Hub construído: %d fazendas, %d árvores na floresta, %d objetos no bosque", #farmFrames, placed, #forest:GetChildren())
