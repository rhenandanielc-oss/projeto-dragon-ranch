--!strict
-- Fase 5: inimigos básicos do mundo aberto.
--  * Nascem perto dos jogadores, conforme a região (mais e mais fortes nas zonas perigosas),
--    nunca no Hub, nas fazendas nem nos acampamentos; somem quando ninguém está por perto.
--  * IA simples: passeia, persegue quem chegar perto (jogador ou dragão), ataca, volta para casa
--    se for longe demais (e se cura).
--  * Ao serem derrotados, entregam itens e moedas direto para quem derrotou + pontos para o
--    dragão ativo. Tudo no servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EnemiesCfg = require(ReplicatedStorage.Shared.Config.Enemies)
local Items = require(ReplicatedStorage.Shared.Config.Items)
local Growth = require(ReplicatedStorage.Shared.Config.Growth)

local Server = ServerScriptService.Server
local DataService = require(Server.Data.DataService)
local NetService = require(Server.Services.NetService)
local InventoryService = require(Server.Services.InventoryService)
local DragonService = require(Server.Dragons.DragonService)
local CombatService = require(Server.Combat.CombatService)
local WorldQuery = require(Server.World.WorldQuery)

local EnemyService = {}

type Enemy = {
	def: any,
	model: Model,
	hum: Humanoid,
	root: BasePart,
	home: Vector3,
	health: number,
	target: CombatService.Target?,
	lastAttack: number,
	lastSeenPlayer: number,
	returning: boolean,
	slowUntil: number,
	slowMult: number,
	damagers: { [Player]: number },
	bar: Frame,
	dead: boolean,
	wanderAt: number,
}

local enemies: { Enemy } = {}
local folder: Folder
local rng = Random.new()

local GLOBAL_CAP = 70
local SPAWN_MIN, SPAWN_MAX = 110, 240
local COUNT_RADIUS = 420
local DESPAWN_RADIUS = 750

--------------------------------------------------------------------------
-- Corpo procedural (placeholder até a arte final)
--------------------------------------------------------------------------
local function weldPart(model: Model, root: BasePart, props: { [string]: any }, offset: CFrame): BasePart
	local p = Instance.new("Part")
	p.CanCollide = false
	p.CanQuery = true
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.CFrame = root.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
	p.Parent = model
	return p
end

