--!strict
-- Fase 7: dungeon "Santuário da Cascata" com instância por grupo (GAME-DESIGN §9.5).
--  * Portão no mundo (vale escondido ao norte, atrás da cachoeira) com círculo de grupo:
--    o primeiro a pisar vira líder; quem pisar em até 30 s entra (máx. 4); o líder pode iniciar antes.
--  * Cada grupo recebe uma cópia da dungeon numa área isolada fora do mapa.
--  * Salas: aranhas → ponte do abismo (espinhos) → câmara das runas (placas em sequência)
--    → golens → chefe (Guardião da Cascata) → baú final e portal de saída.
--  * Morte elimina (volta ao portão, fica com o loot, sem baú final nem item de missão).
--  * Desconexão: 3 min para voltar à mesma instância.
--  * Baú final: loot individual; recompensa completa só a cada 20 h por jogador; item de missão
--    (Poção do Voo / Poção da Terra) para quem tem a missão ativa.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DungeonCfg = require(ReplicatedStorage.Shared.Config.Dungeon)
local Items = require(ReplicatedStorage.Shared.Config.Items)

local Server = ServerScriptService.Server
local DataService = require(Server.Data.DataService)
local NetService = require(Server.Services.NetService)
local InventoryService = require(Server.Services.InventoryService)
local DragonService = require(Server.Dragons.DragonService)
local CompanionService = require(Server.Dragons.CompanionService)
local CombatService = require(Server.Combat.CombatService)
local EnemyService = require(Server.Combat.EnemyService)

local DungeonService = {}

type Member = { userId: number, name: string, status: string, deadline: number? }
type Run = {
	id: number,
	slot: number,
	origin: CFrame,
	model: Model,
	members: { [number]: Member },
	checkpoint: CFrame,
	enemies: { any },
	stage: string,
	plateSeq: { number },
	plateIndex: number,
	boss: any?,
	clearedAt: number?,
	opened: { [number]: boolean },
	closing: boolean,
}

local runs: { [number]: Run } = {}
local slotsUsed: { [number]: boolean } = {}
local runOf: { [number]: number } = {} -- userId -> run id
local nextRunId = 1
local rng = Random.new()

local gateCF: CFrame? = nil
local circlePart: BasePart? = nil
local circleLabel: TextLabel? = nil
local forming: { leader: number?, members: { number }, startAt: number }? = nil

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

local function teleport(player: Player, cf: CFrame)
	local char = player.Character
	if not char then
		return
	end
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 5)
	end)
	if CompanionService.IsMounted(player) then
		CompanionService.Dismount(player)
	end
	char:PivotTo(cf + Vector3.new(0, 4, 0))
end

--------------------------------------------------------------------------
-- Geometria da dungeon (peças simples; uma cópia por grupo)
--------------------------------------------------------------------------
local STONE = Color3.fromRGB(70, 74, 82)
local DARK = Color3.fromRGB(48, 50, 58)
local WATER = Color3.fromRGB(60, 120, 170)

local function P(parent: Instance, props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Slate
	p.Color = STONE
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function torch(parent: Instance, cf: CFrame)
	P(parent, { Name = "TorchPost", Size = Vector3.new(0.6, 3, 0.6), CFrame = cf, Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 56, 36) })
	local flame = P(parent, { Name = "Flame", Size = Vector3.new(0.8, 1.2, 0.8), CFrame = cf * CFrame.new(0, 2, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 160, 70), CanCollide = false, CastShadow = false })
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 170, 90)
	l.Range = 30
	l.Brightness = 1.6
	l.Parent = flame
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Heat = 4
	fire.Parent = flame
end

