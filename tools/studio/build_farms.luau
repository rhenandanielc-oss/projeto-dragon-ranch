-- Constrói a área das 18 fazendas (modo Edit). Pode ser executado de novo: recria tudo.
-- Layout: 6 colunas x 3 fileiras, terrenos de 90 x 90 studs, entrada voltada para +Z.
-- Na Fase 6 (mundo), a área será reposicionada ao lado da vila.

local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("Construir fazendas")

local PLOT = 90
local GAP = 24
local COLS, ROWS = 6, 3
local GROUND_Y = 10
local ORIGIN = Vector3.new(620, GROUND_Y, -40) -- canto do primeiro terreno (x mínimo, z mínimo)

-- Chão plano de grama ligando ao terreno existente
local areaMin = Vector3.new(480, GROUND_Y - 14, -90)
local areaMax = Vector3.new(ORIGIN.X + COLS * PLOT + (COLS - 1) * GAP + 50, GROUND_Y, ORIGIN.Z + ROWS * PLOT + (ROWS - 1) * GAP + 60)
local size = areaMax - areaMin
workspace.Terrain:FillBlock(CFrame.new((areaMin + areaMax) / 2), size, Enum.Material.Grass)
-- limpa o que estiver acima do chão na área
workspace.Terrain:FillBlock(CFrame.new((areaMin + areaMax) / 2 + Vector3.new(0, size.Y / 2 + 60, 0)), Vector3.new(size.X, 120, size.Z), Enum.Material.Air)

local old = workspace:FindFirstChild("Farms")
if old then old:Destroy() end
local farms = Instance.new("Folder")
farms.Name = "Farms"

local WOOD = Color3.fromRGB(124, 92, 60)
local DARKWOOD = Color3.fromRGB(90, 64, 42)

