--!strict
-- Fase 3: dragão companheiro. O dragão ativo (já nascido) acompanha o dono pelo mundo
-- e, a partir de Jovem, pode ser montado em terra.
--
-- Segurança (anti-exploit):
--  * Seguindo: o servidor é o dono da física do dragão (SetNetworkOwner(nil)); o cliente não move nada.
--  * Montado: o cliente do dono controla o dragão (para não ter atraso), mas o servidor mede a
--    velocidade, a subida e a altura a cada 0,25 s. Passou do limite várias vezes seguidas:
--    o jogador desmonta e o dragão volta à última posição válida.
--  * Montar só o próprio dragão, de perto, vivo, a partir do estágio Jovem.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Growth = require(ReplicatedStorage.Shared.Config.Growth)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)
local Rarity = require(ReplicatedStorage.Shared.Config.Rarity)
local Species = require(ReplicatedStorage.Shared.Config.Species)

local CompanionService = {}

type Entry = {
	player: Player,
	model: Model,
	root: BasePart,
	size: number,
	height: number,
	speed: number,
	canMount: boolean,
	align: AlignPosition,
	orient: AlignOrientation,
	velocity: LinearVelocity,
	seat: Seat?,
	mounted: boolean,
	lastPos: Vector3,
	lastGood: Vector3,
	lastCheck: number,
	strikes: number,
	airSince: number?,
	conns: { RBXScriptConnection },
	goal: Vector3?, -- combate: posição para onde o dragão deve ir (em vez de seguir o dono)
	faceTo: Vector3?,
	mode: string, -- montado: "Ground" | "Fly" | "Burrow"
	canFly: boolean,
	canBurrow: boolean,
	flySpeed: number,
	modeSince: number,
}

local entries: { [Player]: Entry } = {}

local attachedEvent = Instance.new("BindableEvent")
local detachedEvent = Instance.new("BindableEvent")
CompanionService.Attached = attachedEvent.Event -- (player, model, dragon)
CompanionService.Detached = detachedEvent.Event -- (player)
local modeEvent = Instance.new("BindableEvent")
CompanionService.ModeChanged = modeEvent.Event -- (player, modoAntigo, modoNovo)

local BURROW_GROUP = "Burrowing"
local notifyFn: ((Player, string, string?) -> ())? = nil

local function folder(): Folder
	local f = workspace:FindFirstChild("Companions")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Companions"
		f.Parent = workspace
	end
	return f :: Folder
end

local function notify(player: Player, text: string, kind: string?)
	if notifyFn then
		notifyFn(player, text, kind)
	end
end

-- Velocidade de voo: base × raridade × espécie (Amphiptere é o mais rápido no ar).
local FLIGHT_SPECIES = { Amphiptere = 1.15, Wyvern = 1.05, WesternDragon = 1.0, AsianDragon = 1.0 }
function CompanionService.FlightSpeed(dragon: { [string]: any }): number
	local r = Rarity.Defs[dragon.Rarity] or Rarity.Defs.Common
	local stageMult = ({ Young = 0.85, Subadult = 0.93, Adult = 1.0, Elder = 1.05 } :: any)[dragon.Stage] or 1
	return Rules.Mount.FlightBaseSpeed * r.FlightSpeedMult * (FLIGHT_SPECIES[dragon.Species] or 1) * stageMult
end

-- Velocidade em terra do dragão montado (a raridade muda o voo, não a corrida).
function CompanionService.LandSpeed(dragon: { [string]: any }): number
	local base = Rules.Mount.LandSpeedByStage[dragon.Stage] or 0
	if dragon.Species == "Wyrm" then
		base *= Rules.Mount.WyrmLandMultiplier
	end
	return base
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false

local function refreshFilter()
	local list: { Instance } = { folder() }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = list
end

