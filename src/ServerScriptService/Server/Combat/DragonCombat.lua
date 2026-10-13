--!strict
-- Fase 5: o dragão companheiro no combate (GAME-DESIGN §10.5).
--  * Segue o dono e ataca sozinho quem atacar o dono (ou quem o dono atacar).
--  * F: atacar o alvo mirado · G: voltar para perto (ou chamar de volta depois de descansar)
--  * Z / X / C: poderes por estágio (Jovem / Pré-adulto / Adulto), com recarga.
--  * Derrotado: recua para a fazenda e descansa 60 s. Nunca morre.
--  * Ovo e Bebê não lutam (o Bebê acompanha, mas não é alvo).
-- Montado: o jogador não usa espada/arco; clique = mordida do dragão, Z/X/C = poderes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local Species = require(ReplicatedStorage.Shared.Config.Species)
local Growth = require(ReplicatedStorage.Shared.Config.Growth)
local Rarity = require(ReplicatedStorage.Shared.Config.Rarity)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local Server = ServerScriptService.Server
local NetService = require(Server.Services.NetService)
local CompanionService = require(Server.Dragons.CompanionService)
local DragonService = require(Server.Dragons.DragonService)
local CombatService = require(Server.Combat.CombatService)

local DragonCombat = {}

type DState = {
	player: Player,
	dragonId: string,
	model: Model,
	root: BasePart,
	size: number,
	canFight: boolean,
	stage: string,
	maxHealth: number,
	health: number,
	defense: number,
	dmgMult: number,
	powerMult: number,
	powers: { [string]: string },
	cooldowns: { [string]: number },
	lastBite: number,
	lastHurt: number,
	target: CombatService.Target?,
	shieldUntil: number,
	shieldMult: number,
	bar: Frame?,
	rarityTier: number,
	extra: number, -- mecânicas extras da raridade (0–3)
}

local states: { [Player]: DState } = {}
local savedHealth: { [string]: number } = {} -- vida por dragão (mantida entre reconstruções)

local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

local function source(st: DState): CombatService.Source
	return { kind = "Dragon", player = st.player, model = st.model, position = st.root.Position }
end

local function asTarget(st: DState): CombatService.Target
	return { kind = "Dragon", model = st.model, root = st.root, radius = math.max(3, st.size * 0.35), player = st.player, ref = st }
end

local function updateBar(st: DState)
	st.model:SetAttribute("Health", math.floor(st.health))
	st.model:SetAttribute("MaxHealth", st.maxHealth)
	if st.bar then
		st.bar.Size = UDim2.fromScale(math.clamp(st.health / st.maxHealth, 0, 1), 1)
	end
end

local function makeBar(st: DState)
	local tag = st.model:FindFirstChild("NameTag")
	if not tag or not tag:IsA("BillboardGui") then
		return
	end
	local back = Instance.new("Frame")
	back.Name = "HealthBack"
	back.AnchorPoint = Vector2.new(0.5, 0)
	back.Position = UDim2.new(0.5, 0, 1, 2)
	back.Size = UDim2.new(0.6, 0, 0, 7)
	back.BackgroundColor3 = Color3.fromRGB(20, 26, 20)
	back.BorderSizePixel = 0
	back.Parent = tag
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 210, 110)
	fill.BorderSizePixel = 0
	fill.Parent = back
	st.bar = fill
end

