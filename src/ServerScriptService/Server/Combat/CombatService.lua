--!strict
-- Fase 5: núcleo do combate (servidor autoritativo).
--  * Dano entre jogadores, inimigos e dragões passa por CombatService.Damage.
--  * Espada (combo de 3, Golpe Giratório, bloqueio) e arco (tiro carregado, Flecha Tripla,
--    flechas finitas) são calculados aqui: o cliente só manda a ação e a direção da mira.
--  * Esquiva: o cliente faz o movimento; o servidor dá a invulnerabilidade curta e a recarga.
--  * PvP fica desligado até a Fase 9 (CombatService.SetPvPRule).
-- Inimigos e dragões se registram por ganchos (sem dependência circular).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local Server = ServerScriptService.Server
local NetService = require(Server.Services.NetService)
local InventoryService = require(Server.Services.InventoryService)
local CompanionService = require(Server.Dragons.CompanionService)

local CombatService = {}

-- Alvo genérico: Player (personagem), Enemy ou Dragon (companheiro de alguém).
export type Target = {
	kind: string,
	model: Model,
	root: BasePart,
	radius: number,
	player: Player?, -- dono (Player: o próprio; Dragon: o dono; Enemy: nil)
	ref: any, -- dados internos do módulo dono do alvo
}

export type Source = {
	kind: string, -- "Player" | "Enemy" | "Dragon"
	player: Player?, -- jogador responsável (o próprio ou o dono do dragão)
	model: Model?,
	position: Vector3,
}

type PlayerState = {
	weapon: string,
	combo: number,
	lastSwing: number,
	spinReadyAt: number,
	lastShot: number,
	tripleReadyAt: number,
	blocking: boolean,
	dodgeReadyAt: number,
	invulnUntil: number,
	lastCombat: number,
}

local states: { [Player]: PlayerState } = {}

-- ganchos registrados por EnemyService / DragonCombat
local enemyProvider: ((center: Vector3, radius: number) -> { Target })? = nil
local dragonProvider: ((center: Vector3, radius: number) -> { Target })? = nil
local damageHandlers: { [string]: (target: Target, amount: number, source: Source, opts: { [string]: any }?) -> number } = {}
local hurtListeners: { (victim: Player, source: Source) -> () } = {}
local attackListeners: { (attacker: Player, target: Target) -> () } = {}
local lastHit: { [Player]: { by: Player?, at: number } } = {}
local pvpRule: (a: Player, b: Player) -> boolean = function()
	return false
end

local FX_RANGE = 450

--------------------------------------------------------------------------
-- Utilidades
--------------------------------------------------------------------------
local function charParts(player: Player): (Model?, Humanoid?, BasePart?)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not hum or not hrp or hum.Health <= 0 then
		return nil, nil, nil
	end
	return char, hum, hrp
end

local function state(player: Player): PlayerState
	local s = states[player]
	if not s then
		s = {
			weapon = "Sword",
			combo = 0,
			lastSwing = 0,
			spinReadyAt = 0,
			lastShot = 0,
			tripleReadyAt = 0,
			blocking = false,
			dodgeReadyAt = 0,
			invulnUntil = 0,
			lastCombat = 0,
		}
		states[player] = s
	end
	return s
end

-- Envia um efeito visual para quem está perto (os clientes desenham; não muda nada no jogo).
function CombatService.Fx(kind: string, at: Vector3, payload: { [string]: any })
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and (hrp.Position - at).Magnitude <= FX_RANGE then
			NetService.Fire(p, "Fx", kind, payload)
		end
	end
end

function CombatService.SetPvPRule(fn: (a: Player, b: Player) -> boolean)
	pvpRule = fn
end

function CombatService.RegisterEnemies(provider: (Vector3, number) -> { Target }, handler: (Target, number, Source, { [string]: any }?) -> number)
	enemyProvider = provider
	damageHandlers.Enemy = handler
end

function CombatService.RegisterDragons(provider: (Vector3, number) -> { Target }, handler: (Target, number, Source, { [string]: any }?) -> number)
	dragonProvider = provider
	damageHandlers.Dragon = handler
