--!strict
-- Fase 4: coleta de materiais no mundo e fontes de água/comida.
--  * Pontos de coleta (madeira, pedra, ervas, penas, cristal, obsidiana) criados ao iniciar o
--    servidor, sempre nos mesmos lugares (semente fixa), por região do WorldData.
--  * Cada ponto some ao ser coletado e reaparece depois de Rules.Economy.ResourceRespawnSeconds.
--  * Acampamentos (partes com atributo DragonWater / DragonFood) e o cocho da fazenda enchem
--    cantis e dão carne, com recarga por jogador.
-- Anti-exploit: distância conferida no servidor, intervalo mínimo entre coletas, estado só no servidor.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Gathering = require(ReplicatedStorage.Shared.Config.Gathering)
local Items = require(ReplicatedStorage.Shared.Config.Items)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local Server = ServerScriptService.Server
local NetService = require(Server.Services.NetService)
local InventoryService = require(Server.Services.InventoryService)

local GatherService = {}

type Node = {
	kind: string,
	model: Model,
	prompt: ProximityPrompt,
	pos: Vector3,
	ready: boolean,
	saved: { [BasePart]: number },
}

local nodes: { Node } = {}
local lastGather: { [Player]: number } = {}
local sourceCooldown: { [string]: number } = {} -- "userId:fonte" -> os.clock() liberado

local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

local function hrpOf(player: Player): BasePart?
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

--------------------------------------------------------------------------
-- Visual dos pontos (peças simples com materiais reais; poucas peças por ponto)
--------------------------------------------------------------------------
local function p(model: Model, props: { [string]: any }): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(part :: any)[k] = v
	end
	part.Parent = model
	return part
end

local BUILDERS: { [string]: (Model, CFrame, Random) -> () } = {
	LogPile = function(m, cf, r)
		for i = 0, 2 do
			local len = r:NextNumber(6, 8)
			p(m, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(len, 1.5, 1.5),
				CFrame = cf * CFrame.new((i - 1) * 1.5, 0.75 + (if i == 1 then 1.2 else 0), 0) * CFrame.Angles(0, math.rad(90 + r:NextNumber(-6, 6)), 0),
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(104, 76, 50),
			})
		end
	end,
	RockPile = function(m, cf, r)
		for i = 1, 4 do
			local s = r:NextNumber(1.6, 3.2)
			p(m, {
				Size = Vector3.new(s, s * 0.8, s * 1.1),
				CFrame = cf * CFrame.new(r:NextNumber(-2, 2), s * 0.35, r:NextNumber(-2, 2)) * CFrame.Angles(r:NextNumber(0, 1), r:NextNumber(0, 6), r:NextNumber(0, 1)),
				Material = Enum.Material.Slate,
				Color = Color3.fromRGB(120, 118, 114),
			})
		end
	end,
	HerbPatch = function(m, cf, r)
		for i = 1, 6 do
			local h = r:NextNumber(1, 1.8)
			p(m, {
				Size = Vector3.new(0.25, h, 0.6),
				CFrame = cf * CFrame.new(r:NextNumber(-1.4, 1.4), h / 2, r:NextNumber(-1.4, 1.4)) * CFrame.Angles(r:NextNumber(-0.3, 0.3), r:NextNumber(0, 6), 0),
				Material = Enum.Material.LeafyGrass,
				Color = Color3.fromRGB(86, 150, 70),
			})
		end
		for i = 1, 3 do
			p(m, {
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.6, 0.6, 0.6),
				CFrame = cf * CFrame.new(r:NextNumber(-1.2, 1.2), 1.6, r:NextNumber(-1.2, 1.2)),
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(180, 120, 220),
			})
		end
	end,
	FeatherNest = function(m, cf, r)
		p(m, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.9, 4, 4),
			CFrame = cf * CFrame.new(0, 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Fabric,
			Color = Color3.fromRGB(130, 104, 70),
		})
		for i = 1, 4 do
			p(m, {
				Size = Vector3.new(0.15, 0.5, 1.8),
				CFrame = cf * CFrame.new(r:NextNumber(-1, 1), 1.1, r:NextNumber(-1, 1)) * CFrame.Angles(r:NextNumber(-0.5, 0.5), r:NextNumber(0, 6), 0),
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(240, 236, 226),
			})
		end
	end,
	CrystalNode = function(m, cf, r)
		for i = 1, 4 do
			local h = r:NextNumber(2.5, 5)
			local c = p(m, {
				Size = Vector3.new(1, h, 1),
				CFrame = cf * CFrame.new(r:NextNumber(-1, 1), h * 0.4, r:NextNumber(-1, 1)) * CFrame.Angles(r:NextNumber(-0.4, 0.4), r:NextNumber(0, 6), r:NextNumber(-0.4, 0.4)),
				Material = Enum.Material.Glass,
				Color = Color3.fromRGB(140, 200, 255),
				Transparency = 0.15,
			})
			if i == 1 then
				local l = Instance.new("PointLight")
				l.Color = Color3.fromRGB(140, 200, 255)
				l.Range = 10
				l.Brightness = 0.8
				l.Shadows = false
				l.Parent = c
			end
		end
	end,
	ObsidianNode = function(m, cf, r)
		for i = 1, 3 do
			local h = r:NextNumber(1.8, 3.5)
			p(m, {
				Size = Vector3.new(1.6, h, 1.4),
				CFrame = cf * CFrame.new(r:NextNumber(-1.2, 1.2), h * 0.4, r:NextNumber(-1.2, 1.2)) * CFrame.Angles(r:NextNumber(-0.3, 0.3), r:NextNumber(0, 6), r:NextNumber(-0.3, 0.3)),
				Material = Enum.Material.Glass,
				Color = Color3.fromRGB(30, 24, 36),
				Reflectance = 0.15,
			})
		end
	end,
}