-- Sala retangular (centro z, largura w em X, profundidade d em Z), com vãos de 20 na frente/fundo.
local function room(parent: Instance, cz: number, w: number, d: number, gapFront: boolean, gapBack: boolean, name: string)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local H = 34
	P(m, { Name = "Floor", Size = Vector3.new(w, 2, d), CFrame = CFrame.new(0, -1, cz), Material = Enum.Material.Slate, Color = DARK })
	P(m, { Name = "Ceiling", Size = Vector3.new(w + 4, 2, d + 4), CFrame = CFrame.new(0, H + 1, cz), Color = DARK })
	for _, sx in ipairs({ -1, 1 }) do
		P(m, { Name = "Wall", Size = Vector3.new(2, H, d), CFrame = CFrame.new(sx * (w / 2 + 1), H / 2, cz) })
		for k = 1, math.max(1, math.floor(d / 40)) do
			torch(m, CFrame.new(sx * (w / 2 - 1.5), 6, cz - d / 2 + k * d / (math.floor(d / 40) + 1)))
		end
	end
	for _, side in ipairs({ { 1, gapFront }, { -1, gapBack } }) do
		local z = cz + side[1] * (d / 2 + 1)
		if side[2] then
			local seg = (w - 20) / 2
			for _, sx in ipairs({ -1, 1 }) do
				P(m, { Name = "Wall", Size = Vector3.new(seg, H, 2), CFrame = CFrame.new(sx * (10 + seg / 2), H / 2, z) })
			end
			P(m, { Name = "Lintel", Size = Vector3.new(20, H - 22, 2), CFrame = CFrame.new(0, 22 + (H - 22) / 2, z) })
		else
			P(m, { Name = "Wall", Size = Vector3.new(w, H, 2), CFrame = CFrame.new(0, H / 2, z) })
		end
	end
	return m
end

local function corridor(parent: Instance, z0: number, z1: number)
	local m = Instance.new("Model")
	m.Name = "Corridor"
	m.Parent = parent
	local d = math.abs(z1 - z0)
	local cz = (z0 + z1) / 2
	P(m, { Name = "Floor", Size = Vector3.new(20, 2, d), CFrame = CFrame.new(0, -1, cz), Color = DARK })
	P(m, { Name = "Ceiling", Size = Vector3.new(24, 2, d), CFrame = CFrame.new(0, 23, cz), Color = DARK })
	for _, sx in ipairs({ -1, 1 }) do
		P(m, { Name = "Wall", Size = Vector3.new(2, 22, d), CFrame = CFrame.new(sx * 11, 11, cz) })
	end
	torch(m, CFrame.new(9.5, 6, cz))
end

local function door(parent: Instance, z: number, name: string): BasePart
	local d = P(parent, { Name = name, Size = Vector3.new(20, 22, 2), CFrame = CFrame.new(0, 11, z), Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 56, 52) })
	d:SetAttribute("Door", true)
	return d
end