local function part(props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new(props.Shape and "Part" or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function buildPlot(index: number, corner: Vector3): Model
	local model = Instance.new("Model")
	model.Name = string.format("Plot%02d", index)
	local center = corner + Vector3.new(PLOT / 2, 0, PLOT / 2)

	local base = part({
		Name = "Base",
		Size = Vector3.new(PLOT, 1, PLOT),
		CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0)),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(96, 156, 74),
	}, model)
	model.PrimaryPart = base

	local top = GROUND_Y + 1

	-- Cerca com entrada de 14 studs no lado +Z
	local fence = Instance.new("Model")
	fence.Name = "Fence"
	fence.Parent = model
	local half = PLOT / 2
	local function rail(a: Vector3, b: Vector3)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		part({ Name = "Rail", Size = Vector3.new(0.6, 0.6, len), CFrame = CFrame.lookAt(mid + Vector3.new(0, 2.6, 0), b + Vector3.new(0, 2.6, 0)), Material = Enum.Material.WoodPlanks, Color = WOOD }, fence)
		part({ Name = "Rail", Size = Vector3.new(0.6, 0.6, len), CFrame = CFrame.lookAt(mid + Vector3.new(0, 1.4, 0), b + Vector3.new(0, 1.4, 0)), Material = Enum.Material.WoodPlanks, Color = WOOD }, fence)
	end
	local y = top
	local c1 = Vector3.new(center.X - half, y, center.Z - half)
	local c2 = Vector3.new(center.X + half, y, center.Z - half)
	local c3 = Vector3.new(center.X + half, y, center.Z + half)
	local c4 = Vector3.new(center.X - half, y, center.Z + half)
	local gateL = Vector3.new(center.X - 7, y, center.Z + half)
	local gateR = Vector3.new(center.X + 7, y, center.Z + half)
	rail(c1, c2)
	rail(c2, c3)
	rail(c4, c1)
	rail(c3, gateR)
	rail(gateL, c4)
	for _, p in ipairs({ c1, c2, c3, c4, gateL, gateR }) do
		part({ Name = "Post", Size = Vector3.new(1, 3.6, 1), CFrame = CFrame.new(p + Vector3.new(0, 1.8, 0)), Material = Enum.Material.Wood, Color = DARKWOOD }, fence)
	end

	-- Placa na entrada
	local sign = part({ Name = "Sign", Size = Vector3.new(12, 3.5, 0.6), CFrame = CFrame.new(center + Vector3.new(0, 6.5, half + 1)), Material = Enum.Material.WoodPlanks, Color = WOOD }, model)
	part({ Name = "SignPost", Size = Vector3.new(0.8, 5, 0.8), CFrame = CFrame.new(center + Vector3.new(-5, 3, half + 1)), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
	part({ Name = "SignPost", Size = Vector3.new(0.8, 5, 0.8), CFrame = CFrame.new(center + Vector3.new(5, 3, half + 1)), Material = Enum.Material.Wood, Color = DARKWOOD }, model)
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
		label.Text = "Fazenda livre"
		label.Parent = gui
	end

	-- Ninho (incubação)
	local nest = part({ Name = "Nest", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 12, 12), CFrame = CFrame.new(center + Vector3.new(-28, 1.8, -28)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(196, 160, 90) }, model)
	local eggSpot = Instance.new("Attachment")
	eggSpot.Name = "EggSpot"
	eggSpot.Parent = base -- primeiro o pai, depois a posição no mundo
	eggSpot.WorldPosition = center + Vector3.new(-28, 5, -28)

	-- Cocho e bebedouro
	part({ Name = "FoodTrough", Size = Vector3.new(10, 2, 4), CFrame = CFrame.new(center + Vector3.new(-6, 2, -36)), Material = Enum.Material.WoodPlanks, Color = WOOD }, model)
	part({ Name = "WaterTrough", Size = Vector3.new(10, 2, 4), CFrame = CFrame.new(center + Vector3.new(8, 2, -36)), Material = Enum.Material.Slate, Color = Color3.fromRGB(120, 120, 128) }, model)
	part({ Name = "Water", Size = Vector3.new(9, 0.4, 3), CFrame = CFrame.new(center + Vector3.new(8, 3.0, -36)), Material = Enum.Material.Glass, Color = Color3.fromRGB(70, 150, 230), Transparency = 0.3, CanCollide = false }, model)

	-- Poste de treino
	part({ Name = "TrainingPost", Size = Vector3.new(2, 8, 2), CFrame = CFrame.new(center + Vector3.new(30, 5, -28)), Material = Enum.Material.Wood, Color = DARKWOOD }, model)

	-- Baú do armazém (usado na Fase 4)
	part({ Name = "StorageChest", Size = Vector3.new(5, 3.5, 3.5), CFrame = CFrame.new(center + Vector3.new(34, 2.75, 30)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 96, 52) }, model)

	-- 8 posições para dragões (2 fileiras)
	local pens = { Vector3.new(-30, 0, 2), Vector3.new(-10, 0, 2), Vector3.new(10, 0, 2), Vector3.new(30, 0, 2), Vector3.new(-30, 0, 22), Vector3.new(-10, 0, 22), Vector3.new(10, 0, 22), Vector3.new(30, 0, -8) }
	for i, offset in ipairs(pens) do
		local a = Instance.new("Attachment")
		a.Name = "Pen" .. i
		a.Parent = base
		a.WorldPosition = center + offset + Vector3.new(0, 1, 0)
	end

	-- Ponto onde o dono aparece
	local spawnAtt = Instance.new("Attachment")
	spawnAtt.Name = "Spawn"
	spawnAtt.Parent = base
	spawnAtt.WorldPosition = center + Vector3.new(0, 4, half - 8)

	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("OwnerUserId", 0)
	return model
end

local index = 0
for row = 0, ROWS - 1 do
	for col = 0, COLS - 1 do
		index += 1
		local corner = ORIGIN + Vector3.new(col * (PLOT + GAP), 0, row * (PLOT + GAP))
		buildPlot(index, corner).Parent = farms
	end
	task.wait()
end

-- Caminho de terra entre as fileiras
for row = 0, ROWS - 1 do
	local z = ORIGIN.Z + row * (PLOT + GAP) + PLOT + GAP / 2
	local x0 = ORIGIN.X - 20
	local x1 = ORIGIN.X + COLS * PLOT + (COLS - 1) * GAP + 20
	workspace.Terrain:FillBlock(CFrame.new((x0 + x1) / 2, GROUND_Y - 1, z), Vector3.new(x1 - x0, 2, GAP - 6), Enum.Material.Ground)
end

farms.Parent = workspace

-- Ponto de nascimento padrão (antes de receber a fazenda) perto da área
local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
if sp then
	sp.CFrame = CFrame.new(ORIGIN + Vector3.new(-60, 1, 150))
end

if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
return "Fazendas criadas: " .. index