local function groundAt(pos: Vector3, from: number?, depth: number?): number?
	local start = Vector3.new(pos.X, (from or pos.Y) + 12, pos.Z)
	local hit = workspace:Raycast(start, Vector3.new(0, -((depth or 80) + 12), 0), rayParams)
	return hit and hit.Position.Y or nil
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
-- Montar e desmontar
--------------------------------------------------------------------------
local function setServerControl(e: Entry)
	e.velocity.Enabled = false
	e.align.Position = e.root.Position
	e.align.Enabled = true
	e.orient.Enabled = true
	if e.root:IsDescendantOf(workspace) and not e.root.Anchored then
		pcall(function()
			e.root:SetNetworkOwner(nil)
		end)
	end
end

function CompanionService.Dismount(player: Player, reason: string?)
	local e = entries[player]
	if not e or not e.mounted then
		return
	end
	e.mounted = false
	e.model:SetAttribute("Mounted", false)
	if e.mode ~= "Ground" then
		CompanionService.SetMode(player, "Ground", true)
	end
	local seat = e.seat
	if seat then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		seat.Disabled = true
	end
	setServerControl(e)
	-- coloca o jogador em pé ao lado do dragão
	local hrp = hrpOf(player)
	if hrp then
		local side = e.root.CFrame * CFrame.new(e.size * 0.35 + 3, 0, 0)
		local g = groundAt(side.Position, side.Position.Y + 20, 60) or side.Position.Y
		hrp.CFrame = CFrame.new(Vector3.new(side.Position.X, g + 3.5, side.Position.Z)) * e.root.CFrame.Rotation
	end
	if reason then
		notify(player, reason, "warning")
	end
end

