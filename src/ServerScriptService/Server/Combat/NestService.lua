--!strict
-- Fase 10: ninhos selvagens com dragão guardião, ovos de espécie aleatória e raridade por sorte,
-- tempestades e o ninho secreto (raridade Secreta) — GAME-DESIGN §4.2.
-- Tudo decidido no servidor: quem pode pegar, espaço na fazenda, sorteio, reaparecimento.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NestsCfg = require(ReplicatedStorage.Shared.Config.Nests)
local Rarity = require(ReplicatedStorage.Shared.Config.Rarity)
local Species = require(ReplicatedStorage.Shared.Config.Species)

local Server = ServerScriptService.Server
local DataService = require(Server.Data.DataService)
local NetService = require(Server.Services.NetService)
local DragonService = require(Server.Dragons.DragonService)
local EnemyService = require(Server.Combat.EnemyService)
local WorldQuery = require(Server.World.WorldQuery)

local NestService = {}

type Nest = {
	id: number,
	pos: Vector3,
	danger: boolean,
	secret: boolean,
	model: Model,
	egg: BasePart,
	prompt: ProximityPrompt,
	state: string, -- "Guarded" | "Free" | "Empty" | "Hidden"
	guardian: any?,
	winner: number?,
	winnerUntil: number,
	respawnAt: number,
}

local nests: { Nest } = {}
local rng = Random.new()
local folder: Folder
local storm = false

local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

local function weighted(list: { { Id: string, Weight: number } }): string
	local total = 0
	for _, e in ipairs(list) do
		total += e.Weight
	end
	local r = rng:NextNumber() * total
	for _, e in ipairs(list) do
		r -= e.Weight
		if r <= 0 then
			return e.Id
		end
	end
	return list[#list].Id
end

local function buildNestModel(pos: Vector3, secret: boolean): (Model, BasePart)
	local m = Instance.new("Model")
	m.Name = if secret then "SecretNest" else "WildNest"
	local function p(props: { [string]: any }): BasePart
		local part = Instance.new("Part")
		part.Anchored = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in pairs(props) do
			(part :: any)[k] = v
		end
		part.Parent = m
		return part
	end
	-- anel de galhos e pedras
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		p({ Name = "Twig", Size = Vector3.new(0.7, 0.7, 5), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 4, 0.8, math.sin(a) * 4)) * CFrame.Angles(0, -a, math.rad(12)), Material = Enum.Material.Wood, Color = Color3.fromRGB(96, 70, 46), CanCollide = false })
	end
	p({ Name = "Bed", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 8, 8), CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(150, 120, 80), CanCollide = false })
	for i = 1, 5 do
		local a = rng:NextNumber(0, math.pi * 2)
		p({ Name = "Rock", Size = Vector3.new(2.2, 1.6, 2), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 6, 0.6, math.sin(a) * 6)) * CFrame.Angles(rng:NextNumber(0, 1), a, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(110, 108, 104) })
	end
	local egg = p({ Name = "Egg", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 3.4, 2.6), CFrame = CFrame.new(pos + Vector3.new(0, 2.4, 0)), Material = Enum.Material.SmoothPlastic, Color = if secret then Color3.fromRGB(30, 240, 220) else Color3.fromRGB(226, 214, 190), CanCollide = false })
	if secret then
		egg.Material = Enum.Material.Neon
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(30, 255, 220)
		l.Range = 24
		l.Brightness = 2
		l.Parent = egg
	end
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.Parent = folder
	return m, egg
end

local function setState(n: Nest, state: string)
	n.state = state
	local visible = state == "Guarded" or state == "Free"
	n.egg.Transparency = if visible then 0 else 1
	n.prompt.Enabled = state == "Free"
	n.model:SetAttribute("NestState", state)
	local light = n.egg:FindFirstChildOfClass("PointLight")
	if light then
		light.Enabled = visible
	end
end

local function spawnGuardian(n: Nest)
	if n.guardian then
		return
	end
	local G = NestsCfg.Guardian
	local S = NestsCfg.Secret
	local mult = if n.secret then S.GuardianHealthMult elseif n.danger then NestsCfg.DangerGuardianMult else 1
	n.guardian = EnemyService.Spawn(G.Enemy, n.pos + Vector3.new(10, 1, 0), {
		NoDespawn = true,
		Leash = G.Leash,
		HealthMult = mult,
		DamageMult = if n.secret then S.GuardianDamageMult elseif n.danger then 1.2 else 1,
		Scale = if n.secret then S.GuardianScale else 1,
		Name = if n.secret then "Guardião da Tempestade" else "Dragão Selvagem",
		Parent = folder,
		OnDeath = function(killer: Player?)
			n.guardian = nil
			if n.state ~= "Guarded" then
				return
			end
			n.winner = killer and killer.UserId or nil
			n.winnerUntil = os.clock() + NestsCfg.ExclusiveSeconds
			setState(n, "Free")
			if killer then
				notify(killer, "O guardião caiu! O ovo do ninho é seu — pegue-o antes que outro pegue.", "success")
			end
		end,
	})
end