local function buildBody(def: any, at: CFrame): (Model, Humanoid, BasePart)
	local s = def.Size
	local m = Instance.new("Model")
	m.Name = def.Id
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Transparency = 1
	root.CanCollide = true
	root.CanTouch = false
	local hip = 2.2 * s
	local bodyH = 2.4 * s
	if def.Body == "Golem" then
		root.Size = Vector3.new(4.6, 5.6, 3.2) * s
		hip = 3.2 * s
	elseif def.Body == "Humanoid" then
		root.Size = Vector3.new(2, 2.6, 1.2) * s
		hip = 2.4 * s
	elseif def.Body == "Spider" then
		root.Size = Vector3.new(3.6, 1.8, 4) * s
		hip = 1.6 * s
	else
		root.Size = Vector3.new(2.2, bodyH, 4.6) * s
		hip = 1.8 * s
	end
	root.CFrame = at + Vector3.new(0, hip + root.Size.Y / 2, 0)
	root.Parent = m
	m.PrimaryPart = root
	local c = def.Color
	local dark = c:Lerp(Color3.new(0, 0, 0), 0.35)
	if def.Body == "Quadruped" then
		weldPart(m, root, { Name = "Body", Size = Vector3.new(2, 1.8, 4.2) * s, Color = c, Material = Enum.Material.Fabric }, CFrame.new(0, 0, 0))
		weldPart(m, root, { Name = "Head", Size = Vector3.new(1.4, 1.3, 1.8) * s, Color = c, Material = Enum.Material.Fabric }, CFrame.new(0, 0.5 * s, -2.6 * s))
		weldPart(m, root, { Name = "Snout", Size = Vector3.new(0.8, 0.7, 1) * s, Color = dark, Material = Enum.Material.Fabric }, CFrame.new(0, 0.2 * s, -3.7 * s))
		for _, o in ipairs({ { -0.7, -1.5 }, { 0.7, -1.5 }, { -0.7, 1.5 }, { 0.7, 1.5 } }) do
			weldPart(m, root, { Name = "Leg", Size = Vector3.new(0.5, 1.9, 0.5) * s, Color = dark, Material = Enum.Material.Fabric }, CFrame.new(o[1] * s, -1.7 * s, o[2] * s))
		end
		weldPart(m, root, { Name = "Tail", Size = Vector3.new(0.4, 0.4, 1.6) * s, Color = c, Material = Enum.Material.Fabric }, CFrame.new(0, 0.5 * s, 2.6 * s) * CFrame.Angles(math.rad(25), 0, 0))
		for _, x in ipairs({ -0.45, 0.45 }) do
			weldPart(m, root, { Name = "Eye", Size = Vector3.new(0.18, 0.18, 0.1) * s, Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Neon }, CFrame.new(x * s, 0.75 * s, -3.5 * s))
		end
	elseif def.Body == "Spider" then
		weldPart(m, root, { Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6) * s, Color = c, Material = Enum.Material.Fabric }, CFrame.new(0, 0.2 * s, 0.9 * s))
		weldPart(m, root, { Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(1.5, 1.5, 1.5) * s, Color = c, Material = Enum.Material.Fabric }, CFrame.new(0, 0, -1.1 * s))
		for i = 0, 3 do
			for _, side in ipairs({ -1, 1 }) do
				local z = (-0.9 + i * 0.6) * s
				weldPart(m, root, { Name = "Leg", Size = Vector3.new(2.6, 0.25, 0.25) * s, Color = dark, Material = Enum.Material.Fabric }, CFrame.new(side * 1.6 * s, -0.3 * s, z) * CFrame.Angles(0, 0, math.rad(side * -35)))
			end
		end
		for _, x in ipairs({ -0.3, 0.3 }) do
			weldPart(m, root, { Name = "Eye", Size = Vector3.new(0.2, 0.2, 0.1) * s, Color = Color3.fromRGB(230, 40, 40), Material = Enum.Material.Neon }, CFrame.new(x * s, 0.35 * s, -1.8 * s))
		end
	elseif def.Body == "Golem" then
		local mat = if def.Id == "CrystalGolem" then Enum.Material.Glass else Enum.Material.Slate
		weldPart(m, root, { Name = "Torso", Size = Vector3.new(4.2, 3.4, 2.8) * s, Color = c, Material = mat }, CFrame.new(0, 0.8 * s, 0))
		weldPart(m, root, { Name = "Head", Size = Vector3.new(1.6, 1.4, 1.6) * s, Color = c, Material = mat }, CFrame.new(0, 3.1 * s, -0.2 * s))
		for _, x in ipairs({ -2.8, 2.8 }) do
			weldPart(m, root, { Name = "Arm", Size = Vector3.new(1.4, 3.8, 1.4) * s, Color = c, Material = mat }, CFrame.new(x * s, 0, 0))
		end
		for _, x in ipairs({ -1.1, 1.1 }) do
			weldPart(m, root, { Name = "Leg", Size = Vector3.new(1.5, 2.6, 1.5) * s, Color = c, Material = mat }, CFrame.new(x * s, -2.2 * s, 0))
		end
		weldPart(m, root, { Name = "Core", Size = Vector3.new(0.9, 0.9, 0.3) * s, Color = Color3.fromRGB(120, 220, 255), Material = Enum.Material.Neon }, CFrame.new(0, 1 * s, -1.45 * s))
	else -- Humanoid
		weldPart(m, root, { Name = "Torso", Size = Vector3.new(2, 2, 1) * s, Color = c, Material = Enum.Material.Fabric }, CFrame.new(0, 0.3 * s, 0))
		weldPart(m, root, { Name = "Head", Size = Vector3.new(1.2, 1.2, 1.2) * s, Color = Color3.fromRGB(200, 160, 130), Material = Enum.Material.SmoothPlastic }, CFrame.new(0, 1.9 * s, 0))
		weldPart(m, root, { Name = "Hood", Size = Vector3.new(1.4, 0.8, 1.4) * s, Color = dark, Material = Enum.Material.Fabric }, CFrame.new(0, 2.4 * s, 0.05 * s))
		for _, x in ipairs({ -1.5, 1.5 }) do
			weldPart(m, root, { Name = "Arm", Size = Vector3.new(0.9, 2, 0.9) * s, Color = c, Material = Enum.Material.Fabric }, CFrame.new(x * s, 0.3 * s, 0))
		end
		for _, x in ipairs({ -0.5, 0.5 }) do
			weldPart(m, root, { Name = "Leg", Size = Vector3.new(0.9, 2.2, 0.9) * s, Color = Color3.fromRGB(60, 50, 44), Material = Enum.Material.Fabric }, CFrame.new(x * s, -1.9 * s, 0))
		end
		weldPart(m, root, { Name = "Weapon", Size = Vector3.new(0.25, 0.25, 3) * s, Color = Color3.fromRGB(170, 170, 176), Material = Enum.Material.Metal }, CFrame.new(1.5 * s, -0.4 * s, -1.4 * s))
	end
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = hip
	hum.MaxHealth = 1e6 -- a vida real fica no servidor (atributo Health)
	hum.Health = 1e6
	hum.BreakJointsOnDeath = false
	hum.RequiresNeck = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = def.WalkSpeed
	hum.Parent = m
	return m, hum, root