end

function CombatService.OnPlayerHurt(fn: (Player, Source) -> ())
	table.insert(hurtListeners, fn)
end

function CombatService.OnPlayerAttack(fn: (Player, Target) -> ())
	table.insert(attackListeners, fn)
end

-- Último jogador que feriu `victim` nos últimos `window` segundos (para PvP).
function CombatService.LastAttacker(victim: Player, window: number): Player?
	local h = lastHit[victim]
	if h and h.by and h.by.Parent and os.clock() - h.at <= window then
		return h.by
	end
	return nil
end

function CombatService.PlayerTarget(player: Player): Target?
	local char, _, hrp = charParts(player)
	if not char or not hrp or char:GetAttribute("Burrowed") then
		return nil -- por baixo da terra ninguém acerta
	end
	return { kind = "Player", model = char, root = hrp, radius = 2, player = player, ref = player }
end

-- Pode `source` ferir `target`? (amigos nunca; PvP só quando a regra da Fase 9 permitir)
function CombatService.CanHurt(source: Source, target: Target): boolean
	if source.kind == "Enemy" then
		return target.kind ~= "Enemy"
	end
	if target.kind == "Enemy" then
		return true
	end
	local a, b = source.player, target.player
	if not a or not b or a == b then
		return false
	end
	return pvpRule(a, b)
end

-- Todos os alvos perto de um ponto (inimigos, jogadores, dragões).
function CombatService.TargetsNear(center: Vector3, radius: number): { Target }
	local out: { Target } = {}
	if enemyProvider then
		for _, t in ipairs(enemyProvider(center, radius)) do
			table.insert(out, t)
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local t = CombatService.PlayerTarget(p)
		if t and (t.root.Position - center).Magnitude <= radius + t.radius then
			table.insert(out, t)
		end
	end
	if dragonProvider then
		for _, t in ipairs(dragonProvider(center, radius)) do
			table.insert(out, t)
		end
	end
	return out
end

function CombatService.InCombat(player: Player): boolean
	local s = states[player]
	return s ~= nil and os.clock() - s.lastCombat < Combat.Player.OutOfCombatSeconds
end

--------------------------------------------------------------------------
-- Dano
--------------------------------------------------------------------------
local function damagePlayer(target: Target, amount: number, source: Source): number
	local victim = target.player :: Player
	local _, hum, hrp = charParts(victim)
	if not hum or not hrp then
		return 0
	end
	local s = state(victim)
	local now = os.clock()
	if now < s.invulnUntil then
		CombatService.Fx("Hit", hrp.Position, { Pos = hrp.Position, Text = "Esquivou", Color = Color3.fromRGB(200, 220, 255) })
		return 0
	end
	if s.blocking and s.weapon == "Sword" then
		local to = source.position - hrp.Position
		local flat = Vector3.new(to.X, 0, to.Z)
		if flat.Magnitude > 0.1 then
			local look = hrp.CFrame.LookVector
			local ang = math.deg(math.acos(math.clamp(flat.Unit:Dot(Vector3.new(look.X, 0, look.Z).Unit), -1, 1)))
			if ang <= Combat.Sword.BlockArcDegrees / 2 then
				amount *= 1 - Combat.Sword.BlockReduction
			end
		end
	end
	amount = math.max(0, amount)
	hum:TakeDamage(amount)
	s.lastCombat = now
	CombatService.Fx("Hit", hrp.Position, { Pos = hrp.Position, Amount = math.floor(amount + 0.5), Color = Color3.fromRGB(255, 90, 80) })
	if source.player and source.player ~= victim then
		lastHit[victim] = { by = source.player, at = now }
	end
	for _, fn in ipairs(hurtListeners) do
		task.spawn(fn, victim, source)
	end
	return amount
end