local function onAttached(player: Player, model: Model, dragon: { [string]: any })
	local root = model.PrimaryPart
	if not root then
		return
	end
	local stageCfg = Combat.DragonStage[dragon.Stage]
	local role = Combat.Roles[Species[dragon.Species].Role] or { Health = 1, Damage = 1, Defense = 0 }
	local _, ext = model:GetBoundingBox()
	local st: DState = {
		player = player,
		dragonId = dragon.Id,
		model = model,
		root = root,
		size = math.max(ext.X, ext.Z),
		canFight = stageCfg ~= nil,
		stage = dragon.Stage,
		maxHealth = if stageCfg then math.floor(stageCfg.Health * role.Health) else 1,
		health = 1,
		defense = role.Defense,
		dmgMult = role.Damage,
		powerMult = (if stageCfg then stageCfg.PowerMult else 1) * role.Damage * (Combat.RarityPowerBonus[dragon.Rarity] or 1),
		powers = Combat.SpeciesPowers[dragon.Species] or {},
		cooldowns = {},
		lastBite = 0,
		lastHurt = 0,
		target = nil,
		shieldUntil = 0,
		shieldMult = 1,
		bar = nil,
		rarityTier = (Rarity.Defs[dragon.Rarity] or Rarity.Defs.Common).Tier,
		extra = (Rarity.Defs[dragon.Rarity] or Rarity.Defs.Common).ExtraMechanics,
	}
	st.health = math.min(savedHealth[dragon.Id] or st.maxHealth, st.maxHealth)
	states[player] = st
	if st.canFight then
		makeBar(st)
		updateBar(st)
	end
	-- avisa o cliente quais poderes estão liberados (para a barra de poderes)
	local unlocked = {}
	for slot, stage in pairs(Combat.PowerSlotStage) do
		if st.canFight and Growth.StageIndex(dragon.Stage) >= Growth.StageIndex(stage) then
			local id = st.powers[slot]
			local def = id and Combat.Powers[id]
			if def then
				unlocked[slot] = { Id = def.Id, Name = def.Name, Cooldown = def.Cooldown }
			end
		end
	end
	NetService.Fire(player, "DragonPowers", unlocked, st.canFight)
end

local function onDetached(player: Player)
	local st = states[player]
	if st then
		savedHealth[st.dragonId] = st.health
	end
	states[player] = nil
	NetService.Fire(player, "DragonPowers", {}, false)
end

--------------------------------------------------------------------------
-- Dano no dragão
--------------------------------------------------------------------------
local function defeated(st: DState)
	st.model:SetAttribute("Defeated", true)
	CombatService.Fx("Death", st.root.Position, { Pos = st.root.Position, Dragon = true })
	savedHealth[st.dragonId] = st.maxHealth -- volta descansado
	states[st.player] = nil
	DragonService.Rest(st.player, Combat.DragonRestSeconds)
end

local function damageHandler(target: CombatService.Target, amount: number, src: CombatService.Source, _opts: { [string]: any }?): number
	local st = target.ref :: DState
	if not st or states[st.player] ~= st or not st.canFight then
		return 0
	end
	local mult = 1 - st.defense
	if os.clock() < st.shieldUntil then
		mult *= st.shieldMult
	end
	local dmg = amount * mult
	st.health -= dmg
	st.lastHurt = os.clock()
	CombatService.Fx("Hit", st.root.Position, { Pos = st.root.Position + Vector3.new(0, st.size * 0.4, 0), Amount = math.floor(dmg + 0.5), Color = Color3.fromRGB(255, 140, 90) })
	-- revida quem bateu nele
	if src.kind == "Enemy" and src.model and not st.target then
		for _, t in ipairs(CombatService.TargetsNear(src.position, 4)) do
			if t.model == src.model then
				st.target = t
				break
			end
		end
	end
	updateBar(st)
	if st.health <= 0 then
		defeated(st)
	end
	return dmg
end

local function provider(center: Vector3, radius: number): { CombatService.Target }
	local out = {}
	for _, st in pairs(states) do
		if st.canFight and st.model.Parent and st.model:GetAttribute("Mode") ~= "Burrow" and (st.root.Position - center).Magnitude <= radius + st.size * 0.5 then
			table.insert(out, asTarget(st))
		end
	end
	return out
end

--------------------------------------------------------------------------
-- Ataques e poderes
--------------------------------------------------------------------------
local function targetValid(t: CombatService.Target?, st: DState?): boolean
	if not t or not t.model.Parent then
		return false
	end
	if t.kind == "Enemy" then
		local h = t.model:GetAttribute("Health")
		return type(h) == "number" and h > 0
	end
	-- jogadores e dragões de outros: só quando o PvP permitir (zonas, proteções)
	if not st then
		return false
	end
	if t.kind == "Player" then
		local hum = t.model:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return false
		end
	elseif t.model:GetAttribute("Defeated") then
		return false
	end
	return CombatService.CanHurt(source(st), t)
end