end

local function healthBar(e: Enemy)
	local gui = Instance.new("BillboardGui")
	gui.Name = "EnemyBar"
	gui.Size = UDim2.fromOffset(150, 34)
	gui.StudsOffsetWorldSpace = Vector3.new(0, e.root.Size.Y / 2 + 3 * e.def.Size, 0)
	gui.MaxDistance = 120
	gui.AlwaysOnTop = false
	gui.Adornee = e.root
	gui.Parent = e.model
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0, 16)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 14
	name.TextColor3 = Color3.fromRGB(255, 220, 200)
	name.TextStrokeTransparency = 0.4
	name.Text = e.def.Name
	name.Parent = gui
	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(15, 19)
	back.Size = UDim2.new(1, -30, 0, 9)
	back.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
	back.BorderSizePixel = 0
	back.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(220, 60, 50)
	fill.BorderSizePixel = 0
	fill.Parent = back
	e.bar = fill
end

local function updateBar(e: Enemy)
	e.bar.Size = UDim2.fromScale(math.clamp(e.health / e.def.Health, 0, 1), 1)
	e.model:SetAttribute("Health", e.health)
end

--------------------------------------------------------------------------
-- Alvos (para o CombatService)
--------------------------------------------------------------------------
local function asTarget(e: Enemy): CombatService.Target
	return { kind = "Enemy", model = e.model, root = e.root, radius = math.max(e.root.Size.X, e.root.Size.Z) * 0.6, player = nil, ref = e }
end

local function provider(center: Vector3, radius: number): { CombatService.Target }
	local out = {}
	for _, e in ipairs(enemies) do
		if not e.dead and (e.root.Position - center).Magnitude <= radius + 6 then
			table.insert(out, asTarget(e))
		end
	end
	return out
end

local function rewardKill(e: Enemy)
	-- quem causou mais dano leva a recompensa
	local best: Player? = nil
	local bestDmg = 0
	for p, d in pairs(e.damagers) do
		if p.Parent and d > bestDmg then
			best, bestDmg = p, d
		end
	end
	if not best then
		return
	end
	local player = best :: Player
	local data = DataService.Get(player)
	if not data then
		return
	end
	local parts = {}
	for _, drop in ipairs(e.def.Drops) do
		if drop.Chance > 0 and rng:NextNumber() <= drop.Chance and drop.Max > 0 then
			local n = rng:NextInteger(drop.Min, drop.Max)
			local got = InventoryService.Add(player, drop.Item, n)
			if got > 0 then
				table.insert(parts, string.format("%d %s", got, Items[drop.Item].DisplayName))
			end
		end
	end
	local coins = rng:NextInteger(e.def.Coins[1], e.def.Coins[2])
	data.Coins += coins
	DataService.MarkChanged(player, "Coins")
	table.insert(parts, 1, string.format("%d moedas", coins))
	-- pontos de crescimento para o dragão ativo (se já nasceu)
	local id = data.ActiveDragonId
	local dragon = id and data.Dragons[id]
	if dragon and dragon.Stage ~= "Egg" then
		DragonService.AddPoints(player, id, Growth.Sources.CombatKillBasic, "combat")
		DataService.MarkChanged(player, "Dragons")
	end
	NetService.Fire(player, "Notify", e.def.Name .. " derrotado: " .. table.concat(parts, ", "), "success")