--------------------------------------------------------------------------
-- Posicionamento
--------------------------------------------------------------------------
local function inPolygon(x: number, y: number, pts: { { number } }): boolean
	local inside = false
	local j = #pts
	for i = 1, #pts do
		local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
		if (yi > y) ~= (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
			inside = not inside
		end
		j = i
	end
	return inside
end

local function nearAny(x: number, y: number, list: { any }, r: number): boolean
	for _, f in ipairs(list) do
		local dx, dy = f.x - x, f.y - y
		if dx * dx + dy * dy < r * r then
			return true
		end
	end
	return false
end

local function makeNode(kind: string, cf: CFrame, folder: Folder, r: Random): Node
	local def = Gathering.Nodes[kind]
	local m = Instance.new("Model")
	m.Name = kind
	BUILDERS[kind](m, cf, r)
	local anchor = p(m, { Name = "Anchor", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, 1.5, 0), Transparency = 1, CanQuery = false, CastShadow = false })
	m.PrimaryPart = anchor
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Gather"
	prompt.ActionText = def.Action
	prompt.ObjectText = Items[def.Item].DisplayName
	prompt.HoldDuration = def.Hold
	prompt.MaxActivationDistance = Gathering.InteractDistance - 2
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m:SetAttribute("GatherItem", def.Item)
	m.Parent = folder
	CollectionService:AddTag(m, "Gatherable")
	local node: Node = { kind = kind, model = m, prompt = prompt, pos = anchor.Position, ready = true, saved = {} }
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			node.saved[d] = d.Transparency
		end
	end
	return node
end

local function setReady(node: Node, ready: boolean)
	node.ready = ready
	node.prompt.Enabled = ready
	for part, t in pairs(node.saved) do
		part.Transparency = if ready then t else 1
		local light = part:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = ready
		end
	end
end

local function onGather(player: Player, node: Node)
	if not node.ready then
		return
	end
	local hrp = hrpOf(player)
	if not hrp or (hrp.Position - node.pos).Magnitude > Gathering.InteractDistance + 4 then
		return
	end
	local now = os.clock()
	if now - (lastGather[player] or -math.huge) < Gathering.MinSecondsBetween then
		return
	end
	lastGather[player] = now
	local def = Gathering.Nodes[node.kind]
	local amount = math.random(def.Min, def.Max)
	local added = InventoryService.Add(player, def.Item, amount)
	if added <= 0 then
		notify(player, "Sua mochila está cheia.", "warning")
		return
	end
	setReady(node, false)
	notify(player, string.format("+%d %s", added, Items[def.Item].DisplayName))
	task.delay(Rules.Economy.ResourceRespawnSeconds, function()
		if node.model.Parent then
			setReady(node, true)
		end
	end)
end

