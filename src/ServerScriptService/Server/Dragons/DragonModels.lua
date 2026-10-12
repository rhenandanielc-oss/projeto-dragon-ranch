--!strict
-- Modelos dos dragões.
-- 1. Se existir um modelo gerado em ServerStorage.DragonAssets.<Espécie>.<Egg|Baby|Adult>, ele é usado.
--    Jovem, Pré-adulto e Ancião usam o modelo Adulto em escala menor/maior.
-- 2. Senão, usa o modelo PROVISÓRIO de peças simples (silhueta de cada espécie, DRAGON-VISUAL-DESIGN.md §11).
-- Coordenadas em escala Adulto; o chão fica em y = 0 relativo à peça Root.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Elements = require(ReplicatedStorage.Shared.Config.Elements)
local Species = require(ReplicatedStorage.Shared.Config.Species)
local Rarity = require(ReplicatedStorage.Shared.Config.Rarity)
local Growth = require(ReplicatedStorage.Shared.Config.Growth)

local DragonModels = {}

type Spec = { kind: string, size: Vector3, cf: CFrame, color: string, head: boolean? }

-- Escala por estágio e aumento extra da cabeça (filhotes têm cabeça grande).
local STAGE_SCALE = { Baby = 0.32, Young = 0.62, Subadult = 0.8, Adult = 1.0, Elder = 1.1 }
local STAGE_HEAD = { Baby = 1.55, Young = 1.2, Subadult = 1.05, Adult = 1.0, Elder = 1.0 }

local function rod(a: Vector3, b: Vector3, d: number, color: string, head: boolean?): Spec
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	return { kind = "Cylinder", size = Vector3.new(len, d, d), cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0), color = color, head = head }
end

local function ball(p: Vector3, s: Vector3, color: string, head: boolean?): Spec
	return { kind = "Ball", size = s, cf = CFrame.new(p), color = color, head = head }
end

local function block(p: Vector3, s: Vector3, color: string, rot: CFrame?, head: boolean?): Spec
	return { kind = "Block", size = s, cf = CFrame.new(p) * (rot or CFrame.identity), color = color, head = head }
end

local function wing(side: number, shoulder: Vector3, span: number, chord: number, lift: number, color: string): { Spec }
	local tip = shoulder + Vector3.new(side * span, lift, 1)
	local specs = {
		rod(shoulder, tip, 0.7, "main"),
		block((shoulder + tip) / 2 + Vector3.new(0, -chord * 0.3, chord * 0.35), Vector3.new(span, 0.25, chord), color, CFrame.Angles(0, 0, math.atan2(lift, side * span)) * CFrame.Angles(math.rad(-15), 0, 0)),
	}
	return specs
end

local function head(p: Vector3, scale: number, horns: boolean, extra: { Spec })
	local s = scale
	table.insert(extra, block(p, Vector3.new(3 * s, 2.6 * s, 4 * s), "main", nil, true))
	table.insert(extra, block(p + Vector3.new(0, -0.5 * s, -2.8 * s), Vector3.new(2.2 * s, 1.6 * s, 2.4 * s), "main", nil, true))
	table.insert(extra, ball(p + Vector3.new(1.15 * s, 0.6 * s, -1.2 * s), Vector3.new(0.8, 0.8, 0.8) * s, "eye", true))
	table.insert(extra, ball(p + Vector3.new(-1.15 * s, 0.6 * s, -1.2 * s), Vector3.new(0.8, 0.8, 0.8) * s, "eye", true))
	if horns then
		table.insert(extra, rod(p + Vector3.new(0.9 * s, 1.1 * s, 0.6 * s), p + Vector3.new(1.3 * s, 2.6 * s, 2.8 * s), 0.5 * s, "horn", true))
		table.insert(extra, rod(p + Vector3.new(-0.9 * s, 1.1 * s, 0.6 * s), p + Vector3.new(-1.3 * s, 2.6 * s, 2.8 * s), 0.5 * s, "horn", true))
	end
end

local function tail(start: Vector3, dir: Vector3, count: number, d0: number, step: number, sway: number): { Spec }
	local specs = {}
	for i = 0, count - 1 do
		local t = i / math.max(1, count - 1)
		local d = d0 * (1 - t * 0.75)
		local p = start + dir * (i * step) + Vector3.new(math.sin(i * 0.8) * sway, -t * 1.2, 0)
		table.insert(specs, ball(p, Vector3.new(d, d, d * 1.3), "main"))
	end
	return specs