local function takeEgg(player: Player, n: Nest)
	if n.state ~= "Free" then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or (hrp.Position - n.pos).Magnitude > 16 then
		return
	end
	if n.winner and n.winner ~= player.UserId and os.clock() < n.winnerUntil then
		notify(player, "Quem venceu o guardião tem a vez de pegar este ovo por mais alguns segundos.")
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local count = 0
	for _ in pairs(data.Dragons) do
		count += 1
	end
	if count >= data.DragonSlots then
		notify(player, "Sua fazenda está cheia. Amplie a fazenda para levar este ovo.", "warning")
		return
	end
	local speciesList = {}
	for id in pairs(Species) do
		table.insert(speciesList, id)
	end
	table.sort(speciesList)
	local speciesId = speciesList[rng:NextInteger(1, #speciesList)]
	local rarityId = if n.secret then "Secret" else weighted(Rarity.WildChances)
	local id = DragonService.CreateDragon(player, speciesId, rarityId)
	if not id then
		return
	end
	setState(n, "Empty")
	n.respawnAt = os.clock() + NestsCfg.RespawnSeconds
	local r = Rarity.Defs[rarityId]
	notify(player, string.format("Você pegou um ovo %s! Ele foi para o ninho da sua fazenda.", r.DisplayName), "success")
	if rarityId == "Secret" or r.Tier >= 5 then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				notify(p, string.format("%s encontrou um ovo %s!", player.DisplayName, r.DisplayName), "info")
			end
		end
	end
end

local function makeNest(pos: Vector3, danger: boolean, secret: boolean): Nest
	local model, egg = buildNestModel(pos, secret)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TakeEgg"
	prompt.ActionText = "Pegar o ovo"
	prompt.ObjectText = if secret then "Ninho da Tempestade" else "Ninho selvagem"
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = egg
	local n: Nest = {
		id = #nests + 1,
		pos = pos,
		danger = danger,
		secret = secret,
		model = model,
		egg = egg,
		prompt = prompt,
		state = "Guarded",
		guardian = nil,
		winner = nil,
		winnerUntil = 0,
		respawnAt = 0,
	}
	prompt.Triggered:Connect(function(player: Player)
		takeEgg(player, n)
	end)
	setState(n, if secret then "Hidden" else "Guarded")
	table.insert(nests, n)
	return n
end

local function spawnNests()
	local data = WorldQuery.Data()
	if not data then
		warn("[Nest] WorldData não encontrado")
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local r = Random.new(NestsCfg.Seed)
	for _, region in ipairs(data.REGIONS) do
		local want = NestsCfg.PerRegion[region.id]
		if want then
			local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
			for _, pt in ipairs(region.pts) do
				minX, maxX = math.min(minX, pt[1]), math.max(maxX, pt[1])
				minY, maxY = math.min(minY, pt[2]), math.max(maxY, pt[2])
			end
			local made, tries = 0, 0
			while made < want and tries < 80 do
				tries += 1
				local x, y = r:NextNumber(minX, maxX), r:NextNumber(minY, maxY)
				if WorldQuery.InPolygon(x, y, region.pts) then
					local hit = workspace:Raycast(Vector3.new(x, 2000, -y), Vector3.new(0, -2600, 0), params)
					if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y > 0.8 and not WorldQuery.IsSafe(hit.Position) then
						makeNest(hit.Position, region.danger == true, false)
						made += 1
					end
				end
			end
		end
	end
	-- ninho secreto (escondido; só aparece na tempestade)
	local S = NestsCfg.Secret
	local hit = workspace:Raycast(Vector3.new(S.x, 2000, -S.y), Vector3.new(0, -2600, 0), params)
	if hit then
		makeNest(hit.Position, true, true)
	end
	print(string.format("[Nest] %d ninhos criados", #nests))
end

local function setStorm(on: boolean)
	storm = on
	workspace:SetAttribute("Storm", on)
	for _, n in ipairs(nests) do
		if n.secret then
			if on and n.state == "Hidden" then
				setState(n, "Guarded")
			elseif not on and n.state ~= "Empty" then
				if n.guardian then
					EnemyService.Remove(n.guardian)
					n.guardian = nil
				end
				setState(n, "Hidden")
			end
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		notify(p, if on then "Uma tempestade se aproxima das Terras de Escamarra…" else "A tempestade passou.", "info")
	end
end

function NestService.IsStorm(): boolean
	return storm
end

function NestService.Init()
	folder = Instance.new("Folder")
	folder.Name = "Nests"
	folder.Parent = workspace
	task.spawn(function()
		local ok, err = pcall(spawnNests)
		if not ok then
			warn("[Nest] " .. tostring(err))
		end
	end)

	-- guardiões acordam quando alguém chega perto; ninhos vazios reaparecem
	task.spawn(function()
		while true do
			task.wait(2)
			local now = os.clock()
			local heads: { Vector3 } = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local char = p.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					table.insert(heads, hrp.Position)
				end
			end
			for _, n in ipairs(nests) do
				if n.state == "Empty" and now >= n.respawnAt and not n.secret then
					setState(n, "Guarded")
				elseif n.state == "Empty" and n.secret and now >= n.respawnAt and not storm then
					setState(n, "Hidden")
				end
				if n.state == "Guarded" and not n.guardian then
					for _, h in ipairs(heads) do
						if (h - n.pos).Magnitude < NestsCfg.WakeDistance then
							spawnGuardian(n)
							break
						end
					end
				end
				-- ovo livre há muito tempo sem dono: continua livre para qualquer um
			end
		end
	end)

	-- ciclo de tempestades
	task.spawn(function()
		local S = NestsCfg.Storm
		while true do
			task.wait(rng:NextNumber(S.MinGapSeconds, S.MaxGapSeconds))
			setStorm(true)
			task.wait(S.DurationSeconds)
			setStorm(false)
		end
	end)

	-- teste no Studio: atributo ForceStorm em ServerScriptService liga/desliga a tempestade
	ServerScriptService:GetAttributeChangedSignal("ForceStorm"):Connect(function()
		if game:GetService("RunService"):IsStudio() then
			setStorm(ServerScriptService:GetAttribute("ForceStorm") == true)
		end
	end)
end

return NestService
