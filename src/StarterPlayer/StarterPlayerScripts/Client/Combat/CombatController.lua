--!strict
-- Controles de combate (GAME-DESIGN §10.5). O cliente só lê a entrada e manda PEDIDOS;
-- dano, acerto, recargas e flechas são decididos no servidor.
--
-- PC: clique esquerdo = atacar (arco: segurar para carregar) · clique direito = bloquear (espada)
--     ou mirar (arco) · Q = esquiva · roda do mouse = trocar arma · T = habilidade da arma
--     (Golpe Giratório / Flecha Tripla) · F = dragão ataca o alvo mirado · G = dragão volta
--     (ou é chamado de novo) · Z / X / C = poderes do dragão.
-- Celular: botões na tela para cada ação (ContextActionService).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)
local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local player = Players.LocalPlayer
local CombatController = {}

local charging: number? = nil -- os.clock() do início da carga do arco
local aiming = false
local dodgeReadyAt = 0
local baseFov = 70
local isMountedFn: () -> boolean = function()
	return false
end
local chargeChanged: ((number?) -> ())? = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function character(): (Model?, Humanoid?, BasePart?)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not hum or not hrp or hum.Health <= 0 then
		return nil, nil, nil
	end
	return char, hum, hrp
end

local function weapon(): string
	local char = player.Character
	return char and (char:GetAttribute("Weapon") :: string?) or "Sword"
end

-- Ponto do mundo sob o cursor (PC) ou no centro da tela (celular / trava de câmera).
function CombatController.AimPoint(): Vector3
	local cam = workspace.CurrentCamera
	local pos: Vector2
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		pos = cam.ViewportSize / 2
	else
		pos = UserInputService:GetMouseLocation()
	end
	local ray = cam:ViewportPointToRay(pos.X, pos.Y)
	local filter: { Instance } = {}
	if player.Character then
		table.insert(filter, player.Character)
	end
	local comps = workspace:FindFirstChild("Companions")
	if comps then
		table.insert(filter, comps)
	end
	local fx = workspace:FindFirstChild("ClientFx")
	if fx then
		table.insert(filter, fx)
	end
	rayParams.FilterDescendantsInstances = filter
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
	return if hit then hit.Position else ray.Origin + ray.Direction * 1000
end

local function aimDir(): Vector3?
	local char, _, hrp = character()
	if not char or not hrp then
		return nil
	end
	local head = char:FindFirstChild("Head") :: BasePart?
	local from = if head then head.Position else hrp.Position
	local to = CombatController.AimPoint()
	local d = to - from
	if d.Magnitude < 0.5 then
		return hrp.CFrame.LookVector
	end
	return d.Unit
end

-- Vira o personagem para a mira antes de atacar (o servidor usa a frente do personagem).
local function faceAim()
	local _, _, hrp = character()
	local dir = aimDir()
	if hrp and dir then
		local flat = Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude > 0.1 then
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
		end
	end
end

local function attackBegin()
	if isMountedFn() then
		NetClient.Fire("DragonCommand", "Attack", CombatController.AimPoint())
		return
	end
	if not character() then
		return
	end
	if weapon() == "Bow" then
		charging = os.clock()
		if chargeChanged then
			chargeChanged(0)
		end
	else
		faceAim()
		NetClient.Fire("CombatAction", "Attack")
	end
end

local function attackEnd()
	if charging then
		local c = math.clamp((os.clock() - charging) / Combat.Bow.ChargeSeconds, 0, 1)
		charging = nil
		if chargeChanged then
			chargeChanged(nil)
		end
		local dir = aimDir()
		if dir and not isMountedFn() then
			faceAim()
			NetClient.Fire("CombatAction", "Attack", dir, c)
		end
	end
end

local function secondary(begin: boolean)
	if isMountedFn() then
		return
	end
	if weapon() == "Sword" then
		NetClient.Fire("CombatAction", if begin then "BlockOn" else "BlockOff")
	else
		aiming = begin
		local cam = workspace.CurrentCamera
		if begin then
			baseFov = cam.FieldOfView
			cam.FieldOfView = 50
		else
			cam.FieldOfView = baseFov
		end
	end
end