end

local BUILDERS: { [string]: () -> { Spec } } = {}

BUILDERS.WesternDragon = function()
	local s: { Spec } = {
		ball(Vector3.new(0, 6.2, 0), Vector3.new(7.5, 6.5, 12), "main"),
		ball(Vector3.new(0, 5.2, -0.5), Vector3.new(6, 4.6, 10), "belly"),
		ball(Vector3.new(0, 8.6, -6.4), Vector3.new(3, 3, 3.4), "main"),
		ball(Vector3.new(0, 10.4, -8), Vector3.new(2.6, 2.6, 3), "main"),
	}
	for _, x in ipairs({ -2.8, 2.8 }) do
		table.insert(s, rod(Vector3.new(x, 5, -3.6), Vector3.new(x * 1.08, 0.7, -4.2), 1.7, "main"))
		table.insert(s, rod(Vector3.new(x, 5, 3.6), Vector3.new(x * 1.08, 0.7, 4.2), 1.9, "main"))
		table.insert(s, ball(Vector3.new(x * 1.08, 0.6, -4.5), Vector3.new(2, 1.2, 2.4), "horn"))
		table.insert(s, ball(Vector3.new(x * 1.08, 0.6, 3.9), Vector3.new(2, 1.2, 2.4), "horn"))
	end
	for _, side in ipairs({ -1, 1 }) do
		for _, w in ipairs(wing(side, Vector3.new(side * 2.6, 9, -1.5), 9, 8, 5, "accent")) do
			table.insert(s, w)
		end
	end
	head(Vector3.new(0, 11.6, -10.2), 1, true, s)
	for _, t in ipairs(tail(Vector3.new(0, 5.6, 6.5), Vector3.new(0, 0, 1), 7, 3.8, 2.2, 0.6)) do
		table.insert(s, t)
	end
	return s
end

BUILDERS.Wyvern = function()
	local s: { Spec } = {
		ball(Vector3.new(0, 7, 0), Vector3.new(5.6, 5.4, 9.5), "main"),
		ball(Vector3.new(0, 6.2, -0.4), Vector3.new(4.4, 3.8, 8), "belly"),
		ball(Vector3.new(0, 9.6, -5.4), Vector3.new(2.4, 2.4, 3), "main"),
	}
	-- duas patas traseiras fortes
	for _, x in ipairs({ -2.2, 2.2 }) do
		table.insert(s, rod(Vector3.new(x, 6, 2), Vector3.new(x * 1.15, 2.6, 3.2), 2, "main"))
		table.insert(s, rod(Vector3.new(x * 1.15, 2.6, 3.2), Vector3.new(x * 1.15, 0.6, 1.8), 1.3, "main"))
		table.insert(s, ball(Vector3.new(x * 1.15, 0.5, 1.4), Vector3.new(1.8, 1, 2.4), "horn"))
	end
	-- asas que também são os braços: apoiadas no chão na frente
	for _, side in ipairs({ -1, 1 }) do
		local shoulder = Vector3.new(side * 2.4, 8.6, -2.6)
		local elbow = Vector3.new(side * 6, 11.5, -1)
		local wrist = Vector3.new(side * 4.2, 0.8, -5.8)
		table.insert(s, rod(shoulder, elbow, 0.9, "main"))
		table.insert(s, rod(elbow, wrist, 0.7, "main"))
		table.insert(s, rod(elbow, Vector3.new(side * 13, 9, 3), 0.5, "main"))
		table.insert(s, block((elbow + Vector3.new(side * 13, 9, 3)) / 2 + Vector3.new(0, -2.5, 2.5), Vector3.new(8, 0.25, 7), "accent", CFrame.Angles(0, 0, math.rad(-side * 15)) * CFrame.Angles(math.rad(-50), 0, 0)))
	end
	head(Vector3.new(0, 11, -7.4), 0.85, true, s)
	for _, t in ipairs(tail(Vector3.new(0, 6.4, 5), Vector3.new(0, -0.05, 1), 9, 2.8, 2, 0.9)) do
		table.insert(s, t)
	end
	-- ponta da cauda em espinho
	table.insert(s, block(Vector3.new(0, 4, 22.5), Vector3.new(0.3, 2, 2), "accent", CFrame.Angles(0, 0, 0)))
	return s