-- Aplica dano e devolve quanto foi causado. opts: Knockback (Vector3), Slow (0..1), Duration.
function CombatService.Damage(source: Source, target: Target, amount: number, opts: { [string]: any }?): number
	if amount <= 0 or not CombatService.CanHurt(source, target) then
		return 0
	end
	if source.kind == "Player" and source.player then
		state(source.player).lastCombat = os.clock()
		for _, fn in ipairs(attackListeners) do
			task.spawn(fn, source.player, target)
		end
	end
	if target.kind == "Player" then
		return damagePlayer(target, amount, source)
	end
	local handler = damageHandlers[target.kind]
	if handler then
		return handler(target, amount, source, opts)
	end
	return 0
end

--------------------------------------------------------------------------
-- Armas do jogador
--------------------------------------------------------------------------
local function playerSource(player: Player, hrp: BasePart): Source
	return { kind = "Player", player = player, model = player.Character, position = hrp.Position }
end

local function inArc(hrp: BasePart, pos: Vector3, arcDeg: number): boolean
	local to = pos - hrp.Position
	local flat = Vector3.new(to.X, 0, to.Z)
	if flat.Magnitude < 0.5 then
		return true
	end
	local look = hrp.CFrame.LookVector
	local f = Vector3.new(look.X, 0, look.Z).Unit
	return math.deg(math.acos(math.clamp(flat.Unit:Dot(f), -1, 1))) <= arcDeg / 2
end

local function swing(player: Player, s: PlayerState, hrp: BasePart)
	local now = os.clock()
	if now - s.lastSwing < Combat.Sword.SwingInterval then
		return
	end
	if now - s.lastSwing > Combat.Sword.ComboWindow then
		s.combo = 0
	end
	s.combo = s.combo % 3 + 1
	s.lastSwing = now
	local dmg = Combat.Sword.ComboDamage[s.combo]
	local src = playerSource(player, hrp)
	for _, t in ipairs(CombatService.TargetsNear(hrp.Position, Combat.Sword.Range + 4)) do
		if t.model ~= player.Character and (t.root.Position - hrp.Position).Magnitude <= Combat.Sword.Range + t.radius and inArc(hrp, t.root.Position, Combat.Sword.ArcDegrees) then
			CombatService.Damage(src, t, dmg, { Knockback = hrp.CFrame.LookVector * (if s.combo == 3 then 30 else 8) })
		end
	end
	CombatService.Fx("Slash", hrp.Position, { CF = hrp.CFrame, Combo = s.combo, Player = player })
end

local function spin(player: Player, s: PlayerState, hrp: BasePart)
	local now = os.clock()
	if now < s.spinReadyAt then
		return
	end
	s.spinReadyAt = now + Combat.Sword.Spin.Cooldown
	s.lastSwing = now
	local src = playerSource(player, hrp)
	for _, t in ipairs(CombatService.TargetsNear(hrp.Position, Combat.Sword.Spin.Radius + 4)) do
		if t.model ~= player.Character and (t.root.Position - hrp.Position).Magnitude <= Combat.Sword.Spin.Radius + t.radius then
			local away = t.root.Position - hrp.Position
			CombatService.Damage(src, t, Combat.Sword.Spin.Damage, { Knockback = (if away.Magnitude > 0.1 then away.Unit else Vector3.zero) * 35 })
		end
	end
	CombatService.Fx("Spin", hrp.Position, { Pos = hrp.Position, Radius = Combat.Sword.Spin.Radius, Player = player })
	NetService.Fire(player, "SkillUsed", "Spin", Combat.Sword.Spin.Cooldown)
end

-- Flecha simulada no servidor (passos pequenos, raio contra o cenário, distância contra alvos).
local shotParams = RaycastParams.new()
shotParams.FilterType = Enum.RaycastFilterType.Exclude
shotParams.IgnoreWater = true