local function marker(parent: Instance, name: string, cf: CFrame): BasePart
	return P(parent, { Name = name, Size = Vector3.new(1, 1, 1), CFrame = cf, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
end

local template: Model? = nil
local function buildTemplate(): Model
	local m = Instance.new("Model")
	m.Name = "DungeonTemplate"
	m.WorldPivot = CFrame.new()
	local folder = Instance.new("Folder")
	folder.Name = "Geometry"
	folder.Parent = m
	-- A: entrada com queda-d'água no fundo
	room(folder, 0, 60, 60, false, true, "Entrance")
	P(folder, { Name = "Waterfall", Size = Vector3.new(16, 30, 1), CFrame = CFrame.new(0, 15, 28), Material = Enum.Material.Glass, Color = WATER, Transparency = 0.35, CanCollide = false })
	P(folder, { Name = "Pool", Size = Vector3.new(24, 0.4, 10), CFrame = CFrame.new(0, 0.2, 22), Material = Enum.Material.Glass, Color = WATER, Transparency = 0.3, CanCollide = false })
	marker(m, "Spawn", CFrame.new(0, 0, 8))
	corridor(folder, -30, -60)
	-- B: aranhas
	room(folder, -105, 90, 90, true, true, "SpiderHall")
	door(m, -151, "DoorB")
	corridor(folder, -150, -170)
	-- C: ponte do abismo
	local pit = Instance.new("Model")
	pit.Name = "Chasm"
	pit.Parent = folder
	P(pit, { Name = "Floor", Size = Vector3.new(40, 2, 12), CFrame = CFrame.new(0, -1, -176), Color = DARK })
	P(pit, { Name = "Floor", Size = Vector3.new(40, 2, 12), CFrame = CFrame.new(0, -1, -244), Color = DARK })
	for i, z in ipairs({ -190, -203, -216, -229 }) do
		P(pit, { Name = "Platform", Size = Vector3.new(10, 2, 10), CFrame = CFrame.new(if i % 2 == 0 then 4 else -4, -1, z), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(110, 106, 100) })
	end
	for _, sx in ipairs({ -1, 1 }) do
		P(pit, { Name = "Wall", Size = Vector3.new(2, 70, 80), CFrame = CFrame.new(sx * 21, 0, -210) })
	end
	P(pit, { Name = "Ceiling", Size = Vector3.new(44, 2, 80), CFrame = CFrame.new(0, 35, -210), Color = DARK })
	local spikes = P(m, { Name = "Spikes", Size = Vector3.new(40, 2, 56), CFrame = CFrame.new(0, -34, -210), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 40, 40) })
	spikes:SetAttribute("Hazard", true)
	for k = 0, 9 do
		P(pit, { Name = "Spike", Size = Vector3.new(1.2, 4, 1.2), CFrame = CFrame.new(-16 + k * 3.6, -31, -200 + (k % 3) * 8) * CFrame.Angles(0, 0, math.rad(45)), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 150, 156), CanCollide = false })
	end
	marker(m, "CP_Chasm", CFrame.new(0, 0, -176))
	-- D: câmara das runas (placas em sequência)
	room(folder, -280, 60, 60, true, true, "RuneChamber")
	for i, x in ipairs({ -15, 0, 15 }) do
		local plate = P(m, { Name = "Plate" .. i, Size = Vector3.new(8, 0.6, 8), CFrame = CFrame.new(x, 0.3, -282), Material = Enum.Material.Marble, Color = Color3.fromRGB(150, 146, 140) })
		plate:SetAttribute("Plate", i)
		P(m, { Name = "Rune" .. i, Size = Vector3.new(4, 4, 0.4), CFrame = CFrame.new(x, 14, -308.6), Material = Enum.Material.Neon, Color = Color3.fromRGB(60, 50, 90) })
	end
	door(m, -311, "DoorD")
	corridor(folder, -310, -330)
	-- E: golens
	room(folder, -375, 90, 90, true, true, "GolemHall")
	marker(m, "CP_Golems", CFrame.new(0, 0, -336))
	door(m, -421, "DoorE")
	corridor(folder, -420, -440)
	-- F: chefe
	room(folder, -500, 120, 120, true, true, "BossHall")
	for _, o in ipairs({ { -40, -470 }, { 40, -470 }, { -40, -530 }, { 40, -530 } }) do
		P(folder, { Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(34, 7, 7), CFrame = CFrame.new(o[1], 17, o[2]) * CFrame.Angles(0, 0, math.rad(90)) })
	end
	marker(m, "CP_Boss", CFrame.new(0, 0, -446))
	marker(m, "BossSpawn", CFrame.new(0, 0, -515))
	door(m, -561, "DoorG")
	-- G: tesouro e saída
	room(folder, -580, 40, 40, true, false, "Treasure")
	P(m, { Name = "Chest", Size = Vector3.new(6, 4, 4), CFrame = CFrame.new(0, 2, -584), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(130, 90, 50) })
	P(m, { Name = "ChestBand", Size = Vector3.new(6.1, 0.5, 4.1), CFrame = CFrame.new(0, 3.2, -584), Material = Enum.Material.Metal, Color = Color3.fromRGB(210, 170, 80) })
	P(m, { Name = "ExitPortal", Size = Vector3.new(12, 18, 1), CFrame = CFrame.new(0, 9, -598.5), Material = Enum.Material.Neon, Color = Color3.fromRGB(110, 80, 230), Transparency = 0.3, CanCollide = false })
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Spikes" then
			d.CanTouch = false
		end
	end
	return m
end

--------------------------------------------------------------------------
-- Jogadores do grupo
--------------------------------------------------------------------------
local function membersIn(run: Run): { Player }
	local out = {}
	for uid, mem in pairs(run.members) do
		if mem.status == "In" then
			local p = Players:GetPlayerByUserId(uid)
			if p then
				table.insert(out, p)
			end
		end
	end
	return out
end

local function broadcast(run: Run, text: string, kind: string?)
	for _, p in ipairs(membersIn(run)) do
		notify(p, text, kind)
	end
end

local function gateSpawn(): CFrame
	local g = gateCF or CFrame.new(0, 50, 0)
	return g * CFrame.new(0, 0, -30)
end