end

BUILDERS.Amphiptere = function()
	local s: { Spec } = {}
	local n = 12
	for i = 0, n - 1 do
		local t = i / (n - 1)
		local d = 3.2 * (1 - t * 0.6)
		local p = Vector3.new(math.sin(i * 0.7) * 3, 1.8 + (1 - t) * 1.2, -4 + i * 2.1)
		table.insert(s, ball(p, Vector3.new(d, d, d * 1.25), i % 2 == 0 and "main" or "belly"))
	end
	-- pescoço erguido
	table.insert(s, ball(Vector3.new(0, 4.4, -6), Vector3.new(2.6, 2.6, 2.6), "main"))
	table.insert(s, ball(Vector3.new(0, 6.4, -7.4), Vector3.new(2.2, 2.2, 2.2), "main"))
	head(Vector3.new(0, 8, -9), 0.75, false, s)
	-- crista leve
	table.insert(s, block(Vector3.new(0, 9.6, -8.4), Vector3.new(0.2, 1.6, 3), "accent", nil, true))
	-- asas emplumadas (três penas largas por lado)
	for _, side in ipairs({ -1, 1 }) do
		local base = Vector3.new(side * 1.4, 4.6, -2.2)
		for k = 0, 2 do
			local tip = base + Vector3.new(side * (10 - k * 1.5), 5 - k * 1.8, 1 + k * 2.2)
			table.insert(s, rod(base, tip, 0.4, "main"))
			table.insert(s, block((base + tip) / 2, Vector3.new((tip - base).Magnitude, 0.2, 2.6), "accent", CFrame.Angles(0, -side * math.rad(10 + k * 12), math.atan2(tip.Y - base.Y, side * (tip.X - base.X)) * side)))
		end
	end
	return s
end

BUILDERS.Wyrm = function()
	local s: { Spec } = {}
	-- corpo grosso enrolado em espiral
	local n = 14
	for i = 0, n - 1 do
		local t = i / (n - 1)
		local ang = i * 0.62
		local r = 7.5 - t * 4
		local d = 5.2 * (1 - t * 0.55)
		local p = Vector3.new(math.cos(ang) * r, d / 2 + t * 1.5, math.sin(ang) * r)
		table.insert(s, ball(p, Vector3.new(d, d * 0.9, d), i % 3 == 0 and "accent" or "main"))
	end
	-- pescoço e cabeça massiva levantados
	table.insert(s, ball(Vector3.new(8.4, 4.8, -2.4), Vector3.new(4.6, 4.6, 4.6), "main"))
	table.insert(s, ball(Vector3.new(8.8, 7.6, -4.6), Vector3.new(4, 4, 4), "belly"))
	head(Vector3.new(9, 9.6, -7.6), 1.35, true, s)
	-- placas nas costas
	for i = 0, 6 do
		local ang = i * 0.62 * 2
		local r = 7.5 - (i * 2 / (n - 1)) * 4
		table.insert(s, block(Vector3.new(math.cos(ang) * r, 5.4 - i * 0.3, math.sin(ang) * r), Vector3.new(1.4, 1.6, 1.4), "horn", CFrame.Angles(0, ang, math.rad(45))))
	end
	return s
end