local function segmentDistance(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then
		return (p - a).Magnitude
	end
	local t = math.clamp((p - a):Dot(ab) / len2, 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local function fireArrow(player: Player, origin: Vector3, dir: Vector3, damage: number)
	local B = Combat.Bow
	local vel = dir * B.ArrowSpeed
	local pos = origin
	local travelled = 0
	local filter: { Instance } = {}
	if player.Character then
		table.insert(filter, player.Character)
	end
	local comp = CompanionService.Get(player)
	if comp then
		table.insert(filter, comp)
	end
	local gf = workspace:FindFirstChild("Gatherables")
	if gf then
		table.insert(filter, gf)
	end
	shotParams.FilterDescendantsInstances = filter
	local src: Source = { kind = "Player", player = player, model = player.Character, position = origin }
	CombatService.Fx("Arrow", origin, { Origin = origin, Velocity = vel, Gravity = B.Gravity, Player = player })
	local conn: RBXScriptConnection? = nil
	conn = RunService.Heartbeat:Connect(function(dt)
		local nextVel = vel - Vector3.new(0, B.Gravity * dt, 0)
		local step = (vel + nextVel) * 0.5 * dt
		local nextPos = pos + step
		-- alvos ao longo do segmento
		local mid = (pos + nextPos) / 2
		for _, t in ipairs(CombatService.TargetsNear(mid, step.Magnitude / 2 + 6)) do
			if t.model ~= player.Character and segmentDistance(t.root.Position, pos, nextPos) <= t.radius + 1.2 then
				if CombatService.CanHurt(src, t) then
					src.position = pos
					CombatService.Damage(src, t, damage, { Knockback = vel.Unit * 6 })
					if conn then
						conn:Disconnect()
					end
					return
				end
			end
		end
		local hit = workspace:Raycast(pos, step, shotParams)
		travelled += step.Magnitude
		if hit or travelled > B.Range then
			if conn then
				conn:Disconnect()
			end
			return
		end
		pos = nextPos
		vel = nextVel
	end)
end

local function validAim(aim: Vector3?): Vector3?
	if typeof(aim) ~= "Vector3" then
		return nil
	end
	local a = aim :: Vector3
	if a.Magnitude < 0.5 or a.Magnitude > 1.5 or a ~= a then
		return nil
	end
	return a.Unit
end

local function bowShot(player: Player, s: PlayerState, hrp: BasePart, aim: Vector3?, charge: number?)
	local dir = validAim(aim)
	local now = os.clock()
	if not dir or now - s.lastShot < Combat.Bow.ShotInterval then
		return
	end
	if not InventoryService.Remove(player, "Arrow", 1) then
		NetService.Fire(player, "Notify", "Sem flechas! Compre no Tobias ou derrote inimigos.", "warning")
		return
	end
	s.lastShot = now
	local c = math.clamp(charge or 0, 0, 1)
	local dmg = Combat.Bow.MinDamage + (Combat.Bow.MaxDamage - Combat.Bow.MinDamage) * c
	local head = (player.Character :: Model):FindFirstChild("Head") :: BasePart?
	local origin = (if head then head.Position else hrp.Position + Vector3.new(0, 1.5, 0)) + dir * 2
	fireArrow(player, origin, dir, dmg)
end

local function tripleShot(player: Player, s: PlayerState, hrp: BasePart, aim: Vector3?)
	local dir = validAim(aim)
	local now = os.clock()
	local T = Combat.Bow.Triple
	if not dir or now < s.tripleReadyAt then
		return
	end
	if not InventoryService.Remove(player, "Arrow", T.Arrows) then
		NetService.Fire(player, "Notify", string.format("A Flecha Tripla precisa de %d flechas.", T.Arrows), "warning")
		return
	end
	s.tripleReadyAt = now + T.Cooldown
	s.lastShot = now
	local head = (player.Character :: Model):FindFirstChild("Head") :: BasePart?
	local origin = (if head then head.Position else hrp.Position) + dir * 2
	for _, deg in ipairs({ -T.SpreadDegrees, 0, T.SpreadDegrees }) do
		local d = (CFrame.fromAxisAngle(Vector3.yAxis, math.rad(deg)) * dir)
		fireArrow(player, origin, d, T.Damage)
	end
	NetService.Fire(player, "SkillUsed", "Triple", T.Cooldown)
end

-- Arma visual na mão. A peça "Grip" fica presa por um Motor6D ("WeaponGrip"): as animações
-- (no cliente) giram o encaixe para a lâmina seguir o braço e o arco ficar em pé ao mirar.
local function setWeaponVisual(player: Player, weapon: string)
	local char = player.Character
	if not char then
		return
	end
	char:SetAttribute("Weapon", weapon)
	char:SetAttribute("BowDraw", false)
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local lhand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
	local old = char:FindFirstChild("WeaponModel")
	if old then
		old:Destroy()
	end
	if not hand or not hand:IsA("BasePart") or not lhand or not lhand:IsA("BasePart") then
		return
	end
	local m = Instance.new("Model")
	m.Name = "WeaponModel"
	local holder = if weapon == "Sword" then hand else lhand :: BasePart
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Size = Vector3.new(0.3, 0.3, 0.3)
	grip.Transparency = 1
	grip.CanCollide = false
	grip.CanQuery = false
	grip.CanTouch = false
	grip.Massless = true
	grip.CFrame = holder.CFrame * CFrame.new(0, -0.55, 0)
	grip.Parent = m
	local mot = Instance.new("Motor6D")
	mot.Name = "WeaponGrip"
	mot.Part0 = holder
	mot.Part1 = grip
	mot.C0 = CFrame.new(0, -0.55, 0)
	mot.Parent = grip
	local function piece(props: { [string]: any }, offset: CFrame): BasePart
		local p = Instance.new("Part")
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		for k, v in pairs(props) do
			(p :: any)[k] = v
		end
		p.CFrame = grip.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = grip
		w.Part1 = p
		w.Parent = p
		p.Parent = m
		return p
	end
	if weapon == "Sword" then
		-- lâmina para a frente da mão (o encaixe gira nos golpes para seguir o braço)
		piece({ Name = "Grip2", Size = Vector3.new(0.28, 0.28, 1.1), Material = Enum.Material.Leather, Color = Color3.fromRGB(70, 46, 30) }, CFrame.new(0, 0, 0))
		piece({ Name = "Pommel", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), Material = Enum.Material.Metal, Color = Color3.fromRGB(190, 150, 70) }, CFrame.new(0, 0, 0.65))
		piece({ Name = "Guard", Size = Vector3.new(1.7, 0.28, 0.32), Material = Enum.Material.Metal, Color = Color3.fromRGB(190, 150, 70) }, CFrame.new(0, 0, -0.6))
		piece({ Name = "Blade", Size = Vector3.new(0.5, 0.12, 4.2), Material = Enum.Material.Metal, Color = Color3.fromRGB(205, 210, 218), Reflectance = 0.15 }, CFrame.new(0, 0, -2.8))
		piece({ Name = "Edge", Size = Vector3.new(0.12, 0.13, 4.0), Material = Enum.Material.Glass, Color = Color3.fromRGB(235, 240, 250), Transparency = 0.2 }, CFrame.new(0, 0, -2.9))
		local tip = piece({ Name = "Point", Size = Vector3.new(0.5, 0.12, 0.5), Material = Enum.Material.Metal, Color = Color3.fromRGB(205, 210, 218) }, CFrame.new(0, 0, -5) * CFrame.Angles(0, math.rad(45), 0))
		tip.Size = Vector3.new(0.35, 0.12, 0.35)
	else
		-- arco curvo (em pé na mão) + corda
		local segs = 7
		local h, depth = 4.8, 0.9
		for i = 0, segs - 1 do
			local t0, t1 = i / segs, (i + 1) / segs
			local function pt(t: number): Vector3
				local y = (t - 0.5) * h
				local z = -depth * (2 * t - 1) ^ 2 -- meio na mão, pontas para o arqueiro
				return Vector3.new(0, y, z)
			end
			local a, b = pt(t0), pt(t1)
			local mid = (a + b) / 2
			local len = (b - a).Magnitude
			local thick = 0.32 - math.abs(t0 + t1 - 1) * 0.12
			piece({ Name = "Limb", Size = Vector3.new(thick, len + 0.08, thick * 1.2), Material = Enum.Material.Wood, Color = Color3.fromRGB(96, 62, 36) }, CFrame.lookAt(mid, mid + (b - a)) * CFrame.Angles(math.rad(-90), 0, 0))
		end
		piece({ Name = "Wrap", Size = Vector3.new(0.4, 0.7, 0.45), Material = Enum.Material.Leather, Color = Color3.fromRGB(60, 40, 28) }, CFrame.new(0, 0, 0))
		piece({ Name = "String", Size = Vector3.new(0.04, h, 0.04), Material = Enum.Material.Fabric, Color = Color3.fromRGB(235, 230, 215) }, CFrame.new(0, 0, -depth))
	end
	m.Parent = char
end

local function onAction(player: Player, action: string, aim: Vector3?, charge: number?)
	local char, hum, hrp = charParts(player)
	if not char or not hum or not hrp then
		return
	end
	local s = state(player)
	if action == "SwitchWeapon" then
		s.weapon = if s.weapon == "Sword" then "Bow" else "Sword"
		s.blocking = false
		hum.WalkSpeed = StarterPlayer.CharacterWalkSpeed
		setWeaponVisual(player, s.weapon)
		return
	end
	if action == "DrawOn" or action == "DrawOff" then
		-- só visual (os outros jogadores veem a pose de mira)
		char:SetAttribute("BowDraw", action == "DrawOn" and s.weapon == "Bow")
		return
	end
	if action == "Dodge" then
		local now = os.clock()
		if now < s.dodgeReadyAt then
			return
		end
		s.dodgeReadyAt = now + Rules.Combat.DodgeCooldownSeconds
		s.invulnUntil = now + Combat.Dodge.InvulnerableSeconds
		NetService.Fire(player, "SkillUsed", "Dodge", Rules.Combat.DodgeCooldownSeconds)
		return
	end
	-- montado: espada e arco ficam guardados (comanda o dragão)
	if CompanionService.IsMounted(player) then
		return
	end
	if action == "BlockOn" or action == "BlockOff" then
		s.blocking = action == "BlockOn" and s.weapon == "Sword"
		hum.WalkSpeed = if s.blocking then Combat.Sword.BlockWalkSpeed else StarterPlayer.CharacterWalkSpeed
		char:SetAttribute("Blocking", s.blocking)
		return
	end
	if s.weapon == "Sword" then
		if action == "Attack" and not s.blocking then
			swing(player, s, hrp)
		elseif action == "Skill" then
			spin(player, s, hrp)
		end
	else
		if action == "Attack" then
			bowShot(player, s, hrp, aim, charge)
		elseif action == "Skill" then
			tripleShot(player, s, hrp, aim)
		end
	end
end

--------------------------------------------------------------------------
-- Inicialização
--------------------------------------------------------------------------
function CombatService.Init()
	-- Troca a regeneração padrão do Roblox pela nossa (só fora de combate).
	local scripts = StarterPlayer:FindFirstChild("StarterCharacterScripts")
	if scripts and not scripts:FindFirstChild("Health") then
		local blank = Instance.new("Script")
		blank.Name = "Health"
		blank.Parent = scripts
	end

	NetService.On("CombatAction", onAction)

	local function onCharacter(player: Player, char: Model)
		local s = state(player)
		s.blocking = false
		s.combo = 0
		local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
		if hum then
			hum.MaxHealth = Combat.Player.MaxHealth
			hum.Health = Combat.Player.MaxHealth
		end
		char:WaitForChild("RightHand", 5)
		setWeaponVisual(player, s.weapon)
	end
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(char)
			onCharacter(player, char)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		lastHit[player] = nil
	end)

	-- regeneração fora de combate
	task.spawn(function()
		while true do
			task.wait(1)
			for _, p in ipairs(Players:GetPlayers()) do
				local _, hum = charParts(p)
				if hum and hum.Health < hum.MaxHealth and not CombatService.InCombat(p) then
					hum.Health = math.min(hum.MaxHealth, hum.Health + Combat.Player.RegenPerSecond)
				end
			end
		end
	end)
end

return CombatService