-- Troca o modo do dragão montado: "Ground" (terra), "Fly" (voo) ou "Burrow" (por baixo da terra).
-- O servidor confere se o dragão liberou o modo pela missão. `force` = servidor (desmontar, reset).
function CompanionService.SetMode(player: Player, mode: string, force: boolean?)
	local e = entries[player]
	if not e or (not e.mounted and not force) or e.mode == mode then
		return
	end
	if not force then
		if mode == "Fly" and not e.canFly then
			notify(player, "Seu dragão ainda não voa. Fale com a Mestra Lira sobre a Poção do Voo.")
			return
		end
		if mode == "Burrow" and not e.canBurrow then
			notify(player, "Seu Wyrm ainda não entra na terra. Fale com a Mestra Lira sobre a Poção da Terra.")
			return
		end
		if os.clock() - e.modeSince < 0.6 then
			return
		end
	end
	local old = e.mode
	e.mode = mode
	e.modeSince = os.clock()
	e.airSince = nil
	e.strikes = 0
	e.lastPos = e.root.Position
	e.lastCheck = os.clock()
	e.model:SetAttribute("Mode", mode)
	-- por baixo da terra o cavaleiro atravessa o terreno e não pode ser atingido
	local char = player.Character
	if char then
		char:SetAttribute("Burrowed", mode == "Burrow")
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CollisionGroup = if mode == "Burrow" then BURROW_GROUP else "Default"
			end
		end
	end
	for _, d in ipairs(e.model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = if mode == "Burrow" then BURROW_GROUP else "Default"
		end
	end
	modeEvent:Fire(player, old, mode)
end

function CompanionService.Mode(player: Player): string?
	local e = entries[player]
	return e and e.mounted and e.mode or nil
end

function CompanionService.Mount(player: Player)
	local e = entries[player]
	if not e or e.mounted then
		return
	end
	if not e.canMount or not e.seat then
		notify(player, "Seu dragão precisa ser Jovem para ser montado.")
		return
	end
	local hrp = hrpOf(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.SeatPart ~= nil then
		return
	end
	if (hrp.Position - e.root.Position).Magnitude > Rules.Companion.MountDistance + e.size * 0.5 then
		notify(player, "Chegue mais perto do seu dragão para montar.")
		return
	end
	local seat = e.seat :: Seat
	e.mounted = true
	e.model:SetAttribute("Mounted", true)
	e.align.Enabled = false
	e.velocity.VectorVelocity = Vector3.zero
	e.velocity.Enabled = true
	seat.Disabled = false
	seat:Sit(hum)
	e.lastPos = e.root.Position
	e.lastGood = e.root.Position
	e.lastCheck = os.clock()
	e.strikes = 0
	e.airSince = nil
	pcall(function()
		e.root:SetNetworkOwner(player)
	end)
end

--------------------------------------------------------------------------
-- Criar / remover o companheiro
--------------------------------------------------------------------------
-- `model` vem do DragonModels.Build (Root ancorado no chão, peças soldadas ao Root).
function CompanionService.Attach(player: Player, model: Model, dragon: { [string]: any }): Model
	CompanionService.Detach(player)
	local root = model.PrimaryPart :: BasePart
	local _, extents = model:GetBoundingBox()
	local height = (model:GetAttribute("Height") :: number?) or extents.Y
	local size = math.max(extents.X, extents.Z)

	local att = Instance.new("Attachment")
	att.Name = "Center"
	att.Parent = root

	local align = Instance.new("AlignPosition")
	align.Name = "FollowAlign"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.MaxForce = 1e7
	align.Responsiveness = 18
	align.MaxVelocity = Rules.Companion.FollowCatchUpSpeed
	align.Parent = root

	local orient = Instance.new("AlignOrientation")
	orient.Name = "MountAlign" -- usado também pelo cliente quando montado
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = att
	orient.MaxTorque = 1e7
	orient.Responsiveness = 16
	orient.CFrame = root.CFrame.Rotation
	orient.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "MountVelocity"
	velocity.Attachment0 = att
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.MaxForce = 1e7
	velocity.Enabled = false
	velocity.Parent = root

	local canMount = Growth.StageIndex(dragon.Stage) >= Growth.StageIndex(Growth.RideStage)
	local seat: Seat? = nil
	if canMount then
		local s = Instance.new("Seat")
		s.Name = "Saddle"
		s.Size = Vector3.new(2, 0.4, 2)
		s.Transparency = 1
		s.CanCollide = false
		s.CanQuery = false
		s.Massless = true
		s.Disabled = true
		s.CFrame = root.CFrame * CFrame.new(0, height * 0.6, -size * 0.04)
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = s
		w.Parent = s
		s.Parent = model
		seat = s

		local promptAtt = root:FindFirstChild("PromptAttachment")
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Mount"
		prompt.ActionText = "Montar"
		prompt.ObjectText = ""
		prompt.KeyboardKeyCode = Enum.KeyCode.V
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
		prompt.UIOffset = Vector2.new(0, 72)
		prompt.MaxActivationDistance = 12 + size * 0.4
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0.25
		prompt:SetAttribute("OwnerUserId", player.UserId)
		prompt.Parent = promptAtt or root
		prompt.Triggered:Connect(function(who: Player)
			if who == player then
				CompanionService.Mount(player)
			end
		end)
	end

	local speed = CompanionService.LandSpeed(dragon)
	local adult = Growth.StageIndex(dragon.Stage) >= Growth.StageIndex(Growth.FlightStage)
	local canFly = adult and Species[dragon.Species].CanFly and dragon.FlightUnlocked == true
	local canBurrow = adult and Species[dragon.Species].CanBurrow and dragon.BurrowUnlocked == true
	local flySpeed = CompanionService.FlightSpeed(dragon)
	model:SetAttribute("CanFly", canFly)
	model:SetAttribute("CanBurrow", canBurrow)
	model:SetAttribute("FlightSpeed", flySpeed)
	model:SetAttribute("FlightStyle", Species[dragon.Species].FlightStyle or "")
	model:SetAttribute("Mode", "Ground")
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Companion", true)
	model:SetAttribute("MountSpeed", speed)
	model:SetAttribute("Mounted", false)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	-- nasce ao lado do jogador, se ele já estiver no mundo
	local hrp = hrpOf(player)
	if hrp then
		local p = (hrp.CFrame * CFrame.new(size * 0.4 + 4, 0, size * 0.5 + 5)).Position
		local g = groundAt(p, hrp.Position.Y + 10, 80) or (hrp.Position.Y - 3)
		model:PivotTo(CFrame.new(Vector3.new(p.X, g, p.Z)) * hrp.CFrame.Rotation)
	end
	model.Parent = folder()
	root.Anchored = false
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false

	local e: Entry = {
		player = player,
		model = model,
		root = root,
		size = size,
		height = height,
		speed = speed,
		canMount = canMount,
		align = align,
		orient = orient,
		velocity = velocity,
		seat = seat,
		mounted = false,
		lastPos = root.Position,
		lastGood = root.Position,
		lastCheck = os.clock(),
		strikes = 0,
		airSince = nil,
		conns = {},
		goal = nil,
		faceTo = nil,
		mode = "Ground",
		canFly = canFly,
		canBurrow = canBurrow,
		flySpeed = flySpeed,
		modeSince = os.clock(),
	}
	entries[player] = e
	setServerControl(e)

	if seat then
		table.insert(
			e.conns,
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				local occ = seat.Occupant
				if occ == nil then
					if e.mounted then
						CompanionService.Dismount(player)
					end
				elseif occ.Parent ~= player.Character then
					-- só o dono senta no próprio dragão
					local weld = seat:FindFirstChild("SeatWeld")
					if weld then
						weld:Destroy()
					end
				end
			end)
		)
	end
	attachedEvent:Fire(player, model, dragon)
	return model
end

function CompanionService.Detach(player: Player)
	local e = entries[player]
	if not e then
		return
	end
	entries[player] = nil
	for _, c in ipairs(e.conns) do
		c:Disconnect()
	end
	if e.mounted and e.seat then
		local weld = e.seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	if e.model.Parent then
		e.model:Destroy()
	end
	detachedEvent:Fire(player)
end

-- Combate: manda o dragão ir até `pos` (nil = volta a seguir o dono) e olhar para `face`.
function CompanionService.SetGoal(player: Player, pos: Vector3?, face: Vector3?)
	local e = entries[player]
	if e then
		e.goal = pos
		e.faceTo = face
	end
end

function CompanionService.Root(player: Player): BasePart?
	local e = entries[player]
	return e and e.root
end

function CompanionService.Get(player: Player): Model?
	local e = entries[player]
	return e and e.model
end

function CompanionService.IsMounted(player: Player): boolean
	local e = entries[player]
	return e ~= nil and e.mounted
end

--------------------------------------------------------------------------
-- Ciclo: seguir o dono / validar o dragão montado
--------------------------------------------------------------------------
local function follow(e: Entry)
	local hrp = hrpOf(e.player)
	if not hrp then
		return
	end
	local rootPos = e.root.Position
	local flat = Vector3.new(hrp.Position.X - rootPos.X, 0, hrp.Position.Z - rootPos.Z)
	local dist = flat.Magnitude
	local behind = hrp.CFrame * CFrame.new(e.size * 0.3 + 4, 0, e.size * 0.45 + 5)

	-- longe demais (teleporte, respawn, caiu de um penhasco): reaparece ao lado
	if dist > Rules.Companion.TeleportDistance or math.abs(hrp.Position.Y - rootPos.Y) > 90 then
		local g = groundAt(behind.Position, hrp.Position.Y + 10, 80) or (hrp.Position.Y - 3)
		e.model:PivotTo(CFrame.new(Vector3.new(behind.Position.X, g, behind.Position.Z)) * hrp.CFrame.Rotation)
		e.align.Position = e.root.Position
		return
	end

	local target = behind.Position
	local toTarget = Vector3.new(target.X - rootPos.X, 0, target.Z - rootPos.Z)
	-- parado perto do dono: não fica "tremendo" atrás dele
	if e.goal then
		target = e.goal :: Vector3
		if Vector3.new(target.X - rootPos.X, 0, target.Z - rootPos.Z).Magnitude < 2 then
			target = rootPos
		end
	elseif toTarget.Magnitude < 3 or dist < e.size * 0.5 + 4 then
		target = rootPos
	end
	local g = groundAt(target, math.max(hrp.Position.Y, rootPos.Y) + 8, 80) or rootPos.Y
	e.align.Position = Vector3.new(target.X, g, target.Z)
	-- anda mais rápido quanto mais longe estiver (nunca acima do limite de alcance)
	e.align.MaxVelocity = math.clamp(dist * 1.3, 10, math.max(Rules.Companion.FollowCatchUpSpeed, e.speed + 10))

	local move = Vector3.new(target.X - rootPos.X, 0, target.Z - rootPos.Z)
	local face = e.faceTo
	if face and move.Magnitude <= 1.5 then
		local f = Vector3.new(face.X - rootPos.X, 0, face.Z - rootPos.Z)
		if f.Magnitude > 0.5 then
			e.orient.CFrame = CFrame.lookAt(Vector3.zero, f.Unit)
		end
	elseif move.Magnitude > 1.5 then
		e.orient.CFrame = CFrame.lookAt(Vector3.zero, move.Unit)
	elseif dist > 2 then
		e.orient.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit)
	end