BUILDERS.AsianDragon = function()
	local s: { Spec } = {}
	local n = 18
	for i = 0, n - 1 do
		local t = i / (n - 1)
		local d = 2.6 * (1 - t * 0.55)
		local p = Vector3.new(math.sin(i * 0.45) * 2.2, 4.2 + math.sin(i * 0.6) * 1.6, -9 + i * 1.7)
		table.insert(s, ball(p, Vector3.new(d, d, d * 1.3), i % 2 == 0 and "main" or "belly"))
		-- juba/barbatana dorsal
		if i % 2 == 1 and i < n - 2 then
			table.insert(s, block(p + Vector3.new(0, d * 0.6, 0), Vector3.new(0.2, d * 0.6, 1.2), "accent"))
		end
	end
	-- quatro patas curtas
	for _, seg in ipairs({ 3, 11 }) do
		local p = Vector3.new(math.sin(seg * 0.45) * 2.2, 4.2 + math.sin(seg * 0.6) * 1.6, -9 + seg * 1.7)
		for _, side in ipairs({ -1, 1 }) do
			local foot = Vector3.new(p.X + side * 2, 0.5, p.Z - 0.5)
			table.insert(s, rod(p, foot, 0.8, "main"))
			table.insert(s, ball(foot, Vector3.new(1.2, 0.6, 1.4), "horn"))
		end
	end
	-- cabeça com chifres ramificados e bigodes longos
	local hp = Vector3.new(0, 6.6, -11.4)
	head(hp, 0.85, true, s)
	table.insert(s, rod(hp + Vector3.new(1.1, 1.8, 1.6), hp + Vector3.new(2, 2.8, 1), 0.3, "horn", true))
	table.insert(s, rod(hp + Vector3.new(-1.1, 1.8, 1.6), hp + Vector3.new(-2, 2.8, 1), 0.3, "horn", true))
	table.insert(s, rod(hp + Vector3.new(0.8, -0.4, -3.2), hp + Vector3.new(3.6, -1.6, -1.4), 0.15, "accent", true))
	table.insert(s, rod(hp + Vector3.new(-0.8, -0.4, -3.2), hp + Vector3.new(-3.6, -1.6, -1.4), 0.15, "accent", true))
	-- tufo na ponta da cauda
	table.insert(s, ball(Vector3.new(math.sin((n - 1) * 0.45) * 2.2, 4.2 + math.sin((n - 1) * 0.6) * 1.6, -9 + n * 1.7), Vector3.new(1.6, 1.6, 2), "accent"))
	return s
end

local function palette(speciesId: string, elder: boolean): { [string]: Color3 }
	local def = Species[speciesId]
	local e1 = Elements[def.Elements[1]].Color
	local e2 = def.Elements[2] and Elements[def.Elements[2]].Color or e1:Lerp(Color3.new(0, 0, 0), 0.35)
	local main = e1:Lerp(Color3.fromRGB(60, 50, 50), 0.35)
	return {
		main = main,
		accent = e2,
		belly = main:Lerp(Color3.fromRGB(255, 240, 210), 0.45),
		horn = elder and Color3.fromRGB(250, 245, 230) or Color3.fromRGB(225, 210, 175),
		eye = Color3.fromRGB(255, 220, 60),
	}
end

local function makePart(spec: Spec, scale: number, headMul: number, colors: { [string]: Color3 }, root: BasePart): BasePart
	local p: BasePart
	if spec.kind == "Ball" then
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		p = part
	elseif spec.kind == "Cylinder" then
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		p = part
	else
		p = Instance.new("Part")
	end
	local sizeMul = spec.head and scale * headMul or scale
	p.Size = Vector3.new(math.max(0.05, spec.size.X * sizeMul), math.max(0.05, spec.size.Y * sizeMul), math.max(0.05, spec.size.Z * sizeMul))
	local pos = spec.cf.Position * scale
	p.CFrame = root.CFrame * (CFrame.new(pos) * spec.cf.Rotation)
	p.Color = colors[spec.color] or colors.main
	p.Material = spec.color == "eye" and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = true
	p.Massless = true
	p.CastShadow = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	p.Parent = root.Parent
	return p
end

local function makeRoot(model: Model, at: CFrame): BasePart
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 2, 2)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.CFrame = at
	root.Parent = model
	model.PrimaryPart = root
	return root
end

