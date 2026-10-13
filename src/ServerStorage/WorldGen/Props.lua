-- Construções procedurais com materiais realistas do Roblox (pedra, madeira, lona),
-- usadas no lugar dos modelos gerados por IA com cara de desenho:
-- castelo, farol, ruínas, obeliscos, postes de lanterna, toldos, barracas, píer,
-- estandartes, fogueira, caixas e barris.
-- Todas as funções recebem um CFrame apoiado no chão (Y = superfície) e um pai.

local Props = {}

local STONE = Color3.fromRGB(122, 118, 112)
local DARKSTONE = Color3.fromRGB(70, 68, 72)
local ROOF = Color3.fromRGB(52, 50, 58)
local WOOD = Color3.fromRGB(110, 80, 52)
local DARKWOOD = Color3.fromRGB(72, 52, 36)
local CANVAS = Color3.fromRGB(214, 202, 170)
local BANNER = Color3.fromRGB(32, 34, 44)

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
Props.part = part

local function wedge(props, parent)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	for k, v in pairs(props) do
		(w :: any)[k] = v
	end
	w.Parent = parent
	return w
end

local function model(name: string, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = name
	if parent then
		m.Parent = parent
	end
	return m
end

-- cilindro em pé (o eixo do cilindro do Roblox é X; giramos para Y)
local function cyl(cf: CFrame, h: number, d: number, props, parent)
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(h, d, d)
	props.CFrame = cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	return part(props, parent)
end
Props.cyl = cyl

-- cone feito de discos empilhados (telhado de torre)
function Props.cone(cf: CFrame, radius: number, height: number, parent, color: Color3?, material: Enum.Material?)
	local steps = math.clamp(math.floor(height / 2.5), 5, 14)
	for i = 0, steps - 1 do
		local t = i / steps
		local r = radius * (1 - t) + 0.4
		cyl(cf * CFrame.new(0, height * t, 0), height / steps + 0.05, r * 2, { Name = "Roof", Material = material or Enum.Material.Slate, Color = color or ROOF, CastShadow = i < steps - 2 }, parent)
	end
end

-- telhado de 4 águas (pirâmide) para planta quadrada w x d
function Props.pyramidRoof(cf: CFrame, w: number, d: number, h: number, parent, color: Color3?)
	for k = 0, 3 do
		local rot = CFrame.Angles(0, math.rad(90 * k), 0)
		local span = if k % 2 == 0 then w else d
		local depth = if k % 2 == 0 then d else w
		wedge({ Name = "Roof", Size = Vector3.new(span, h, depth / 2), CFrame = cf * rot * CFrame.new(0, h / 2, -depth / 4) * CFrame.Angles(0, math.rad(180), 0), Material = Enum.Material.Slate, Color = color or ROOF }, parent)
	end
end

-- ameias em linha entre dois pontos (topo de muralha)
function Props.merlons(a: Vector3, b: Vector3, y: number, parent, size: number?)
	local s = size or 3
	local len = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude
	local n = math.max(1, math.floor(len / (s * 2)))
	for i = 0, n - 1 do
		local p = a:Lerp(b, (i + 0.5) / n)
		part({ Name = "Merlon", Size = Vector3.new(s, s * 1.2, s * 0.9), CFrame = CFrame.lookAt(Vector3.new(p.X, y + s * 0.6, p.Z), Vector3.new(b.X, y + s * 0.6, b.Z)), Material = Enum.Material.Cobblestone, Color = STONE }, parent)
	end
end

-- muralha de pedra com caminho de ronda e ameias
function Props.wall(a: Vector3, b: Vector3, h: number, thick: number, parent)
	local base = math.min(a.Y, b.Y) - 6
	local mid = Vector3.new((a.X + b.X) / 2, base + (h + 6) / 2, (a.Z + b.Z) / 2)
	local len = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude
	local look = CFrame.lookAt(mid, Vector3.new(b.X, mid.Y, b.Z))
	part({ Name = "Wall", Size = Vector3.new(thick, h + 6, len), CFrame = look, Material = Enum.Material.Cobblestone, Color = STONE }, parent)
	part({ Name = "WallCap", Size = Vector3.new(thick + 1, 1.2, len), CFrame = look * CFrame.new(0, (h + 6) / 2, 0), Material = Enum.Material.Slate, Color = DARKSTONE }, parent)
	local top = base + h + 6
	local side = look.RightVector * (thick / 2 - 0.6)
	Props.merlons(Vector3.new(a.X, 0, a.Z) + side, Vector3.new(b.X, 0, b.Z) + side, top + 0.6, parent)
	Props.merlons(Vector3.new(a.X, 0, a.Z) - side, Vector3.new(b.X, 0, b.Z) - side, top + 0.6, parent)
end

-- torre redonda com ameias e telhado cônico
function Props.roundTower(cf: CFrame, r: number, h: number, parent, roof: boolean?)
	local m = model("Tower", parent)
	cyl(cf * CFrame.new(0, -8, 0), h + 8, r * 2, { Name = "TowerBody", Material = Enum.Material.Cobblestone, Color = STONE }, m)
	cyl(cf * CFrame.new(0, h, 0), 2.5, r * 2 + 3, { Name = "TowerLedge", Material = Enum.Material.Slate, Color = DARKSTONE }, m)
	local n = math.max(8, math.floor(r * 1.2))
	for i = 0, n - 1 do
		if i % 2 == 0 then
			local a = i / n * math.pi * 2
			part({ Name = "Merlon", Size = Vector3.new(3, 4, 2.5), CFrame = cf * CFrame.new(math.cos(a) * (r + 0.6), h + 4.5, math.sin(a) * (r + 0.6)) * CFrame.Angles(0, -a, 0), Material = Enum.Material.Cobblestone, Color = STONE }, m)
		end
	end
	-- seteiras com luz quente
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + 0.4
		for _, y in ipairs({ h * 0.45, h * 0.75 }) do
			part({ Name = "Window", Size = Vector3.new(1.4, 4, 0.6), CFrame = cf * CFrame.new(math.cos(a) * (r + 0.05), y, math.sin(a) * (r + 0.05)) * CFrame.Angles(0, -a + math.rad(90), 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 170, 90), CastShadow = false }, m)
		end
	end
	if roof ~= false then
		Props.cone(cf * CFrame.new(0, h + 2.5, 0), r + 2.5, r * 2.4, m)
	end
	return m
end

-- estandarte pendurado com emblema de dragão (desenhado com quadros da interface)
function Props.emblem(surfacePart: BasePart, face: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 1
	gui.Parent = surfacePart
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.38)
	ring.Size = UDim2.fromScale(0.62, 0.62)
	ring.SizeConstraint = Enum.SizeConstraint.RelativeXX
	ring.BackgroundTransparency = 1
	ring.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(226, 214, 186)
	stroke.Thickness = 3
	stroke.Parent = ring
	local function bar(x, y, w, h, rot)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(x, y)
		f.Size = UDim2.fromScale(w, h)
		f.Rotation = rot
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.fromRGB(226, 214, 186)
		f.Parent = ring
	end
	-- asas abertas e corpo (silhueta simples)
	bar(0.5, 0.55, 0.08, 0.55, 0)
	bar(0.3, 0.42, 0.42, 0.07, 28)
	bar(0.7, 0.42, 0.42, 0.07, -28)
	bar(0.22, 0.55, 0.3, 0.06, 55)
	bar(0.78, 0.55, 0.3, 0.06, -55)
	bar(0.5, 0.22, 0.14, 0.12, 45)
end

function Props.banner(cf: CFrame, parent, height: number?, color: Color3?)
	local m = model("Banner", parent)
	local h = height or 14
	cyl(cf, h, 0.6, { Name = "Pole", Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	part({ Name = "Crossbar", Size = Vector3.new(5.4, 0.4, 0.4), CFrame = cf * CFrame.new(0, h - 0.6, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	local cloth = part({ Name = "Cloth", Size = Vector3.new(4.8, h * 0.5, 0.15), CFrame = cf * CFrame.new(0, h - 0.8 - h * 0.25, 0.2), Material = Enum.Material.Fabric, Color = color or BANNER, CanCollide = false, CastShadow = false }, m)
	Props.emblem(cloth, Enum.NormalId.Front)
	Props.emblem(cloth, Enum.NormalId.Back)
	return m
end

-- estandarte grande pendurado numa parede/portão
function Props.wallBanner(cf: CFrame, w: number, h: number, parent)
	local cloth = part({ Name = "WallBanner", Size = Vector3.new(w, h, 0.2), CFrame = cf, Material = Enum.Material.Fabric, Color = Color3.fromRGB(110, 24, 26), CanCollide = false, CastShadow = false }, parent)
	Props.emblem(cloth, Enum.NormalId.Front)
	return cloth
end

-- poste de madeira com braço e lanterna pendurada (como na referência)
function Props.lanternPost(cf: CFrame, parent, height: number?)
	local m = model("LanternPost", parent)
	local h = height or 11
	part({ Name = "Post", Size = Vector3.new(0.9, h, 0.9), CFrame = cf * CFrame.new(0, h / 2, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	part({ Name = "Arm", Size = Vector3.new(0.5, 0.5, 3.2), CFrame = cf * CFrame.new(0, h - 0.6, -1.4), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	part({ Name = "Brace", Size = Vector3.new(0.35, 2.4, 0.35), CFrame = cf * CFrame.new(0, h - 1.6, -0.8) * CFrame.Angles(math.rad(-40), 0, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	local hang = cf * CFrame.new(0, h - 2.1, -2.7)
	part({ Name = "Chain", Size = Vector3.new(0.15, 0.9, 0.15), CFrame = hang * CFrame.new(0, 0.95, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 42), CanCollide = false }, m)
	part({ Name = "LanternCap", Size = Vector3.new(1.3, 0.35, 1.3), CFrame = hang * CFrame.new(0, 0.55, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(36, 34, 32), CanCollide = false }, m)
	local glass = part({ Name = "LanternGlass", Size = Vector3.new(0.95, 1.1, 0.95), CFrame = hang, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 176, 90), CanCollide = false, CastShadow = false }, m)
	part({ Name = "LanternBase", Size = Vector3.new(1.2, 0.3, 1.2), CFrame = hang * CFrame.new(0, -0.65, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(36, 34, 32), CanCollide = false }, m)
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 176, 100)
	l.Range = 22
	l.Brightness = 1.6
	l.Shadows = false
	l.Parent = glass
	return m
end

-- tocha fincada no chão
function Props.torch(cf: CFrame, parent)
	local m = model("Torch", parent)
	part({ Name = "Stick", Size = Vector3.new(0.5, 5, 0.5), CFrame = cf * CFrame.new(0, 2.5, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	local head = part({ Name = "Head", Size = Vector3.new(0.8, 0.9, 0.8), CFrame = cf * CFrame.new(0, 5.2, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 130, 50), CastShadow = false }, m)
	local f = Instance.new("Fire")
	f.Size = 2.2
	f.Heat = 6
	f.Parent = head
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 150, 70)
	l.Range = 16
	l.Brightness = 1.3
	l.Shadows = false
	l.Parent = head
	return m
end

-- fogueira com pedras em volta
function Props.campfire(cf: CFrame, parent, scale: number?)
	local s = scale or 1
	local m = model("Campfire", parent)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		part({ Name = "FireStone", Size = Vector3.new(1.6, 1.1, 1.3) * s, CFrame = cf * CFrame.new(math.cos(a) * 2.6 * s, 0.4 * s, math.sin(a) * 2.6 * s) * CFrame.Angles(0, -a, 0.2), Material = Enum.Material.Slate, Color = Color3.fromRGB(90, 90, 92) }, m)
	end
	for k = 0, 2 do
		part({ Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4 * s, 0.7 * s, 0.7 * s), CFrame = cf * CFrame.new(0, 0.6 * s, 0) * CFrame.Angles(0, k * math.rad(60), math.rad(12)), Material = Enum.Material.Wood, Color = Color3.fromRGB(60, 42, 30) }, m)
	end
	local core = part({ Name = "Embers", Size = Vector3.new(1.6, 0.4, 1.6) * s, CFrame = cf * CFrame.new(0, 0.5 * s, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 110, 40), CanCollide = false, CastShadow = false }, m)
	local f = Instance.new("Fire")
	f.Size = 5 * s
	f.Heat = 9
	f.Parent = core
	local smoke = Instance.new("Smoke")
	smoke.Opacity = 0.08
	smoke.RiseVelocity = 4
	smoke.Size = 4 * s
	smoke.Parent = core
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 150, 70)
	l.Range = 30 * s
	l.Brightness = 2
	l.Parent = core
	return m
end

function Props.crate(cf: CFrame, parent, s: number?)
	local k = s or 1
	local m = model("Crate", parent)
	part({ Name = "Box", Size = Vector3.new(3, 3, 3) * k, CFrame = cf * CFrame.new(0, 1.5 * k, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 112, 70) }, m)
	for _, y in ipairs({ 0.25, 2.75 }) do
		part({ Name = "Band", Size = Vector3.new(3.1, 0.3, 3.1) * k, CFrame = cf * CFrame.new(0, y * k, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	end
	return m
end

function Props.barrel(cf: CFrame, parent)
	local m = model("Barrel", parent)
	cyl(cf, 3.6, 2.8, { Name = "Body", Material = Enum.Material.Wood, Color = Color3.fromRGB(118, 80, 48) }, m)
	for _, y in ipairs({ 0.5, 3.1 }) do
		cyl(cf * CFrame.new(0, y - 0.15, 0), 0.3, 2.95, { Name = "Hoop", Material = Enum.Material.Metal, Color = Color3.fromRGB(56, 54, 52) }, m)
	end
	return m
end

-- toldo de lona inclinado sobre 4 postes
function Props.tarp(cf: CFrame, w: number, d: number, h: number, parent)
	local m = model("Tarp", parent)
	for _, o in ipairs({ { -w / 2, -d / 2, h }, { w / 2, -d / 2, h }, { -w / 2, d / 2, h * 0.7 }, { w / 2, d / 2, h * 0.7 } }) do
		part({ Name = "Pole", Size = Vector3.new(0.6, o[3], 0.6), CFrame = cf * CFrame.new(o[1], o[3] / 2, o[2]), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	end
	local slope = math.atan2(h * 0.3, d)
	part({ Name = "Canvas", Size = Vector3.new(w + 1.5, 0.2, math.sqrt(d * d + (h * 0.3) ^ 2) + 1), CFrame = cf * CFrame.new(0, h * 0.85, 0) * CFrame.Angles(-slope, 0, 0), Material = Enum.Material.Fabric, Color = CANVAS, CanCollide = false }, m)
	return m
end

-- barraca de lona em "A"
function Props.tent(cf: CFrame, parent, s: number?)
	local k = s or 1
	local m = model("Tent", parent)
	local w, d, h = 9 * k, 11 * k, 7 * k
	for _, sx in ipairs({ -1, 1 }) do
		wedge({ Name = "Canvas", Size = Vector3.new(d, h, w / 2), CFrame = cf * CFrame.new(sx * w / 4, h / 2, 0) * CFrame.Angles(0, math.rad(90 * sx), 0), Material = Enum.Material.Fabric, Color = CANVAS }, m)
	end
	part({ Name = "Ridge", Size = Vector3.new(0.4, 0.4, d + 1.5), CFrame = cf * CFrame.new(0, h + 0.1, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	for _, sz in ipairs({ -1, 1 }) do
		part({ Name = "Pole", Size = Vector3.new(0.4, h + 0.4, 0.4), CFrame = cf * CFrame.new(0, (h + 0.4) / 2, sz * (d / 2 + 0.6)), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	end
	return m
end

-- píer de madeira entre dois pontos (a -> b), na altura y
function Props.pier(a: Vector3, b: Vector3, y: number, width: number, parent)
	local m = model("Pier", parent)
	local flatA, flatB = Vector3.new(a.X, y, a.Z), Vector3.new(b.X, y, b.Z)
	local len = (flatB - flatA).Magnitude
	local look = CFrame.lookAt(flatA, flatB)
	local n = math.floor(len / 1.4)
	for i = 0, n - 1 do
		part({ Name = "Plank", Size = Vector3.new(width, 0.35, 1.25), CFrame = look * CFrame.new(0, 0, -(i + 0.5) * 1.4) * CFrame.Angles(0, math.rad((i % 3 - 1) * 1.2), 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(128 + (i % 4) * 6, 96, 64) }, m)
	end
	for i = 0, math.floor(len / 5) do
		for _, sx in ipairs({ -1, 1 }) do
			part({ Name = "Stake", Size = Vector3.new(0.7, 9, 0.7), CFrame = look * CFrame.new(sx * (width / 2 - 0.3), -3.6, -i * 5), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
		end
	end
	return m
end

-- obelisco rúnico (waypoint) em pedra, com cristal brilhante
function Props.obelisk(cf: CFrame, parent)
	local m = model("Obelisk", parent)
	part({ Name = "Plinth", Size = Vector3.new(9, 1.6, 9), CFrame = cf * CFrame.new(0, 0.4, 0), Material = Enum.Material.Slate, Color = DARKSTONE }, m)
	part({ Name = "Step", Size = Vector3.new(6.5, 1.4, 6.5), CFrame = cf * CFrame.new(0, 1.8, 0), Material = Enum.Material.Cobblestone, Color = STONE }, m)
	local y = 2.5
	for i = 0, 5 do
		local w = 3.4 - i * 0.32
		part({ Name = "Shaft", Size = Vector3.new(w, 3.2, w), CFrame = cf * CFrame.new(0, y + 1.6, 0) * CFrame.Angles(0, math.rad(i * 3), 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(88, 92, 98) }, m)
		if i % 2 == 1 then
			for k = 0, 3 do
				part({ Name = "Rune", Size = Vector3.new(0.7, 1.4, 0.1), CFrame = cf * CFrame.Angles(0, math.rad(90 * k + i * 3), 0) * CFrame.new(0, y + 1.6, -w / 2 - 0.02), Material = Enum.Material.Neon, Color = Color3.fromRGB(110, 180, 255), CastShadow = false }, m)
			end
		end
		y += 3.2
	end
	local crystal = part({ Name = "Crystal", Size = Vector3.new(1.6, 3.6, 1.6), CFrame = cf * CFrame.new(0, y + 2.2, 0) * CFrame.Angles(0, math.rad(45), math.rad(8)), Material = Enum.Material.Glass, Color = Color3.fromRGB(120, 190, 255), Transparency = 0.15, CastShadow = false }, m)
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(120, 190, 255)
	l.Range = 34
	l.Brightness = 2
	l.Parent = crystal
	return m
end

-- farol de pedra com faixas, sala da lanterna e luz giratória
function Props.lighthouse(cf: CFrame, parent)
	local m = model("Lighthouse", parent)
	cyl(cf * CFrame.new(0, -4, 0), 8, 30, { Name = "Base", Material = Enum.Material.Cobblestone, Color = STONE }, m)
	local y = 4
	for i = 0, 7 do
		local d = 18 - i * 1.1
		cyl(cf * CFrame.new(0, y, 0), 7, d, { Name = "Tower", Material = Enum.Material.Concrete, Color = if i % 2 == 0 then Color3.fromRGB(232, 228, 220) else Color3.fromRGB(150, 44, 40) }, m)
		y += 7
	end
	cyl(cf * CFrame.new(0, y, 0), 1.6, 14, { Name = "Gallery", Material = Enum.Material.Slate, Color = DARKSTONE }, m)
	local glass = cyl(cf * CFrame.new(0, y + 1.6, 0), 7, 8.5, { Name = "LanternRoom", Material = Enum.Material.Glass, Color = Color3.fromRGB(255, 236, 180), Transparency = 0.35 }, m)
	local lamp = part({ Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.new(3.5, 3.5, 3.5), CFrame = cf * CFrame.new(0, y + 5, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 236, 170), CastShadow = false }, m)
	local l = Instance.new("PointLight")
	l.Range = 60
	l.Brightness = 3
	l.Color = Color3.fromRGB(255, 230, 170)
	l.Parent = lamp
	local _ = glass
	Props.cone(cf * CFrame.new(0, y + 8.6, 0), 5.6, 6, m, Color3.fromRGB(46, 50, 56), Enum.Material.Metal)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		part({ Name = "Rail", Size = Vector3.new(0.3, 2.4, 0.3), CFrame = cf * CFrame.new(math.cos(a) * 6.6, y + 2.8, math.sin(a) * 6.6), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 42) }, m)
	end
	return m
end

-- ruínas: colunas inteiras e quebradas, arcos, piso rachado e cúpula partida
function Props.ruins(cf: CFrame, parent, rng: Random)
	local m = model("Ruins", parent)
	local LIME = Color3.fromRGB(210, 202, 182)
	part({ Name = "Floor", Size = Vector3.new(56, 1.5, 56), CFrame = cf * CFrame.new(0, -0.2, 0), Material = Enum.Material.Limestone, Color = Color3.fromRGB(190, 182, 164) }, m)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local h = if rng:NextNumber() < 0.55 then 24 else rng:NextNumber(5, 16)
		local c = cf * CFrame.new(math.cos(a) * 22, 0, math.sin(a) * 22)
		cyl(c, 1.5, 4.6, { Name = "ColumnBase", Material = Enum.Material.Limestone, Color = LIME }, m)
		cyl(c * CFrame.new(0, 1.5, 0), h, 3.4, { Name = "Column", Material = Enum.Material.Limestone, Color = LIME }, m)
		if h >= 24 then
			cyl(c * CFrame.new(0, h + 1.5, 0), 1.4, 4.6, { Name = "Capital", Material = Enum.Material.Limestone, Color = LIME }, m)
		else
			-- pedaço caído ao lado
			part({ Name = "FallenDrum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(rng:NextNumber(4, 8), 3.4, 3.4), CFrame = c * CFrame.new(rng:NextNumber(3, 6), 1.6, rng:NextNumber(-3, 3)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Material = Enum.Material.Limestone, Color = LIME }, m)
		end
	end
	-- arquitrave sobre as colunas inteiras vizinhas
	for k = 0, 11 do
		local a0, a1 = k / 12 * math.pi * 2, (k + 1) / 12 * math.pi * 2
		if k % 3 ~= 2 then
			local p0 = (cf * CFrame.new(math.cos(a0) * 22, 27.5, math.sin(a0) * 22)).Position
			local p1 = (cf * CFrame.new(math.cos(a1) * 22, 27.5, math.sin(a1) * 22)).Position
			part({ Name = "Lintel", Size = Vector3.new(3.4, 2.6, (p1 - p0).Magnitude + 2), CFrame = CFrame.lookAt((p0 + p1) / 2, p1), Material = Enum.Material.Limestone, Color = LIME }, m)
		end
	end
	-- cúpula partida (meia esfera em pedaços)
	for k = 0, 9 do
		local a = k / 10 * math.pi
		part({ Name = "DomeShard", Size = Vector3.new(10, 1.6, 14), CFrame = cf * CFrame.new(0, 30, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 4, -10) * CFrame.Angles(math.rad(35), 0, 0), Material = Enum.Material.Limestone, Color = Color3.fromRGB(196, 188, 168) }, m)
	end
	-- blocos espalhados e musgo
	for _ = 1, 14 do
		local x, z = rng:NextNumber(-34, 34), rng:NextNumber(-34, 34)
		part({ Name = "Block", Size = Vector3.new(rng:NextNumber(2, 5), rng:NextNumber(1.5, 3), rng:NextNumber(2, 5)), CFrame = cf * CFrame.new(x, 0.9, z) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 6), rng:NextNumber(-0.2, 0.2)), Material = Enum.Material.Limestone, Color = LIME }, m)
	end
	return m
end

-- Castelo dos Dragões: muralha octogonal com torres, portão, pátio e torre de menagem.
-- statue(cf, height) é chamado para colocar estátuas de dragão (opcional).
function Props.castle(cf: CFrame, parent, R: number, statue: ((CFrame, number) -> ())?)
	local m = model("DragonCastle", parent)
	local walls = model("Walls", m)
	local towers = model("Towers", m)
	local N = 8
	local corners = {}
	for k = 0, N - 1 do
		local a = (k + 0.5) / N * math.pi * 2
		table.insert(corners, cf * CFrame.new(math.cos(a) * R, 0, math.sin(a) * R))
	end
	-- -Z local = frente (portão)
	for k = 1, N do
		local a, b = corners[k], corners[k % N + 1]
		local mid = (a.Position + b.Position) / 2
		local isFront = (cf:PointToObjectSpace(mid)).Z < -R * 0.8
		if isFront then
			-- muralha com abertura do portão no meio
			local gapA = a.Position:Lerp(b.Position, 0.4)
			local gapB = a.Position:Lerp(b.Position, 0.6)
			Props.wall(a.Position, gapA, 34, 10, walls)
			Props.wall(gapB, b.Position, 34, 10, walls)
			-- portão: duas torres quadradas, arco e grade
			for _, g in ipairs({ gapA, gapB }) do
				local gcf = CFrame.lookAt(g, g + (b.Position - a.Position))
				part({ Name = "GateTower", Size = Vector3.new(16, 52, 16), CFrame = gcf * CFrame.new(0, 20, 0), Material = Enum.Material.Cobblestone, Color = STONE }, m)
				Props.pyramidRoof(gcf * CFrame.new(0, 46, 0), 19, 19, 14, m)
				if statue then
					statue(CFrame.lookAt(g + Vector3.new(0, 60, 0), g + Vector3.new(0, 60, 0) + cf.LookVector), 18)
				end
			end
			local gmid = (gapA + gapB) / 2
			local gcf = CFrame.lookAt(gmid, gmid + (b.Position - a.Position))
			part({ Name = "GateArch", Size = Vector3.new(10, 12, (gapB - gapA).Magnitude), CFrame = gcf * CFrame.new(0, 32, 0), Material = Enum.Material.Cobblestone, Color = STONE }, m)
			for i = -4, 4 do
				part({ Name = "Portcullis", Size = Vector3.new(0.6, 26, 0.6), CFrame = gcf * CFrame.new(-3, 13 + 8, i * 2.2), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 42), CanCollide = false }, m)
			end
			Props.wallBanner(gcf * CFrame.new(-5.2, 34, 0) * CFrame.Angles(0, math.rad(-90), 0), 8, 14, m)
		else
			Props.wall(a.Position, b.Position, 34, 10, walls)
		end
	end
	for k = 1, N do
		Props.roundTower(corners[k] * CFrame.new(0, -2, 0), 13, 58, towers)
	end
	-- torre de menagem (keep)
	local keep = model("Keep", m)
	local kcf = cf * CFrame.new(0, 0, R * 0.25)
	part({ Name = "KeepBody", Size = Vector3.new(64, 76, 52), CFrame = kcf * CFrame.new(0, 30, 0), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(108, 104, 100) }, keep)
	part({ Name = "KeepLedge", Size = Vector3.new(68, 2, 56), CFrame = kcf * CFrame.new(0, 68, 0), Material = Enum.Material.Slate, Color = DARKSTONE }, keep)
	Props.pyramidRoof(kcf * CFrame.new(0, 69, 0), 60, 48, 30, keep)
	for _, o in ipairs({ { -32, -26 }, { 32, -26 }, { -32, 26 }, { 32, 26 } }) do
		Props.roundTower(kcf * CFrame.new(o[1], 0, o[2]), 9, 96, keep)
	end
	-- janelas iluminadas e grande portão da torre
	for i = -2, 2 do
		for _, y in ipairs({ 30, 48 }) do
			part({ Name = "KeepWindow", Size = Vector3.new(3, 7, 0.6), CFrame = kcf * CFrame.new(i * 10, y, -26.1), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 170, 90), CastShadow = false }, keep)
		end
	end
	part({ Name = "KeepDoor", Size = Vector3.new(14, 20, 1), CFrame = kcf * CFrame.new(0, 10, -26.3), Material = Enum.Material.Wood, Color = DARKWOOD }, keep)
	Props.wallBanner(kcf * CFrame.new(-18, 46, -26.4), 9, 18, keep)
	Props.wallBanner(kcf * CFrame.new(18, 46, -26.4), 9, 18, keep)
	if statue then
		statue(kcf * CFrame.new(0, 99, 0) * CFrame.Angles(0, math.rad(180), 0), 30)
	end
	-- braseiros no pátio
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local bcf = cf * CFrame.new(math.cos(a) * R * 0.6, 0, math.sin(a) * R * 0.6 - R * 0.15)
		cyl(bcf, 5, 4, { Name = "BrazierStand", Material = Enum.Material.Basalt, Color = Color3.fromRGB(56, 52, 52) }, m)
		local bowl = cyl(bcf * CFrame.new(0, 5, 0), 1.4, 6, { Name = "Brazier", Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 45), CastShadow = false }, m)
		local f = Instance.new("Fire")
		f.Size = 7
		f.Heat = 12
		f.Parent = bowl
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 150, 70)
		l.Range = 40
		l.Brightness = 1.8
		l.Shadows = false
		l.Parent = bowl
	end
	return m
end

-- casa medieval: base de pedra, paredes claras com vigas de madeira, telhado íngreme
-- style: "thatch" (palha) | "slate" (ardósia) | "wood" (tábuas)
function Props.house(cf: CFrame, parent, rng: Random, w: number?, d: number?, style: string?)
	local m = model("House", parent)
	local W = w or rng:NextNumber(16, 22)
	local D = d or rng:NextNumber(12, 16)
	local H = rng:NextNumber(10, 13)
	local two = rng:NextNumber() < 0.35
	local wallC = ({ Color3.fromRGB(222, 212, 190), Color3.fromRGB(206, 192, 168), Color3.fromRGB(190, 178, 160) })[rng:NextInteger(1, 3)]
	local beam = Color3.fromRGB(70, 50, 36)
	local st = style or ({ "thatch", "slate", "wood" })[rng:NextInteger(1, 3)]
	part({ Name = "Foundation", Size = Vector3.new(W + 1, 3.4, D + 1), CFrame = cf * CFrame.new(0, 0.7, 0), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(120, 116, 110) }, m)
	local wallH = if two then H * 1.6 else H
	part({ Name = "Walls", Size = Vector3.new(W, wallH, D), CFrame = cf * CFrame.new(0, 2.4 + wallH / 2, 0), Material = Enum.Material.Concrete, Color = wallC }, m)
	-- vigas aparentes (enxaimel)
	for _, sz in ipairs({ -1, 1 }) do
		for i = 0, 4 do
			local x = -W / 2 + i * W / 4
			part({ Name = "Beam", Size = Vector3.new(0.7, wallH, 0.4), CFrame = cf * CFrame.new(x, 2.4 + wallH / 2, sz * (D / 2 + 0.15)), Material = Enum.Material.Wood, Color = beam }, m)
		end
		for _, y in ipairs(if two then { 2.4 + H * 0.8 } else { 2.4 + wallH - 0.4 }) do
			part({ Name = "Beam", Size = Vector3.new(W, 0.6, 0.4), CFrame = cf * CFrame.new(0, y, sz * (D / 2 + 0.15)), Material = Enum.Material.Wood, Color = beam }, m)
		end
	end
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "Beam", Size = Vector3.new(0.4, wallH, 0.7), CFrame = cf * CFrame.new(sx * (W / 2 + 0.15), 2.4 + wallH / 2, 0), Material = Enum.Material.Wood, Color = beam }, m)
	end
	-- porta e janelas com luz quente
	part({ Name = "Door", Size = Vector3.new(3.4, 6.4, 0.4), CFrame = cf * CFrame.new(0, 2.4 + 3.2, -D / 2 - 0.25), Material = Enum.Material.Wood, Color = Color3.fromRGB(84, 58, 38) }, m)
	for _, x in ipairs({ -W / 3, W / 3 }) do
		part({ Name = "Window", Size = Vector3.new(2.4, 2.6, 0.3), CFrame = cf * CFrame.new(x, 2.4 + 5, -D / 2 - 0.2), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 196, 120), CastShadow = false }, m)
		part({ Name = "Shutter", Size = Vector3.new(1.3, 2.8, 0.25), CFrame = cf * CFrame.new(x - 1.9, 2.4 + 5, -D / 2 - 0.3), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(96, 70, 48) }, m)
	end
	-- telhado de duas águas
	local roofH = D * 0.62
	local roofMat = if st == "thatch" then Enum.Material.Fabric elseif st == "slate" then Enum.Material.Slate else Enum.Material.WoodPlanks
	local roofC = if st == "thatch" then Color3.fromRGB(176, 146, 92) elseif st == "slate" then Color3.fromRGB(64, 66, 74) else Color3.fromRGB(110, 74, 52)
	local ry = 2.4 + wallH
	for _, sz in ipairs({ -1, 1 }) do
		wedge({ Name = "Roof", Size = Vector3.new(W + 2.4, roofH, D / 2 + 1.4), CFrame = cf * CFrame.new(0, ry + roofH / 2, sz * (D / 4 + 0.7)) * (if sz < 0 then CFrame.Angles(0, math.rad(180), 0) else CFrame.new()), Material = roofMat, Color = roofC }, m)
	end
	-- empena fechada
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			wedge({ Name = "Gable", Size = Vector3.new(0.6, roofH - 0.4, D / 2), CFrame = cf * CFrame.new(sx * (W / 2 - 0.3), ry + (roofH - 0.4) / 2, sz * D / 4) * (if sz < 0 then CFrame.Angles(0, math.rad(180), 0) else CFrame.new()), Material = Enum.Material.Concrete, Color = wallC }, m)
		end
	end
	-- chaminé
	if rng:NextNumber() < 0.7 then
		local cx = W / 2 - 2.5
		part({ Name = "Chimney", Size = Vector3.new(2.6, roofH + 4, 2.6), CFrame = cf * CFrame.new(cx, ry + (roofH + 4) / 2 - 1, D / 4), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(110, 104, 98) }, m)
	end
	return m
end

-- celeiro de madeira com portão grande
function Props.barn(cf: CFrame, parent, s: number?)
	local k = s or 1
	local m = model("Barn", parent)
	local W, D, H = 26 * k, 20 * k, 14 * k
	part({ Name = "Foundation", Size = Vector3.new(W + 1, 2, D + 1), CFrame = cf * CFrame.new(0, 0.4, 0), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(116, 112, 106) }, m)
	part({ Name = "Walls", Size = Vector3.new(W, H, D), CFrame = cf * CFrame.new(0, 1.4 + H / 2, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(128, 58, 44) }, m)
	part({ Name = "Door", Size = Vector3.new(9 * k, 10 * k, 0.5), CFrame = cf * CFrame.new(0, 1.4 + 5 * k, -D / 2 - 0.3), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(96, 46, 36) }, m)
	for _, rot in ipairs({ 40, -40 }) do
		part({ Name = "DoorBrace", Size = Vector3.new(0.6, 12 * k, 0.3), CFrame = cf * CFrame.new(0, 1.4 + 5 * k, -D / 2 - 0.6) * CFrame.Angles(0, 0, math.rad(rot)), Material = Enum.Material.Wood, Color = Color3.fromRGB(226, 216, 196) }, m)
	end
	local roofH = D * 0.55
	for _, sz in ipairs({ -1, 1 }) do
		wedge({ Name = "Roof", Size = Vector3.new(W + 2, roofH, D / 2 + 1.2), CFrame = cf * CFrame.new(0, 1.4 + H + roofH / 2, sz * (D / 4 + 0.6)) * (if sz < 0 then CFrame.Angles(0, math.rad(180), 0) else CFrame.new()), Material = Enum.Material.Slate, Color = Color3.fromRGB(62, 64, 70) }, m)
		wedge({ Name = "Gable", Size = Vector3.new(W - 0.4, roofH - 0.3, D / 2), CFrame = cf * CFrame.new(0, 1.4 + H + (roofH - 0.3) / 2, sz * D / 4) * (if sz < 0 then CFrame.Angles(0, math.rad(180), 0) else CFrame.new()), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(128, 58, 44) }, m)
	end
	return m
end

-- barraca de mercado com toldo listrado e mercadorias
function Props.stall(cf: CFrame, parent, rng: Random)
	local m = model("Stall", parent)
	local colors = { Color3.fromRGB(160, 48, 44), Color3.fromRGB(44, 86, 140), Color3.fromRGB(196, 150, 60), Color3.fromRGB(60, 110, 70) }
	local c = colors[rng:NextInteger(1, #colors)]
	part({ Name = "Counter", Size = Vector3.new(10, 3.4, 4), CFrame = cf * CFrame.new(0, 1.7, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(130, 96, 62) }, m)
	for _, o in ipairs({ { -4.8, -1.8 }, { 4.8, -1.8 }, { -4.8, 1.8 }, { 4.8, 1.8 } }) do
		part({ Name = "Pole", Size = Vector3.new(0.5, 9, 0.5), CFrame = cf * CFrame.new(o[1], 4.5, o[2]), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	end
	for i = 0, 4 do
		part({ Name = "Awning", Size = Vector3.new(2.2, 0.2, 6.4), CFrame = cf * CFrame.new(-4.4 + i * 2.2, 8.6, -0.6) * CFrame.Angles(math.rad(-14), 0, 0), Material = Enum.Material.Fabric, Color = if i % 2 == 0 then c else Color3.fromRGB(230, 222, 200), CanCollide = false }, m)
	end
	for i = -2, 2 do
		local goods = { Color3.fromRGB(200, 60, 50), Color3.fromRGB(230, 170, 60), Color3.fromRGB(110, 160, 70), Color3.fromRGB(140, 90, 160) }
		part({ Name = "Goods", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = cf * CFrame.new(i * 1.8, 4, -0.8), Material = Enum.Material.SmoothPlastic, Color = goods[rng:NextInteger(1, #goods)] }, m)
	end
	return m
end

-- poço de pedra com telhadinho
function Props.well(cf: CFrame, parent)
	local m = model("Well", parent)
	cyl(cf, 3.2, 7, { Name = "Ring", Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(128, 124, 118) }, m)
	cyl(cf * CFrame.new(0, 2.6, 0), 0.4, 5.6, { Name = "Water", Material = Enum.Material.Glass, Color = Color3.fromRGB(40, 90, 110), Transparency = 0.2 }, m)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "Post", Size = Vector3.new(0.6, 7, 0.6), CFrame = cf * CFrame.new(sx * 3.1, 3.5, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	end
	for _, sz in ipairs({ -1, 1 }) do
		wedge({ Name = "Roof", Size = Vector3.new(8, 1.8, 2.6), CFrame = cf * CFrame.new(0, 7.6, sz * 1.3) * (if sz < 0 then CFrame.Angles(0, math.rad(180), 0) else CFrame.new()), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(110, 74, 52) }, m)
	end
	return m
end

-- chafariz de pedra em degraus (a água é feita com terreno pelo construtor)
function Props.fountain(cf: CFrame, parent)
	local m = model("Fountain", parent)
	cyl(cf * CFrame.new(0, -0.5, 0), 2.6, 30, { Name = "Basin", Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(150, 146, 138) }, m)
	cyl(cf * CFrame.new(0, 2.1, 0), 0.4, 27, { Name = "Water", Material = Enum.Material.Glass, Color = Color3.fromRGB(60, 130, 150), Transparency = 0.35, CanCollide = false }, m)
	cyl(cf, 6, 5, { Name = "Pillar", Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(140, 136, 128) }, m)
	cyl(cf * CFrame.new(0, 6, 0), 1.2, 12, { Name = "UpperBowl", Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(150, 146, 138) }, m)
	local spout = cyl(cf * CFrame.new(0, 7.2, 0), 2, 1.4, { Name = "Spout", Material = Enum.Material.Slate, Color = DARKSTONE }, m)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	pe.Size = NumberSequence.new(0.5, 0.2)
	pe.Transparency = NumberSequence.new(0.3, 1)
	pe.Rate = 40
	pe.Lifetime = NumberRange.new(0.8, 1.2)
	pe.Speed = NumberRange.new(8, 10)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.Acceleration = Vector3.new(0, -30, 0)
	pe.Parent = spout
	return m
end

-- queda-d'água: lâmina translúcida com água "correndo" (partículas) e névoa embaixo.
-- top e bottom são pontos do mundo; facing é a direção para onde a água cai (para fora do paredão)
function Props.waterfall(top: Vector3, bottom: Vector3, width: number, facing: Vector3, parent)
	local m = model("Waterfall", parent)
	local h = top.Y - bottom.Y
	if h < 2 then
		return m
	end
	local flat = Vector3.new(facing.X, 0, facing.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	flat = flat.Unit
	local mid = Vector3.new(top.X, (top.Y + bottom.Y) / 2, top.Z) + flat * 1.5
	local cf = CFrame.lookAt(mid, mid + flat)
	local sheet = part({ Name = "Sheet", Size = Vector3.new(width, h, 0.6), CFrame = cf, Material = Enum.Material.Glass, Color = Color3.fromRGB(196, 228, 240), Transparency = 0.45, CanCollide = false, CanQuery = false, CastShadow = false }, m)
	local sheet2 = part({ Name = "SheetFront", Size = Vector3.new(width * 0.8, h, 0.3), CFrame = cf * CFrame.new(0, 0, -0.9), Material = Enum.Material.Glass, Color = Color3.fromRGB(230, 244, 250), Transparency = 0.7, CanCollide = false, CanQuery = false, CastShadow = false }, m)
	local _ = sheet2
	-- emissor no topo: faixas brancas descendo
	local emitTop = part({ Name = "FlowEmitter", Size = Vector3.new(width, 0.5, 1), CFrame = cf * CFrame.new(0, h / 2, -0.6), Transparency = 1, CanCollide = false, CanQuery = false }, m)
	local flow = Instance.new("ParticleEmitter")
	flow.Texture = "rbxasset://textures/particles/smoke_main.dds"
	flow.Color = ColorSequence.new(Color3.fromRGB(240, 250, 255))
	flow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.85, 0.65), NumberSequenceKeypoint.new(1, 1) })
	flow.Size = NumberSequence.new(math.clamp(width * 0.35, 2, 10))
	flow.Rate = math.clamp(width * 6, 20, 140)
	flow.EmissionDirection = Enum.NormalId.Bottom
	flow.Speed = NumberRange.new(14, 20)
	flow.Acceleration = Vector3.new(0, -60, 0)
	flow.Lifetime = NumberRange.new(math.sqrt(2 * h / 60) * 0.9, math.sqrt(2 * h / 60) * 1.05)
	flow.SpreadAngle = Vector2.new(4, 4)
	flow.LightInfluence = 1
	flow.Parent = emitTop
	-- névoa e espuma na base
	local base = part({ Name = "MistEmitter", Size = Vector3.new(width, 0.5, width * 0.6), CFrame = CFrame.new(Vector3.new(bottom.X, bottom.Y + 1, bottom.Z) + flat * 3), Transparency = 1, CanCollide = false, CanQuery = false }, m)
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(236, 246, 255))
	mist.Transparency = NumberSequence.new(0.55, 1)
	mist.Size = NumberSequence.new(math.clamp(width * 0.4, 3, 14), math.clamp(width * 0.8, 6, 26))
	mist.Rate = math.clamp(width * 1.5, 6, 40)
	mist.Lifetime = NumberRange.new(2, 3.5)
	mist.Speed = NumberRange.new(3, 7)
	mist.SpreadAngle = Vector2.new(60, 60)
	mist.EmissionDirection = Enum.NormalId.Top
	mist.LightInfluence = 1
	mist.Parent = base
	local foam = part({ Name = "Foam", Size = Vector3.new(width * 1.2, 0.3, width * 0.5), CFrame = CFrame.new(Vector3.new(bottom.X, bottom.Y + 0.2, bottom.Z) + flat * 2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 248, 252), Transparency = 0.35, CanCollide = false, CanQuery = false, CastShadow = false }, m)
	local _2 = foam
	return m
end

-- mirante de madeira na beira do penhasco, com corrimão, banco e luneta
function Props.lookout(cf: CFrame, parent, groundAt: (Vector3) -> number)
	local m = model("Lookout", parent)
	local deckY = cf.Position.Y + 3
	local W, D = 18, 14
	for _, o in ipairs({ { -W / 2 + 1, -D / 2 + 1 }, { W / 2 - 1, -D / 2 + 1 }, { -W / 2 + 1, D / 2 - 1 }, { W / 2 - 1, D / 2 - 1 } }) do
		local p = (cf * CFrame.new(o[1], 0, o[2])).Position
		local g = groundAt(p)
		local h = deckY - g + 2
		part({ Name = "Post", Size = Vector3.new(1.2, h, 1.2), CFrame = CFrame.new(p.X, g - 2 + h / 2, p.Z), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	end
	local deck = CFrame.new(cf.Position.X, deckY, cf.Position.Z) * cf.Rotation
	for i = 0, 11 do
		part({ Name = "Plank", Size = Vector3.new(W, 0.4, D / 12 - 0.08), CFrame = deck * CFrame.new(0, 0, -D / 2 + (i + 0.5) * D / 12), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(126 + (i % 3) * 6, 92, 60) }, m)
	end
	-- corrimão em 3 lados (a frente -Z é o lado da vista)
	local rails = { { Vector3.new(-W / 2, 0, -D / 2), Vector3.new(W / 2, 0, -D / 2) }, { Vector3.new(-W / 2, 0, -D / 2), Vector3.new(-W / 2, 0, D / 2) }, { Vector3.new(W / 2, 0, -D / 2), Vector3.new(W / 2, 0, D / 2) } }
	for _, r in ipairs(rails) do
		local a, b = (deck * CFrame.new(r[1])).Position, (deck * CFrame.new(r[2])).Position
		part({ Name = "Rail", Size = Vector3.new(0.4, 0.4, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 3.6, 0), b + Vector3.new(0, 3.6, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
		for k = 0, 4 do
			local q = a:Lerp(b, k / 4)
			part({ Name = "Baluster", Size = Vector3.new(0.4, 3.6, 0.4), CFrame = CFrame.new(q + Vector3.new(0, 1.8, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
		end
	end
	part({ Name = "Bench", Size = Vector3.new(7, 0.5, 2), CFrame = deck * CFrame.new(0, 1.6, 4), Material = Enum.Material.WoodPlanks, Color = WOOD }, m)
	local tri = deck * CFrame.new(5, 0, -4)
	for k = 0, 2 do
		part({ Name = "TelescopeLeg", Size = Vector3.new(0.25, 4, 0.25), CFrame = tri * CFrame.Angles(0, k * math.rad(120), 0) * CFrame.new(0, 2, 0.6) * CFrame.Angles(math.rad(-12), 0, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	end
	part({ Name = "Telescope", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.4, 0.7, 0.7), CFrame = tri * CFrame.new(0, 4.2, 0) * CFrame.Angles(0, math.rad(90), math.rad(12)), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 120, 60) }, m)
	return m
end

-- ninho de galhos e palha sobre pedras (habitat do ovo / cama de dragão)
function Props.nest(cf: CFrame, parent, s: number, rng: Random)
	local m = model("Nest", parent)
	local r = 5.5 * s
	cyl(cf * CFrame.new(0, 0.1, 0), 0.9 * s, r * 2, { Name = "Straw", Material = Enum.Material.Fabric, Color = Color3.fromRGB(206, 176, 104) }, m)
	for k = 0, 17 do
		local a = k / 18 * math.pi * 2
		part({ Name = "Twig", Shape = Enum.PartType.Cylinder, Size = Vector3.new(r * 0.9, 0.55 * s, 0.55 * s), CFrame = cf * CFrame.new(math.cos(a) * r, 1 * s, math.sin(a) * r) * CFrame.Angles(0, -a + math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-25, 25))), Material = Enum.Material.Wood, Color = Color3.fromRGB(96 + rng:NextInteger(-12, 12), 70, 46) }, m)
	end
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2 + 0.2
		part({ Name = "NestStone", Size = Vector3.new(2.2, 1.6, 1.8) * s * rng:NextNumber(0.8, 1.2), CFrame = cf * CFrame.new(math.cos(a) * (r + 1.6 * s), 0.5 * s, math.sin(a) * (r + 1.6 * s)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(108, 110, 106) }, m)
	end
	return m
end

-- quadro de avisos de madeira
function Props.noticeBoard(cf: CFrame, parent)
	local m = model("NoticeBoard", parent)
	for _, sx in ipairs({ -3.4, 3.4 }) do
		part({ Name = "Post", Size = Vector3.new(0.7, 8, 0.7), CFrame = cf * CFrame.new(sx, 4, 0), Material = Enum.Material.Wood, Color = DARKWOOD }, m)
	end
	part({ Name = "Board", Size = Vector3.new(7, 4.4, 0.4), CFrame = cf * CFrame.new(0, 5, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(130, 94, 60) }, m)
	for _, sz in ipairs({ -1, 1 }) do
		wedge({ Name = "Roof", Size = Vector3.new(8.4, 1.2, 1.3), CFrame = cf * CFrame.new(0, 8.2, sz * 0.65) * (if sz < 0 then CFrame.Angles(0, math.rad(180), 0) else CFrame.new()), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(100, 68, 48) }, m)
	end
	for i = 0, 4 do
		part({ Name = "Paper", Size = Vector3.new(1.2, 1.5, 0.05), CFrame = cf * CFrame.new(-2.6 + i * 1.3, 5 + (i % 2) * 0.8 - 0.4, -0.24) * CFrame.Angles(0, 0, math.rad((i % 3 - 1) * 6)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(232, 222, 196), CastShadow = false }, m)
	end
	return m
end

-- aglomerado de cristais mágicos (prismas de vidro com brilho)
function Props.crystalCluster(cf: CFrame, parent, s: number, rng: Random)
	local m = model("Crystal", parent)
	local n = rng:NextInteger(4, 8)
	local hue = if rng:NextNumber() < 0.7 then Color3.fromRGB(120, 190, 255) else Color3.fromRGB(180, 130, 255)
	for i = 1, n do
		local h = (if i == 1 then 9 else rng:NextNumber(3, 7)) * s
		local w = h * rng:NextNumber(0.18, 0.28)
		local a = rng:NextNumber(0, math.pi * 2)
		local r = if i == 1 then 0 else rng:NextNumber(0.8, 2.4) * s
		local tilt = if i == 1 then 0 else rng:NextNumber(0.25, 0.6)
		local base = cf * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r) * CFrame.Angles(0, a, 0) * CFrame.Angles(tilt, 0, 0)
		part({ Name = "Prism", Size = Vector3.new(w, h, w), CFrame = base * CFrame.new(0, h / 2 - 0.4, 0) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Glass, Color = hue, Transparency = 0.2, CastShadow = false }, m)
		wedge({ Name = "Tip", Size = Vector3.new(w, w * 1.2, w), CFrame = base * CFrame.new(0, h - 0.4 + w * 0.6, 0) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Glass, Color = hue, Transparency = 0.2, CastShadow = false }, m)
	end
	local glow = part({ Name = "Glow", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, 3 * s, 0), Transparency = 1, CanCollide = false, CanQuery = false }, m)
	local l = Instance.new("PointLight")
	l.Color = hue
	l.Range = 14 * s
	l.Brightness = 1.2
	l.Shadows = false
	l.Parent = glow
	return m
end

-- árvore morta retorcida (tronco afinando e galhos secos)
function Props.deadTree(cf: CFrame, parent, s: number, rng: Random)
	local m = model("DeadTree", parent)
	local bark = Color3.fromRGB(58, 48, 42)
	local h = 26 * s
	local lean = CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.08, 0.08))
	local seg = 4
	local top = cf * lean
	for i = 0, seg - 1 do
		local d = (2.6 - i * 0.5) * s
		local sh = h / seg
		part({ Name = "Trunk", Size = Vector3.new(d, sh + 0.6, d), CFrame = top * CFrame.new(0, sh / 2, 0), Material = Enum.Material.Wood, Color = bark }, m)
		top = top * CFrame.new(0, sh, 0) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12))
		if i >= 1 then
			for _ = 1, 2 do
				local a = rng:NextNumber(0, math.pi * 2)
				local len = rng:NextNumber(5, 10) * s
				local bcf = top * CFrame.new(0, -sh * 0.3, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(40, 70)))
				part({ Name = "Branch", Size = Vector3.new(0.7 * s, len, 0.7 * s), CFrame = bcf * CFrame.new(0, len / 2, 0), Material = Enum.Material.Wood, Color = bark }, m)
			end
		end
	end
	return m
end

return Props