local function spawnNodes()
	local wg = ServerStorage:FindFirstChild("WorldGen")
	local wdModule = wg and wg:FindFirstChild("WorldData")
	if not wdModule then
		warn("[Gather] WorldData não encontrado; pontos de coleta não criados")
		return
	end
	local WorldData = require(wdModule :: any)
	local folder = workspace:FindFirstChild("Gatherables")
	if folder then
		folder:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "Gatherables"
	f.Parent = workspace

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = false
	local r = Random.new(Gathering.Seed)
	local hub = WorldData.HUB
	local minNormal = 1 - Gathering.MaxSlope * 0.5
	local placed = 0
	for _, region in ipairs(WorldData.REGIONS) do
		local counts = Gathering.PerRegion[region.id]
		if counts then
			local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
			for _, pt in ipairs(region.pts) do
				minX, maxX = math.min(minX, pt[1]), math.max(maxX, pt[1])
				minY, maxY = math.min(minY, pt[2]), math.max(maxY, pt[2])
			end
			local kinds = {}
			for kind in pairs(counts) do
				table.insert(kinds, kind)
			end
			table.sort(kinds) -- ordem fixa = mesmos lugares sempre
			for _, kind in ipairs(kinds) do
				local want = counts[kind]
				local tries = 0
				local made = 0
				while made < want and tries < want * 15 do
					tries += 1
					local x, y = r:NextNumber(minX, maxX), r:NextNumber(minY, maxY)
					if inPolygon(x, y, region.pts) and not nearAny(x, y, WorldData.FARMS, Gathering.AvoidFarmRadius) and (x - hub.x) ^ 2 + (y - hub.y) ^ 2 > Gathering.AvoidHubRadius ^ 2 then
						local hit = workspace:Raycast(Vector3.new(x, 2000, -y), Vector3.new(0, -2600, 0), params)
						if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y >= minNormal then
							-- apoia no relevo (inclina com o chão) e gira ao acaso
							local up = hit.Normal
							local right = up:Cross(Vector3.zAxis)
							if right.Magnitude < 0.1 then
								right = Vector3.xAxis
							end
							local cf = CFrame.fromMatrix(hit.Position, right.Unit, up) * CFrame.Angles(0, r:NextNumber(0, math.pi * 2), 0)
							local node = makeNode(kind, cf, f, r)
							table.insert(nodes, node)
							node.prompt.Triggered:Connect(function(player: Player)
								onGather(player, node)
							end)
							made += 1
							placed += 1
						end
					end
				end
			end
		end
	end
	print(string.format("[Gather] %d pontos de coleta criados", placed))
end

--------------------------------------------------------------------------
-- Fontes de água e comida (acampamentos e fazenda)
--------------------------------------------------------------------------
local function sourcePrompt(part: BasePart, key: string, action: string, objectText: string, item: string, amount: number, cooldown: number, ownerOnly: number?)
	if part:FindFirstChild(key) then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = key
	prompt.ActionText = action
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = math.max(12, math.min(part.Size.X, part.Size.Z) * 0.6)
	prompt.RequiresLineOfSight = false
	if ownerOnly then
		prompt:SetAttribute("OwnerUserId", ownerOnly)
	end
	prompt.Parent = part
	local sourceId = part:GetFullName()
	prompt.Triggered:Connect(function(player: Player)
		local owner = prompt:GetAttribute("OwnerUserId")
		if owner ~= nil and owner ~= player.UserId then
			return
		end
		local hrp = hrpOf(player)
		if not hrp or (hrp.Position - part.Position).Magnitude > prompt.MaxActivationDistance + part.Size.Magnitude * 0.5 + 6 then
			return
		end
		local k = tostring(player.UserId) .. ":" .. sourceId .. ":" .. item
		local readyAt = sourceCooldown[k] or 0
		if os.clock() < readyAt then
			notify(player, string.format("Volte em %d s.", math.ceil(readyAt - os.clock())))
			return
		end
		local added = InventoryService.Add(player, item, amount)
		if added <= 0 then
			notify(player, "Sua mochila está cheia.", "warning")
			return
		end
		sourceCooldown[k] = os.clock() + cooldown
		notify(player, string.format("+%d %s", added, Items[item].DisplayName), "success")
	end)
end

function GatherService.SetupCampSources()
	local W = Gathering.WaterRefill
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") then
			if d:GetAttribute("DragonWater") then
				sourcePrompt(d, "Refill", "Encher cantis", "Lagoa do acampamento", "WaterFlask", W.Amount, W.CooldownSeconds)
			elseif d:GetAttribute("DragonFood") then
				sourcePrompt(d, "TakeMeat", "Pegar carne", "Comedouro do acampamento", "Meat", Gathering.CampFood.Amount, Gathering.CampFood.CooldownSeconds)
			end
		end
	end
end

-- Cocho de água da fazenda: só o dono enche cantis ali (chamado quando a fazenda é atribuída).
function GatherService.SetupFarm(player: Player, plot: Model)
	local water = plot:FindFirstChild("WaterTrough")
	if water and water:IsA("BasePart") then
		local old = water:FindFirstChild("Refill")
		if old then
			old:Destroy()
		end
		sourcePrompt(water, "Refill", "Encher cantis", "Bebedouro", "WaterFlask", Gathering.WaterRefill.Amount, Gathering.WaterRefill.CooldownSeconds, player.UserId)
	end
end

function GatherService.Init()
	Players.PlayerRemoving:Connect(function(player)
		lastGather[player] = nil
		-- a recarga das fontes fica guardada (sair e voltar não zera a espera)
	end)
	task.spawn(function()
		local ok, err = pcall(spawnNodes)
		if not ok then
			warn("[Gather] " .. tostring(err))
		end
		pcall(GatherService.SetupCampSources)
	end)
end

return GatherService