local function nameTag(model: Model, adornee: BasePart, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(220, 54)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 90
	gui.Adornee = adornee
	gui.Parent = model
	local name = Instance.new("TextLabel")
	name.Name = "Title"
	name.Size = UDim2.new(1, 0, 0.6, 0)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.4
	name.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Name = "Subtitle"
	sub.Position = UDim2.fromScale(0, 0.6)
	sub.Size = UDim2.new(1, 0, 0.4, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(230, 230, 230)
	sub.TextStrokeTransparency = 0.5
	sub.Parent = gui
end

-- Atualiza o texto da etiqueta acima do dragão.
function DragonModels.UpdateTag(model: Model, dragon: { [string]: any })
	local gui = model:FindFirstChild("NameTag")
	if not gui then
		return
	end
	local def = Species[dragon.Species]
	local rarity = Rarity.Defs[dragon.Rarity] or Rarity.Defs.Common
	local title = gui:FindFirstChild("Title") :: TextLabel
	title.Text = (dragon.CustomName ~= nil and dragon.CustomName ~= "") and (dragon.CustomName .. " — " .. def.DisplayName) or def.DisplayName
	local sub = gui:FindFirstChild("Subtitle") :: TextLabel
	sub.Text = Growth.StageNames[dragon.Stage] .. " · " .. rarity.DisplayName
	sub.TextColor3 = rarity.Color
end

-- Escala do modelo Adulto gerado para cada estágio que o reaproveita.
local MESH_STAGE_SCALE = { Young = 0.62, Subadult = 0.8, Adult = 1.0, Elder = 1.12 }

local function meshAssetFor(speciesId: string, stage: string): (Model?, number)
	local folder = ServerStorage:FindFirstChild("DragonAssets")
	local species = folder and folder:FindFirstChild(speciesId)
	if not species then
		return nil, 1
	end
	if stage == "Egg" or stage == "Baby" then
		return species:FindFirstChild(stage) :: Model?, 1
	end
	return species:FindFirstChild("Adult") :: Model?, MESH_STAGE_SCALE[stage] or 1
end

-- Coloca o modelo gerado sobre o Root: base no chão, cabeça para a frente (-Z do Root).
local function attachMesh(source: Model, scale: number, root: BasePart): number
	local mesh = source:Clone()
	if scale ~= 1 then
		mesh:ScaleTo(mesh:GetScale() * scale)
	end
	local yaw = math.rad(source:GetAttribute("YawDegrees") or 0)
	mesh:PivotTo(root.CFrame * CFrame.Angles(0, yaw, 0))
	local bcf, size = mesh:GetBoundingBox()
	local bottom = bcf.Position - Vector3.new(0, size.Y / 2, 0)
	mesh:PivotTo(mesh:GetPivot() + (root.Position - bottom))
	for _, d in ipairs(mesh:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = d
			weld.Parent = d
		end
	end
	mesh.Name = "Mesh"
	mesh.Parent = root.Parent
	return size.Y
end

-- Cria o modelo de um dragão (ou ovo) na posição `at` (chão).
function DragonModels.Build(dragon: { [string]: any }, at: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Dragon_" .. dragon.Id
	local stage = dragon.Stage
	local colors = palette(dragon.Species, stage == "Elder")
	local root = makeRoot(model, at)

	local source, meshScale = meshAssetFor(dragon.Species, stage)
	if source then
		local height = attachMesh(source, meshScale, root)
		nameTag(model, root, height + 1.5)
	elseif stage == "Egg" then
		local egg = makePart({ kind = "Ball", size = Vector3.new(2.6, 3.4, 2.6), cf = CFrame.new(0, 1.7, 0), color = "main" }, 1, 1, colors, root)
		egg.Name = "Egg"
		-- faixas com a segunda cor indicam a espécie
		for i, y in ipairs({ 1.2, 2.2 }) do
			local band = makePart({ kind = "Cylinder", size = Vector3.new(0.3, 2.45 - i * 0.25, 2.45 - i * 0.25), cf = CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), color = "accent" }, 1, 1, colors, root)
			band.Name = "Band"
		end
		nameTag(model, root, 4.2)
	else
		local scale = STAGE_SCALE[stage] or 1
		local headMul = STAGE_HEAD[stage] or 1
		local builder = BUILDERS[dragon.Species]
		local maxY = 0
		for _, spec in ipairs(builder()) do
			local part = makePart(spec, scale, headMul, colors, root)
			if spec.head then
				part.Name = "Head"
			end
			maxY = math.max(maxY, (spec.cf.Position.Y + spec.size.Y / 2) * scale)
		end
		nameTag(model, root, maxY + 2)
	end

	model:SetAttribute("DragonId", dragon.Id)
	model:SetAttribute("Species", dragon.Species)
	model:SetAttribute("Stage", stage)
	DragonModels.UpdateTag(model, dragon)
	return model
end

return DragonModels