local function dodge()
	local _, hum, hrp = character()
	if not hum or not hrp or isMountedFn() then
		return
	end
	local now = os.clock()
	if now < dodgeReadyAt then
		return
	end
	dodgeReadyAt = now + Rules.Combat.DodgeCooldownSeconds
	NetClient.Fire("CombatAction", "Dodge")
	local dir = hum.MoveDirection
	if dir.Magnitude < 0.1 then
		dir = -hrp.CFrame.LookVector -- parado: rola para trás
	end
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local att = Instance.new("Attachment")
	att.Parent = hrp
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.xAxis
	lv.SecondaryTangentAxis = Vector3.zAxis
	lv.PlaneVelocity = Vector2.new(dir.X, dir.Z) * (Combat.Dodge.Distance / Combat.Dodge.Duration)
	lv.MaxForce = 1e5
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = hrp
	task.delay(Combat.Dodge.Duration, function()
		lv:Destroy()
		att:Destroy()
	end)
end

local function skill()
	if isMountedFn() or not character() then
		return
	end
	faceAim()
	NetClient.Fire("CombatAction", "Skill", aimDir())
end

local function dragon(cmd: string)
	NetClient.Fire("DragonCommand", cmd, CombatController.AimPoint())
end

function CombatController.Charging(): number?
	if not charging then
		return nil
	end
	return math.clamp((os.clock() - charging) / Combat.Bow.ChargeSeconds, 0, 1)
end

function CombatController.IsAiming(): boolean
	return aiming
end

function CombatController.Init(isMounted: () -> boolean, onCharge: ((number?) -> ())?)
	isMountedFn = isMounted
	chargeChanged = onCharge

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			attackBegin()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			secondary(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			attackEnd()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			secondary(false)
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseWheel and not isMountedFn() then
			-- a roda também aproxima a câmera; só troca arma com Shift segurado ou quando a câmera está em primeira pessoa
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				NetClient.Fire("CombatAction", "SwitchWeapon")
			end
		end
	end)

	local function bind(name: string, fn: (Enum.UserInputState) -> (), title: string, pos: UDim2, ...: Enum.KeyCode)
		ContextActionService:BindAction(name, function(_, state)
			fn(state)
			return Enum.ContextActionResult.Pass
		end, true, ...)
		ContextActionService:SetTitle(name, title)
		ContextActionService:SetPosition(name, pos)
	end
	-- teclas + botões de toque (no PC os botões não aparecem)
	bind("CombatTouchAttack", function(s)
		if not UserInputService.TouchEnabled then
			return
		end
		if s == Enum.UserInputState.Begin then
			attackBegin()
		elseif s == Enum.UserInputState.End then
			attackEnd()
		end
	end, "Atacar", UDim2.new(1, -95, 1, -230))
	bind("CombatBlock", function(s)
		if s == Enum.UserInputState.Begin then
			secondary(true)
		elseif s == Enum.UserInputState.End then
			secondary(false)
		end
	end, "Defesa", UDim2.new(1, -165, 1, -230))
	bind("CombatDodge", function(s)
		if s == Enum.UserInputState.Begin then
			dodge()
		end
	end, "Esquiva", UDim2.new(1, -235, 1, -160), Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
	bind("CombatSkill", function(s)
		if s == Enum.UserInputState.Begin then
			skill()
		end
	end, "Hab.", UDim2.new(1, -235, 1, -230), Enum.KeyCode.T, Enum.KeyCode.ButtonX)
	bind("CombatSwitch", function(s)
		if s == Enum.UserInputState.Begin and not isMountedFn() then
			NetClient.Fire("CombatAction", "SwitchWeapon")
		end
	end, "Arma", UDim2.new(1, -305, 1, -230), Enum.KeyCode.ButtonL1)
	bind("DragonAttack", function(s)
		if s == Enum.UserInputState.Begin then
			dragon("Attack")
		end
	end, "F", UDim2.new(1, -95, 1, -300), Enum.KeyCode.F, Enum.KeyCode.DPadUp)
	bind("DragonRecall", function(s)
		if s == Enum.UserInputState.Begin then
			dragon("Recall")
		end
	end, "G", UDim2.new(1, -165, 1, -300), Enum.KeyCode.G, Enum.KeyCode.DPadDown)
	for i, k in ipairs({ "Z", "X", "C" }) do
		bind("DragonPower" .. k, function(s)
			if s == Enum.UserInputState.Begin then
				dragon(k)
			end
		end, k, UDim2.new(1, -95 - (i - 1) * 70, 1, -370), (Enum.KeyCode :: any)[k])
	end
end

return CombatController