end

local function kill(e: Enemy)
	if e.dead then
		return
	end
	e.dead = true
	e.hum.WalkSpeed = 0
	CombatService.Fx("Death", e.root.Position, { Pos = e.root.Position })
	rewardKill(e)
	for _, d in ipairs(e.model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
		end
	end
	task.delay(1.2, function()
		e.model:Destroy()
	end)
end

local function damageHandler(target: CombatService.Target, amount: number, source: CombatService.Source, opts: { [string]: any }?): number
	local e = target.ref :: Enemy
	if e.dead then
		return 0
	end
	e.health -= amount
	if source.player then
		e.damagers[source.player] = (e.damagers[source.player] or 0) + amount
	end
	-- vira contra quem bateu
	if source.kind == "Player" and source.player then
		e.target = CombatService.PlayerTarget(source.player)
	elseif source.kind == "Dragon" and source.model then
		local root = source.model.PrimaryPart
		if root then
			e.target = { kind = "Dragon", model = source.model, root = root, radius = 3, player = source.player, ref = source.player }
		end
	end
	e.returning = false
	if opts then
		if typeof(opts.Knockback) == "Vector3" then
			e.root.AssemblyLinearVelocity += (opts.Knockback :: Vector3) + Vector3.new(0, 10, 0)
		end
		if type(opts.Slow) == "number" then
			e.slowMult = 1 - opts.Slow
			e.slowUntil = os.clock() + (opts.Duration or 3)
		end
	end
	CombatService.Fx("Hit", e.root.Position, { Pos = e.root.Position + Vector3.new(0, e.root.Size.Y / 2, 0), Amount = math.floor(amount + 0.5), Color = Color3.fromRGB(255, 230, 120) })
	updateBar(e)
	if e.health <= 0 then
		kill(e)
	end
	return amount
end

--------------------------------------------------------------------------
-- Nascimento e IA
--------------------------------------------------------------------------
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { workspace.Terrain }
groundParams.IgnoreWater = false

local function spawnEnemy(id: string, at: Vector3)
	local def = EnemiesCfg.Defs[id]
	if not def then
		return
	end
	local model, hum, root = buildBody(def, CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	model:SetAttribute("EnemyId", id)
	model:SetAttribute("MaxHealth", def.Health)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local e: Enemy = {
		def = def,
		model = model,
		hum = hum,
		root = root,
		home = at,
		health = def.Health,
		target = nil,
		lastAttack = 0,
		lastSeenPlayer = os.clock(),
		returning = false,
		slowUntil = 0,
		slowMult = 1,
		damagers = {},
		bar = nil :: any,
		dead = false,
		wanderAt = os.clock() + rng:NextNumber(2, 6),
	}
	healthBar(e)
	updateBar(e)
	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	table.insert(enemies, e)
end

local function trySpawnNear(player: Player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or #enemies >= GLOBAL_CAP then
		return
	end
	local region = WorldQuery.RegionAt(hrp.Position)
	local spawnCfg = region and EnemiesCfg.Spawns[region.id]
	if not spawnCfg then
		return
	end
	local near = 0
	for _, e in ipairs(enemies) do
		if not e.dead and (e.root.Position - hrp.Position).Magnitude < COUNT_RADIUS then
			near += 1
		end
	end
	if near >= spawnCfg.Max then
		return
	end
	for _ = 1, 6 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(SPAWN_MIN, SPAWN_MAX)
		local x, z = hrp.Position.X + math.cos(a) * d, hrp.Position.Z + math.sin(a) * d
		local hit = workspace:Raycast(Vector3.new(x, hrp.Position.Y + 300, z), Vector3.new(0, -700, 0), groundParams)
		if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y > 0.7 then
			local pos = hit.Position
			local r2 = WorldQuery.RegionAt(pos)
			if r2 and r2.id == region.id and not WorldQuery.IsSafe(pos) then
				spawnEnemy(spawnCfg.List[rng:NextInteger(1, #spawnCfg.List)], pos)
				return
			end
		end
	end
end

local function validTarget(t: CombatService.Target?): boolean
	if not t or not t.model.Parent or not t.root.Parent then
		return false
	end
	if t.kind == "Player" then
		local hum = t.model:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return false
		end
	elseif t.kind == "Dragon" then
		if t.model:GetAttribute("Defeated") then
			return false
		end
	end
	-- quem está em zona protegida não é perseguido
	return not WorldQuery.IsSafe(t.root.Position)
end

local function think(e: Enemy, now: number)
	local pos = e.root.Position
	local def = e.def
	e.hum.WalkSpeed = def.WalkSpeed * (if now < e.slowUntil then e.slowMult else 1)
	-- longe de casa: desiste e volta curando
	if (pos - e.home).Magnitude > def.Leash then
		e.target = nil
		e.returning = true
	end
	if e.returning then
		e.hum:MoveTo(e.home)
		if (pos - e.home).Magnitude < 12 then
			e.returning = false
			e.health = def.Health
			e.damagers = {}
			updateBar(e)
		end
		return
	end
	if not validTarget(e.target) then
		e.target = nil
		-- procura alguém por perto (jogadores e dragões)
		local best: CombatService.Target? = nil
		local bestD = def.AggroRange
		for _, t in ipairs(CombatService.TargetsNear(pos, def.AggroRange)) do
			if t.kind ~= "Enemy" and validTarget(t) then
				local d = (t.root.Position - pos).Magnitude
				if d < bestD then
					best, bestD = t, d
				end
			end
		end
		e.target = best
	end
	local t = e.target
	if t then
		local tp = t.root.Position
		local dist = (Vector3.new(tp.X, pos.Y, tp.Z) - pos).Magnitude
		local reach = def.AttackRange + t.radius + e.root.Size.Z * 0.3
		if dist > reach * 0.8 then
			e.hum:MoveTo(tp)
		else
			e.hum:MoveTo(pos)
			e.root.CFrame = CFrame.lookAt(pos, Vector3.new(tp.X, pos.Y, tp.Z))
		end
		if dist <= reach and now - e.lastAttack >= def.AttackInterval then
			e.lastAttack = now
			CombatService.Fx("EnemyAttack", pos, { Pos = pos, Dir = (tp - pos).Unit })
			CombatService.Damage({ kind = "Enemy", player = nil, model = e.model, position = pos }, t, def.Damage, nil)
		end
	elseif now >= e.wanderAt then
		e.wanderAt = now + rng:NextNumber(4, 9)
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(10, 40)
		e.hum:MoveTo(e.home + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d))
	end
end

function EnemyService.Init()
	folder = Instance.new("Folder")
	folder.Name = "Enemies"
	folder.Parent = workspace
	CombatService.RegisterEnemies(provider, damageHandler)

	-- IA (4×/s)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()
			for i = #enemies, 1, -1 do
				local e = enemies[i]
				if e.dead or not e.model.Parent then
					table.remove(enemies, i)
				else
					local ok, err = pcall(think, e, now)
					if not ok then
						warn("[Enemy] " .. tostring(err))
					end
				end
			end
		end
	end)

	-- nascimento e limpeza (a cada 3 s)
	task.spawn(function()
		while true do
			task.wait(3)
			local now = os.clock()
			local heads: { Vector3 } = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local char = p.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					table.insert(heads, hrp.Position)
				end
				pcall(trySpawnNear, p)
			end
			for _, e in ipairs(enemies) do
				local seen = false
				for _, h in ipairs(heads) do
					if (h - e.root.Position).Magnitude < DESPAWN_RADIUS then
						seen = true
						break
					end
				end
				if seen then
					e.lastSeenPlayer = now
				elseif now - e.lastSeenPlayer > 30 then
					e.dead = true
					e.model:Destroy()
				end
			end
		end
	end)
end

return EnemyService