local function bite(st: DState, t: CombatService.Target)
	if st.model:GetAttribute("Mode") == "Burrow" then
		return
	end
	local now = os.clock()
	if now - st.lastBite < Combat.DragonBite.Interval then
		return
	end
	st.lastBite = now
	local stageCfg = Combat.DragonStage[st.stage]
	local dmg = (if stageCfg then stageCfg.Bite else 10) * st.dmgMult
	CombatService.Fx("Bite", st.root.Position, { Pos = t.root.Position })
	CombatService.Damage(source(st), t, dmg, { Knockback = (t.root.Position - st.root.Position).Unit * 12 })
end

local function inCone(origin: Vector3, dir: Vector3, p: Vector3, range: number, deg: number): boolean
	local to = p - origin
	local d = to.Magnitude
	if d > range then
		return false
	end
	if d < 1 then
		return true
	end
	return math.deg(math.acos(math.clamp(to.Unit:Dot(dir), -1, 1))) <= deg / 2
end

local function segDist(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local function usePower(st: DState, slot: string, aim: Vector3?)
	local player = st.player
	if st.model:GetAttribute("Mode") == "Burrow" then
		return -- por baixo da terra não usa poderes (sai do chão para atacar)
	end
	if not st.canFight then
		notify(player, "Seu dragão ainda é um bebê: ele não luta.")
		return
	end
	local need = Combat.PowerSlotStage[slot]
	if Growth.StageIndex(st.stage) < Growth.StageIndex(need) then
		notify(player, "Esse poder libera quando o dragão for " .. Growth.StageNames[need] .. ".")
		return
	end
	local id = st.powers[slot]
	local def = id and Combat.Powers[id]
	if not def then
		return
	end
	local now = os.clock()
	if now < (st.cooldowns[slot] or 0) then
		return
	end
	-- mecânicas extras da raridade: 1 = área maior · 2 = recarga menor · 3 = deixa os alvos lentos
	local radiusMult = if st.extra >= 1 then 1.15 else 1
	local cooldown = def.Cooldown * (if st.extra >= 2 then 0.9 else 1)
	st.cooldowns[slot] = now + cooldown
	NetService.Fire(player, "SkillUsed", "Dragon" .. slot, cooldown)
	def = table.clone(def) :: any
	def.Radius *= radiusMult
	if st.extra >= 3 and not def.Slow and def.Kind ~= "Heal" and def.Kind ~= "Self" then
		def.Slow = 0.3
		def.Duration = 2
	end

	local origin = st.root.Position + Vector3.new(0, st.size * 0.35, 0)
	local point = if typeof(aim) == "Vector3" then aim :: Vector3 else origin + st.root.CFrame.LookVector * 30
	local flatTo = Vector3.new(point.X - origin.X, 0, point.Z - origin.Z)
	local dir = if flatTo.Magnitude > 1 then flatTo.Unit else Vector3.new(st.root.CFrame.LookVector.X, 0, st.root.CFrame.LookVector.Z).Unit
	-- alcance máximo do poder (o servidor limita o ponto mirado)
	if def.Range > 0 and (point - origin).Magnitude > def.Range then
		point = origin + (point - origin).Unit * def.Range
	end
	CompanionService.SetGoal(player, nil, point)
	local dmg = def.Damage * st.powerMult
	local src = source(st)
	local opts = { Knockback = nil :: Vector3?, Slow = def.Slow, Duration = def.Duration }

	local hits = 0
	local function hitTargets(center: Vector3, radius: number, filter: (CombatService.Target) -> boolean)
		for _, t in ipairs(CombatService.TargetsNear(center, radius)) do
			if t.model ~= st.model and t.model ~= player.Character and filter(t) then
				if def.Knockback then
					local away = t.root.Position - st.root.Position
					opts.Knockback = (if away.Magnitude > 0.1 then away.Unit else dir) * def.Knockback
				end
				if CombatService.Damage(src, t, dmg, opts) > 0 then
					hits += 1
				end
			end
		end
	end

	if def.Kind == "Projectile" then
		-- bola que voa até o ponto (ou até bater no cenário) e explode
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { st.model, player.Character :: Instance }
		local hit = workspace:Raycast(origin, point - origin, params)
		local impact = if hit then hit.Position else point
		local travel = (impact - origin).Magnitude / 120
		CombatService.Fx("Power", origin, { Tier = st.rarityTier, Id = def.Id, Kind = def.Kind, Element = def.Element, From = origin, To = impact, Radius = def.Radius, Time = travel })
		task.delay(travel, function()
			hitTargets(impact, def.Radius, function(t)
				return (t.root.Position - impact).Magnitude <= def.Radius + t.radius
			end)
		end)
	elseif def.Kind == "Cone" then
		CombatService.Fx("Power", origin, { Tier = st.rarityTier, Id = def.Id, Kind = def.Kind, Element = def.Element, From = origin, Dir = dir, Range = def.Range, Angle = def.Radius })
		hitTargets(origin, def.Range, function(t)
			return inCone(origin, dir, t.root.Position, def.Range + t.radius, def.Radius)
		end)
	elseif def.Kind == "Line" then
		local to = origin + dir * def.Range
		CombatService.Fx("Power", origin, { Tier = st.rarityTier, Id = def.Id, Kind = def.Kind, Element = def.Element, From = origin, To = to, Radius = def.Radius })
		hitTargets((origin + to) / 2, def.Range / 2 + def.Radius, function(t)
			return segDist(t.root.Position, origin, to) <= def.Radius + t.radius
		end)
	elseif def.Kind == "Area" then
		local center = if def.Range > 0 then point else st.root.Position
		CombatService.Fx("Power", center, { Tier = st.rarityTier, Id = def.Id, Kind = def.Kind, Element = def.Element, From = origin, To = center, Radius = def.Radius })
		task.delay(0.35, function()
			hitTargets(center, def.Radius, function(t)
				return (t.root.Position - center).Magnitude <= def.Radius + t.radius
			end)
		end)
	elseif def.Kind == "Heal" then
		local center = st.root.Position
		CombatService.Fx("Power", center, { Tier = st.rarityTier, Id = def.Id, Kind = def.Kind, Element = def.Element, To = center, Radius = def.Radius, Time = def.Duration })
		local ticks = math.max(1, math.floor(def.Duration or 1))
		local per = (def.Heal or 0) * st.powerMult / ticks
		task.spawn(function()
			for _ = 1, ticks do
				-- cura jogadores e dragões por perto (aliados: sem PvP, todos são aliados)
				for _, p in ipairs(Players:GetPlayers()) do
					local char = p.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hum and hrp and hum.Health > 0 and (hrp.Position - center).Magnitude <= def.Radius then
						hum.Health = math.min(hum.MaxHealth, hum.Health + per)
					end
				end
				for _, other in pairs(states) do
					if other.canFight and (other.root.Position - center).Magnitude <= def.Radius then
						other.health = math.min(other.maxHealth, other.health + per * 2)
						updateBar(other)
					end
				end
				task.wait(1)
			end
		end)
	elseif def.Kind == "Self" then
		st.shieldUntil = now + (def.Duration or 5)
		st.shieldMult = 1 - (def.Shield or 0.5)
		CombatService.Fx("Power", st.root.Position, { Tier = st.rarityTier, Id = def.Id, Kind = def.Kind, Element = def.Element, To = st.root.Position, Radius = st.size * 0.6, Time = def.Duration })
	end
end

local function nearestEnemy(center: Vector3, radius: number, st: DState?): CombatService.Target?
	local best, bestD = nil, radius
	for _, t in ipairs(CombatService.TargetsNear(center, radius)) do
		if (st == nil or (t.model ~= st.model and t.player ~= st.player)) and targetValid(t, st) then
			local d = (t.root.Position - center).Magnitude
			if d < bestD then
				best, bestD = t, d
			end
		end
	end
	return best
end

local function onCommand(player: Player, cmd: string, aim: Vector3?)
	local st = states[player]
	if cmd == "Recall" then
		if st then
			st.target = nil
			CompanionService.SetGoal(player, nil, nil)
			notify(player, "Seu dragão voltou para perto de você.")
		elseif DragonService.IsCompanionHome(player) then
			DragonService.ToggleCompanion(player)
		end
		return
	end
	if not st or not st.model.Parent then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	-- o ponto mirado precisa ser plausível (perto do jogador)
	if typeof(aim) == "Vector3" and ((aim :: Vector3) - hrp.Position).Magnitude > Combat.CommandRange + 60 then
		aim = nil
	end
	if cmd == "Attack" then
		if not st.canFight then
			notify(player, "Seu dragão ainda é um bebê: ele não luta.")
			return
		end
		if CompanionService.IsMounted(player) then
			-- montado: mordida no inimigo mais próximo à frente
			local front = st.root.Position + st.root.CFrame.LookVector * (st.size * 0.4)
			local t = nearestEnemy(front, Combat.DragonBite.Range + st.size * 0.4, st)
			if t then
				bite(st, t)
			end
			return
		end
		local center = if aim then aim :: Vector3 else hrp.Position + hrp.CFrame.LookVector * 20
		local t = nearestEnemy(center, 30, st)
		if t and (t.root.Position - hrp.Position).Magnitude <= Combat.CommandRange then
			st.target = t
		end
	elseif cmd == "Z" or cmd == "X" or cmd == "C" then
		usePower(st, cmd, aim)
	end
end

--------------------------------------------------------------------------
-- Ciclo
--------------------------------------------------------------------------
local function tick(st: DState, now: number)
	if not st.model.Parent then
		states[st.player] = nil
		return
	end
	if not st.canFight then
		return
	end
	-- recupera vida fora de combate
	if now - st.lastHurt > 8 and st.health < st.maxHealth then
		st.health = math.min(st.maxHealth, st.health + st.maxHealth * 0.02 * 0.2)
		updateBar(st)
	end
	if CompanionService.IsMounted(st.player) then
		return
	end
	local char = st.player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local t = st.target
	if not targetValid(t, st) or not hrp or ((t :: CombatService.Target).root.Position - hrp.Position).Magnitude > Combat.DragonBite.LeashFromOwner then
		if st.target then
			st.target = nil
			CompanionService.SetGoal(st.player, nil, nil)
		end
		return
	end
	local tt = t :: CombatService.Target
	local tp = tt.root.Position
	local rp = st.root.Position
	local flat = Vector3.new(tp.X - rp.X, 0, tp.Z - rp.Z)
	local reach = Combat.DragonBite.Range + tt.radius + st.size * 0.3
	if flat.Magnitude > reach * 0.8 then
		local stop = tp - (if flat.Magnitude > 0.1 then flat.Unit else Vector3.zAxis) * (reach * 0.6)
		CompanionService.SetGoal(st.player, stop, tp)
	else
		CompanionService.SetGoal(st.player, rp, tp)
	end
	if flat.Magnitude <= reach then
		bite(st, tt)
	end
end

function DragonCombat.Init()
	CombatService.RegisterDragons(provider, damageHandler)
	CompanionService.Attached:Connect(onAttached)
	-- Wyrm saindo do chão: golpe em área em quem estiver por perto
	CompanionService.ModeChanged:Connect(function(player: Player, old: string, new: string)
		local st = states[player]
		if not st or not st.canFight or old ~= "Burrow" or new ~= "Ground" then
			return
		end
		local stageCfg = Combat.DragonStage[st.stage]
		local dmg = (if stageCfg then stageCfg.Bite else 12) * st.dmgMult * Rules.Mount.BurrowSurfaceDamage
		local center = st.root.Position
		CombatService.Fx("Power", center, { Kind = "Area", Element = "Earth", To = center, Radius = 14 })
		for _, t in ipairs(CombatService.TargetsNear(center, 14)) do
			if t.model ~= st.model and t.model ~= player.Character then
				CombatService.Damage(source(st), t, dmg, { Knockback = Vector3.new(0, 45, 0) })
			end
		end
	end)
	CompanionService.Detached:Connect(onDetached)
	NetService.On("DragonCommand", onCommand)

	-- ajuda automática: quem ataca o dono vira alvo; quem o dono ataca também
	CombatService.OnPlayerHurt(function(victim: Player, src: CombatService.Source)
		local st = states[victim]
		if st and st.canFight and not targetValid(st.target, st) and src.model then
			for _, t in ipairs(CombatService.TargetsNear(src.position, 4)) do
				if t.model == src.model then
					st.target = t
					break
				end
			end
		end
	end)
	CombatService.OnPlayerAttack(function(attacker: Player, target: CombatService.Target)
		local st = states[attacker]
		if st and st.canFight and not targetValid(st.target, st) and target.model ~= st.model then
			st.target = target
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.2)
			local now = os.clock()
			for _, st in pairs(states) do
				local ok, err = pcall(tick, st, now)
				if not ok then
					warn("[DragonCombat] " .. tostring(err))
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return DragonCombat