end

local function validate(e: Entry)
	local now = os.clock()
	local dt = now - e.lastCheck
	if dt < 0.25 then
		return
	end
	local p = e.root.Position
	local last = e.lastPos
	local horiz = Vector3.new(p.X - last.X, 0, p.Z - last.Z).Magnitude
	local rise = p.Y - last.Y
	local M = Rules.Mount
	local bad = false
	local mode = e.mode
	-- logo depois de trocar de modo, tolerância extra (decolagem/mergulho)
	local grace = if now - e.modeSince < 1.5 then 1.6 else 1
	local maxSpeed = if mode == "Fly" then e.flySpeed elseif mode == "Burrow" then e.speed * 1.2 else e.speed
	if horiz > maxSpeed * dt * M.SpeedTolerance * grace + 4 then
		bad = true
	end
	local maxClimb = if mode == "Fly" then e.flySpeed * 0.8 else M.MaxClimbPerSecond
	if rise > maxClimb * dt * grace + 6 then
		bad = true
	end
	if mode == "Fly" then
		e.airSince = nil
		if p.Y > M.MaxFlightAltitude then
			bad = true
		end
	elseif mode == "Burrow" then
		-- precisa continuar por baixo/rente ao chão
		local g = groundAt(p, p.Y + 40, 120)
		if g and p.Y > g + 4 and rise > -1 then
			e.airSince = e.airSince or now
			if now - (e.airSince :: number) > 1.5 then
				bad = true
			end
		else
			e.airSince = nil
		end
	else
		-- dragão de terra não voa: muito acima do chão, sem estar descendo, por mais de 2 s
		local g = groundAt(p, p.Y, 200)
		if g and p.Y - g > M.MaxHoverHeight and rise > -1 then
			e.airSince = e.airSince or now
			if now - (e.airSince :: number) > 2 then
				bad = true
			end
		else
			e.airSince = nil
		end
	end
	if bad then
		e.strikes += 1
	else
		e.strikes = math.max(0, e.strikes - 0.25)
		e.lastGood = p
	end
	e.lastPos = p
	e.lastCheck = now
	if e.strikes >= M.StrikesToReset then
		warn(string.format("[Companion] Movimento inválido de %s (%.0f studs em %.2f s); resetando", e.player.Name, horiz, dt))
		local good = e.lastGood
		e.model:PivotTo(CFrame.new(good) * e.root.CFrame.Rotation)
		CompanionService.Dismount(e.player, "Movimento inválido detectado. Você desmontou.")
		e.align.Position = good
		e.strikes = 0
		e.airSince = nil
	end
end

function CompanionService.Init(notify: (Player, string, string?) -> ())
	notifyFn = notify
	pcall(function()
		PhysicsService:RegisterCollisionGroup(BURROW_GROUP)
		PhysicsService:CollisionGroupSetCollidable(BURROW_GROUP, "Default", false)
	end)
	Players.PlayerRemoving:Connect(function(player)
		CompanionService.Detach(player)
	end)
	local acc = 0
	local filterAcc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		filterAcc += dt
		if filterAcc > 2 then
			filterAcc = 0
			refreshFilter()
		end
		if acc < 0.1 then
			return
		end
		acc = 0
		for player, e in pairs(entries) do
			if not e.model.Parent then
				entries[player] = nil
				continue
			end
			local ok, err = pcall(if e.mounted then validate else follow, e)
			if not ok then
				warn("[Companion] " .. tostring(err))
			end
		end
	end)
	refreshFilter()
end

return CompanionService