local cleanup: (Run) -> ()

local function eliminate(run: Run, player: Player)
	local mem = run.members[player.UserId]
	if not mem or mem.status ~= "In" then
		return
	end
	mem.status = "Eliminated"
	runOf[player.UserId] = nil
	player:SetAttribute("InDungeon", nil)
	notify(player, "Você foi derrotado e saiu da expedição. Fica com o que já coletou, mas não recebe o baú final.", "warning")
	broadcast(run, player.DisplayName .. " foi eliminado da expedição.", "warning")
	if #membersIn(run) == 0 then
		local anyPending = false
		for _, m in pairs(run.members) do
			if m.status == "Disconnected" then
				anyPending = true
			end
		end
		if not anyPending then
			cleanup(run)
		end
	end
end

local function leave(run: Run, player: Player, reason: string?)
	local mem = run.members[player.UserId]
	if mem then
		mem.status = "Left"
	end
	runOf[player.UserId] = nil
	player:SetAttribute("InDungeon", nil)
	teleport(player, gateSpawn())
	if reason then
		notify(player, reason)
	end
	if #membersIn(run) == 0 then
		cleanup(run)
	end
end

cleanup = function(run: Run)
	if run.closing then
		return
	end
	run.closing = true
	for uid, mem in pairs(run.members) do
		if mem.status == "In" then
			local p = Players:GetPlayerByUserId(uid)
			if p then
				runOf[uid] = nil
				p:SetAttribute("InDungeon", nil)
				teleport(p, gateSpawn())
			end
		end
		if runOf[uid] == run.id then
			runOf[uid] = nil
		end
	end
	for _, e in ipairs(run.enemies) do
		EnemyService.Remove(e)
	end
	if run.boss then
		EnemyService.Remove(run.boss)
	end
	run.model:Destroy()
	slotsUsed[run.slot] = nil
	runs[run.id] = nil
end

--------------------------------------------------------------------------
-- Progresso da instância
--------------------------------------------------------------------------
local function openDoor(run: Run, name: string)
	local d = run.model:FindFirstChild(name)
	if d and d:IsA("BasePart") then
		d.CanCollide = false
		d.Transparency = 1
		CombatService.Fx("Death", d.Position, { Pos = d.Position })
	end
end

local function spawnRoom(run: Run, cfg: any, center: Vector3, onClear: () -> ())
	local count = cfg.Base + cfg.PerMember * #membersIn(run)
	local alive = count
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		local pos = center + Vector3.new(math.cos(a) * 22, 1, math.sin(a) * 22)
		local e = EnemyService.Spawn(cfg.List[rng:NextInteger(1, #cfg.List)], pos, {
			NoDespawn = true,
			Leash = 70,
			Parent = run.model,
			OnDeath = function()
				alive -= 1
				if alive <= 0 then
					onClear()
				end
			end,
		})
		if e then
			table.insert(run.enemies, e)
		else
			alive -= 1
		end
	end
	if alive <= 0 then
		onClear()
	end
end

local function worldOf(run: Run, name: string): CFrame
	local p = run.model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p.CFrame else run.origin
end

local function lightRunes(run: Run)
	-- mostra a sequência piscando as runas
	task.spawn(function()
		for _, idx in ipairs(run.plateSeq) do
			local r = run.model:FindFirstChild("Rune" .. idx)
			if r and r:IsA("BasePart") then
				r.Color = Color3.fromRGB(150, 120, 255)
				task.wait(0.8)
				r.Color = Color3.fromRGB(60, 50, 90)
				task.wait(0.3)
			end
		end
	end)
end

local function spawnBoss(run: Run)
	local B = DungeonCfg.Boss
	local n = math.max(1, #membersIn(run))
	local at = worldOf(run, "BossSpawn").Position + Vector3.new(0, 1, 0)
	local lastSlam = os.clock()
	run.boss = EnemyService.Spawn(B.Enemy, at, {
		NoDespawn = true,
		Leash = 80,
		Scale = B.Scale,
		HealthMult = B.HealthMultBase + B.HealthMultPerMember * n,
		DamageMult = B.DamageMult,
		Name = B.Name,
		Parent = run.model,
		Special = function(e: any, now: number)
			if now - lastSlam < B.SlamEvery then
				return
			end
			lastSlam = now
			local center = e.root.Position
			CombatService.Fx("Power", center, { Kind = "Area", Element = "Earth", To = center, Radius = B.SlamRadius })
			task.delay(1, function()
				if not e.dead then
					EnemyService.AreaAttack(e, center, B.SlamRadius, B.SlamDamage)
				end
			end)
		end,
		OnDeath = function()
			run.stage = "Cleared"
			run.clearedAt = os.clock()
			openDoor(run, "DoorG")
			broadcast(run, "O Guardião da Cascata caiu! Abra o baú e use o portal para sair.", "success")
		end,
	})
	broadcast(run, "O Guardião da Cascata despertou!", "warning")
end

local function openChest(run: Run, player: Player)
	local mem = run.members[player.UserId]
	if run.stage ~= "Cleared" or not mem or mem.status ~= "In" or run.opened[player.UserId] then
		return
	end
	local hrp = hrpOf(player)
	local chest = run.model:FindFirstChild("Chest") :: BasePart?
	if not hrp or not chest or (hrp.Position - chest.Position).Magnitude > 16 then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	run.opened[player.UserId] = true
	local C = DungeonCfg.Chest
	local parts = {}
	local now = os.time()
	local full = now >= (data.Dungeon.FinalChestReadyAt or 0)
	if full then
		data.Dungeon.FinalChestReadyAt = now + DungeonCfg.ChestCooldownSeconds
		DataService.MarkChanged(player, "Dungeon")
		local coins = rng:NextInteger(C.Coins[1], C.Coins[2])
		data.Coins += coins
		table.insert(parts, coins .. " moedas")
		for _, it in ipairs(C.Items) do
			local n = rng:NextInteger(it.Min, it.Max)
			local got = InventoryService.Add(player, it.Item, n)
			if got > 0 then
				table.insert(parts, string.format("%d %s", got, Items[it.Item].DisplayName))
			end
		end
		local id = data.ActiveDragonId
		if id and data.Dragons[id] and data.Dragons[id].Stage ~= "Egg" then
			DragonService.AddPoints(player, id, C.Points, "dungeon")
			DataService.MarkChanged(player, "Dragons")
			table.insert(parts, C.Points .. " pontos para o dragão")
		end
	else
		data.Coins += C.ReducedCoins
		table.insert(parts, C.ReducedCoins .. " moedas (recompensa completa só a cada 20 h)")
	end
	DataService.MarkChanged(player, "Coins")
	-- item de missão para quem está nessa etapa
	for questId, itemId in pairs(C.QuestItems) do
		local st = data.Quests.Active[questId]
		if st and InventoryService.CountQuestItem(player, itemId) == 0 then
			InventoryService.AddQuestItem(player, itemId, 1)
			table.insert(parts, Items[itemId].DisplayName)
		end
	end
	notify(player, "Baú do Santuário: " .. table.concat(parts, ", "), "success")
end

local function startRun(memberIds: { number })
	local slot = 0
	for i = 1, DungeonCfg.Slots do
		if not slotsUsed[i] then
			slot = i
			break
		end
	end
	if slot == 0 then
		for _, uid in ipairs(memberIds) do
			local p = Players:GetPlayerByUserId(uid)
			if p then
				notify(p, "Todas as cópias da dungeon estão ocupadas. Tente de novo em instantes.", "warning")
			end
		end
		return
	end
	slotsUsed[slot] = true
	if not template then
		template = buildTemplate()
	end
	local origin = CFrame.new(DungeonCfg.AreaOrigin + Vector3.new((slot - 1) * DungeonCfg.SlotSpacing, 0, 0))
	local model = (template :: Model):Clone()
	model.Name = "DungeonRun" .. slot
	model:PivotTo(origin)
	model.Parent = workspace
	local id = nextRunId
	nextRunId += 1
	local run: Run = {
		id = id,
		slot = slot,
		origin = origin,
		model = model,
		members = {},
		checkpoint = worldOf({ model = model, origin = origin } :: any, "Spawn"),
		enemies = {},
		stage = "Spiders",
		plateSeq = {},
		plateIndex = 1,
		boss = nil,
		clearedAt = nil,
		opened = {},
		closing = false,
	}
	runs[id] = run
	-- sequência das placas (aleatória por instância)
	local seq = { 1, 2, 3 }
	for i = 3, 2, -1 do
		local j = rng:NextInteger(1, i)
		seq[i], seq[j] = seq[j], seq[i]
	end
	run.plateSeq = seq

	for _, uid in ipairs(memberIds) do
		local p = Players:GetPlayerByUserId(uid)
		if p and hrpOf(p) then
			run.members[uid] = { userId = uid, name = p.DisplayName, status = "In" }
			runOf[uid] = id
			p:SetAttribute("InDungeon", id)
			teleport(p, run.checkpoint)
			notify(p, "Expedição iniciada: " .. DungeonCfg.Name .. ". Cuidado: quem morrer sai da expedição.", "warning")
		end
	end
	if #membersIn(run) == 0 then
		cleanup(run)
		return
	end

	-- sala das aranhas
	local hall = run.origin * CFrame.new(0, 0, -105)
	spawnRoom(run, DungeonCfg.Rooms.Spiders, hall.Position, function()
		run.stage = "Chasm"
		openDoor(run, "DoorB")
		run.checkpoint = worldOf(run, "CP_Chasm")
		broadcast(run, "A passagem se abriu. Atravesse a ponte do abismo!")
	end)

	-- espinhos do abismo: dano e volta ao ponto de controle
	local spikes = model:FindFirstChild("Spikes") :: BasePart?
	if spikes then
		local hitAt: { [number]: number } = {}
		spikes.Touched:Connect(function(hit)
			local char = hit:FindFirstAncestorOfClass("Model")
			local p = char and Players:GetPlayerFromCharacter(char)
			if not p or (hitAt[p.UserId] or 0) > os.clock() then
				return
			end
			hitAt[p.UserId] = os.clock() + 1
			local hum = (char :: Model):FindFirstChildOfClass("Humanoid")
			if hum then
				hum:TakeDamage(DungeonCfg.SpikeDamage)
				if hum.Health > 0 then
					teleport(p, run.checkpoint)
				end
			end
		end)
	end

	-- placas das runas
	for i = 1, 3 do
		local plate = model:FindFirstChild("Plate" .. i) :: BasePart?
		if plate then
			plate.CanTouch = true
			local cool = 0
			plate.Touched:Connect(function(hit)
				if run.stage ~= "Runes" or os.clock() < cool then
					return
				end
				local char = hit:FindFirstAncestorOfClass("Model")
				local p = char and Players:GetPlayerFromCharacter(char)
				if not p or not run.members[p.UserId] then
					return
				end
				cool = os.clock() + 1
				if run.plateSeq[run.plateIndex] == i then
					plate.Color = Color3.fromRGB(150, 120, 255)
					run.plateIndex += 1
					if run.plateIndex > 3 then
						run.stage = "Golems"
						openDoor(run, "DoorD")
						run.checkpoint = worldOf(run, "CP_Golems")
						broadcast(run, "As runas se acenderam. A porta se abriu!", "success")
						local gh = run.origin * CFrame.new(0, 0, -375)
						spawnRoom(run, DungeonCfg.Rooms.Golems, gh.Position, function()
							run.stage = "Boss"
							openDoor(run, "DoorE")
							run.checkpoint = worldOf(run, "CP_Boss")
							spawnBoss(run)
						end)
					end
				else
					run.plateIndex = 1
					for k = 1, 3 do
						local pk = model:FindFirstChild("Plate" .. k) :: BasePart?
						if pk then
							pk.Color = Color3.fromRGB(150, 146, 140)
						end
					end
					broadcast(run, "Sequência errada! Observe as runas de novo.", "warning")
					lightRunes(run)
				end
			end)
		end
	end

	-- baú e portal
	local chest = model:FindFirstChild("Chest") :: BasePart?
	if chest then
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText = "Abrir baú"
		pr.ObjectText = "Baú do Santuário"
		pr.HoldDuration = 0.8
		pr.MaxActivationDistance = 12
		pr.RequiresLineOfSight = false
		pr.Parent = chest
		pr.Triggered:Connect(function(p: Player)
			openChest(run, p)
		end)
	end
	local portal = model:FindFirstChild("ExitPortal") :: BasePart?
	if portal then
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText = "Sair da dungeon"
		pr.ObjectText = "Portal"
		pr.MaxActivationDistance = 12
		pr.RequiresLineOfSight = false
		pr.Parent = portal
		pr.Triggered:Connect(function(p: Player)
			if run.stage == "Cleared" and runOf[p.UserId] == run.id then
				leave(run, p, "Você voltou ao portão do Santuário.")
			end
		end)
	end
end

--------------------------------------------------------------------------
-- Círculo de grupo no portão
--------------------------------------------------------------------------
local function setupGate()
	local world = workspace:FindFirstChild("World")
	local lm = world and world:FindFirstChild("Landmarks")
	local gate = lm and lm:FindFirstChild("DungeonGate")
	local portal = gate and gate:FindFirstChild("Portal")
	if not portal or not portal:IsA("BasePart") then
		warn("[Dungeon] Portão não encontrado (World.Landmarks.DungeonGate.Portal)")
		return
	end
	-- o portal olha para fora (LookVector); na frente dele há um lago, então o círculo fica
	-- à frente e para o lado da trilha de pedras (leste)
	local look = portal.CFrame.LookVector
	local east = -portal.CFrame.RightVector
	local front = CFrame.new(portal.Position - Vector3.new(0, portal.Size.Y / 2, 0) + look * 16 + east * 34)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(front.Position + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), params)
	local groundY = if hit then hit.Position.Y else front.Position.Y
	gateCF = CFrame.new(Vector3.new(front.Position.X, groundY, front.Position.Z)) * portal.CFrame.Rotation
	local c = Instance.new("Part")
	c.Name = "GroupCircle"
	c.Shape = Enum.PartType.Cylinder
	c.Size = Vector3.new(0.4, DungeonCfg.CircleRadius * 2, DungeonCfg.CircleRadius * 2)
	c.CFrame = CFrame.new(gateCF.Position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	c.Anchored = true
	c.CanCollide = false
	c.Material = Enum.Material.Neon
	c.Color = Color3.fromRGB(120, 90, 255)
	c.Transparency = 0.45
	c.Parent = gate
	circlePart = c
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(280, 60)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
	gui.MaxDistance = 90
	gui.Parent = c
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(230, 220, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = DungeonCfg.Name .. "\nPise no círculo para formar um grupo (1–4)"
	label.Parent = gui
	circleLabel = label
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "StartExpedition"
	pr.ActionText = "Iniciar expedição"
	pr.ObjectText = DungeonCfg.Name
	pr.HoldDuration = 0.6
	pr.MaxActivationDistance = DungeonCfg.CircleRadius + 4
	pr.RequiresLineOfSight = false
	pr.Parent = c
	pr.Triggered:Connect(function(p: Player)
		if forming and forming.leader == p.UserId then
			forming.startAt = os.clock()
		elseif forming then
			notify(p, "Só o líder do grupo pode iniciar antes do tempo.")
		end
	end)
end

local function circleTick()
	local c = circlePart
	if not c then
		return
	end
	local inside: { number } = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = hrpOf(p)
		if hrp and not runOf[p.UserId] then
			local flat = Vector3.new(hrp.Position.X - c.Position.X, 0, hrp.Position.Z - c.Position.Z)
			if flat.Magnitude <= DungeonCfg.CircleRadius and math.abs(hrp.Position.Y - c.Position.Y) < 12 then
				table.insert(inside, p.UserId)
			end
		end
	end
	local now = os.clock()
	if not forming then
		if #inside > 0 then
			forming = { leader = inside[1], members = { inside[1] }, startAt = now + DungeonCfg.JoinWindowSeconds }
			local p = Players:GetPlayerByUserId(inside[1])
			if p then
				notify(p, string.format("Você é o líder. Outros têm %d s para pisar no círculo. Use \"Iniciar expedição\" para começar antes.", DungeonCfg.JoinWindowSeconds))
			end
		else
			if circleLabel then
				circleLabel.Text = DungeonCfg.Name .. "\nPise no círculo para formar um grupo (1–4)"
			end
			return
		end
	end
	local f = forming :: { leader: number?, members: { number }, startAt: number }
	-- quem saiu do círculo sai do grupo; quem entrou (até 4) entra
	local still = {}
	for _, uid in ipairs(f.members) do
		if table.find(inside, uid) then
			table.insert(still, uid)
		end
	end
	for _, uid in ipairs(inside) do
		if not table.find(still, uid) and #still < DungeonCfg.MaxGroup then
			table.insert(still, uid)
			local p = Players:GetPlayerByUserId(uid)
			if p then
				notify(p, "Você entrou no grupo da expedição.")
			end
		end
	end
	f.members = still
	if #still == 0 then
		forming = nil
		return
	end
	if not table.find(still, f.leader :: number) then
		f.leader = still[1]
	end
	local left = math.max(0, math.ceil(f.startAt - now))
	if circleLabel then
		local leader = Players:GetPlayerByUserId(f.leader :: number)
		circleLabel.Text = string.format("Grupo %d/%d · líder %s\nComeça em %d s", #still, DungeonCfg.MaxGroup, leader and leader.DisplayName or "?", left)
	end
	if now >= f.startAt then
		forming = nil
		startRun(still)
	end
end

--------------------------------------------------------------------------
-- Morte, saída e volta
--------------------------------------------------------------------------
function DungeonService.InDungeon(player: Player): boolean
	return runOf[player.UserId] ~= nil
end

function DungeonService.Init()
	task.defer(setupGate)
	NetService.On("LeaveDungeon", function(player: Player)
		local id = runOf[player.UserId]
		local run = id and runs[id]
		if run then
			leave(run, player, "Você saiu da expedição.")
		end
	end)

	local function hookCharacter(player: Player, char: Model)
		local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
		if hum then
			hum.Died:Connect(function()
				local id = runOf[player.UserId]
				local run = id and runs[id]
				if run then
					eliminate(run, player)
					player:SetAttribute("DungeonEliminated", true)
				end
			end)
		end
		-- renasce no portão se acabou de ser eliminado; volta para a instância se reconectou
		task.delay(0.4, function()
			if player:GetAttribute("DungeonEliminated") then
				player:SetAttribute("DungeonEliminated", nil)
				teleport(player, gateSpawn())
				return
			end
			local id = runOf[player.UserId]
			local run = id and runs[id]
			if run then
				teleport(player, run.checkpoint)
			end
		end)
	end
	local function onPlayer(player: Player)
		-- voltou dentro dos 3 minutos?
		for _, run in pairs(runs) do
			local mem = run.members[player.UserId]
			if mem and mem.status == "Disconnected" and (mem.deadline or 0) > os.clock() then
				mem.status = "In"
				runOf[player.UserId] = run.id
				player:SetAttribute("InDungeon", run.id)
				notify(player, "Você voltou para a sua expedição.")
			end
		end
		player.CharacterAdded:Connect(function(char)
			hookCharacter(player, char)
		end)
		if player.Character then
			task.spawn(hookCharacter, player, player.Character)
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local id = runOf[player.UserId]
		local run = id and runs[id]
		if run then
			local mem = run.members[player.UserId]
			if mem and mem.status == "In" then
				mem.status = "Disconnected"
				mem.deadline = os.clock() + DungeonCfg.ReconnectGraceSeconds
			end
		end
		runOf[player.UserId] = nil
		if forming then
			local i = table.find(forming.members, player.UserId)
			if i then
				table.remove(forming.members, i)
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			pcall(circleTick)
			local now = os.clock()
			for _, run in pairs(runs) do
				-- runas: mostra a sequência quando o grupo chega na câmara
				if run.stage == "Chasm" then
					for _, p in ipairs(membersIn(run)) do
						local hrp = hrpOf(p)
						if hrp and (run.origin:PointToObjectSpace(hrp.Position)).Z < -255 then
							run.stage = "Runes"
							broadcast(run, "Pise nas placas na ordem em que as runas acendem.")
							lightRunes(run)
							break
						end
					end
				end
				-- fim: tempo depois do chefe, ou desconectados que não voltaram
				local anyIn = #membersIn(run) > 0
				local pending = false
				for _, mem in pairs(run.members) do
					if mem.status == "Disconnected" then
						if (mem.deadline or 0) > now then
							pending = true
						else
							mem.status = "Left"
						end
					end
				end
				if (not anyIn and not pending) or (run.clearedAt and now - run.clearedAt > DungeonCfg.AfterClearSeconds) then
					cleanup(run)
				end
			end
		end
	end)
end

return DungeonService
