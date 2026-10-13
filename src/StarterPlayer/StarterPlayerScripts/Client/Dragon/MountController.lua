--!strict
-- Controle do dragão montado (lado do cliente): terra, voo e "entrar na terra" (Wyrm).
-- O servidor dá ao dono a física do dragão só enquanto ele está montado e confere velocidade,
-- subida e altura conforme o modo; aqui o cliente só aplica a direção do controle.
--
-- Teclas (montado): V = descer · Espaço = decolar / subir (voo) ou mergulhar / sair (Wyrm)
--                   Ctrl = descer no voo (perto do chão: pousa)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetClient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("NetClient"))
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local player = Players.LocalPlayer
local MountController = {}

type Current = { model: Model, root: BasePart, velocity: LinearVelocity, orient: AlignOrientation, facing: Vector3, up: boolean, down: boolean, t: number }

local controls: any = nil
local current: Current? = nil
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = false

local DISMOUNT_ACTION = "DragonDismount"
local UP_ACTION = "DragonUp"
local DOWN_ACTION = "DragonDown"

local function getControls()
	if controls then
		return controls
	end
	local ok, module = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: any)
	end)
	if ok and module then
		controls = module:GetControls()
	end
	return controls
end

local function groundBelow(pos: Vector3, depth: number?): number?
	local hit = workspace:Raycast(pos + Vector3.new(0, 14, 0), Vector3.new(0, -(depth or 90), 0), params)
	return hit and hit.Position.Y or nil
end

local function mode(c: Current): string
	return (c.model:GetAttribute("Mode") :: string?) or "Ground"
end

local function step(dt: number)
	local c = current
	if not c then
		return
	end
	if not c.root.Parent or not c.velocity.Enabled then
		return
	end
	c.t += dt
	local move = Vector3.zero
	local ctl = getControls()
	if ctl then
		move = ctl:GetMoveVector()
	end
	local cam = workspace.CurrentCamera
	local m = mode(c)
	local pos = c.root.Position

	if m == "Fly" then
		-- voa para onde a câmera aponta; Espaço sobe, Ctrl desce
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local dir = right * move.X - look * move.Z
		if dir.Magnitude > 1 then
			dir = dir.Unit
		end
		local speed = (c.model:GetAttribute("FlightSpeed") :: number?) or 60
		local vy = 0
		if c.up then
			vy += speed * 0.6
		end
		if c.down then
			vy -= speed * 0.7
		end
		local v = dir * speed + Vector3.new(0, vy, 0)
		-- não passa do teto
		if pos.Y > Rules.Mount.MaxFlightAltitude - 20 and v.Y > 0 then
			v = Vector3.new(v.X, 0, v.Z)
		end
		c.velocity.VectorVelocity = v
		local flat = Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude > 0.05 then
			c.facing = flat.Unit
		end
		-- inclina um pouco para a frente/cima; o Dragão Asiático ondula de um lado para o outro
		local pitch = math.clamp(-v.Y / math.max(speed, 1), -0.5, 0.5) * 0.6
		local roll = 0
		if c.model:GetAttribute("FlightStyle") == "Undulate" then
			roll = math.sin(c.t * 4) * 0.18
		end
		c.orient.CFrame = CFrame.lookAt(Vector3.zero, c.facing) * CFrame.Angles(pitch, 0, roll)
		-- Ctrl perto do chão: pousa
		if c.down then
			local g = groundBelow(pos, 30)
			if g and pos.Y - g < 6 then
				NetClient.Fire("MountMode", "Ground")
				c.down = false
			end
		end
		return
	end

	-- terra e por baixo da terra: segue o relevo
	local look = cam.CFrame.LookVector
	local right = cam.CFrame.RightVector
	local fwd = Vector3.new(look.X, 0, look.Z)
	local side = Vector3.new(right.X, 0, right.Z)
	if fwd.Magnitude > 0.01 then
		fwd = fwd.Unit
	end
	if side.Magnitude > 0.01 then
		side = side.Unit
	end
	local dir = side * move.X - fwd * move.Z
	if dir.Magnitude > 1 then
		dir = dir.Unit
	end
	local speed = (c.model:GetAttribute("MountSpeed") :: number?) or 30
	if m == "Burrow" then
		speed *= 1.2
	end
	local probe = pos + Vector3.new(0, if m == "Burrow" then Rules.Mount.BurrowDepth + 4 else 0, 0)
	local g0 = groundBelow(probe)
	local g1 = groundBelow(probe + dir * speed * 0.2)
	local target: number? = g0
	if g1 and (not target or g1 > target) then
		target = g1
	end
	if target and m == "Burrow" then
		target -= Rules.Mount.BurrowDepth
	end
	local vy
	if target then
		vy = math.clamp((target - pos.Y) * 10, -70, 45)
	else
		vy = -50 -- sem chão por perto: cai
	end
	c.velocity.VectorVelocity = dir * speed + Vector3.new(0, vy, 0)
	if dir.Magnitude > 0.05 then
		c.facing = dir.Unit
	end
	c.orient.CFrame = CFrame.lookAt(Vector3.zero, c.facing)
end

local function stop()
	current = nil
	ContextActionService:UnbindAction(DISMOUNT_ACTION)
	ContextActionService:UnbindAction(UP_ACTION)
	ContextActionService:UnbindAction(DOWN_ACTION)
end

local function start(seat: BasePart)
	local model = seat.Parent
	if not model or not model:IsA("Model") or model:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end
	local root = model.PrimaryPart
	local velocity = root and root:FindFirstChild("MountVelocity")
	local orient = root and root:FindFirstChild("MountAlign")
	if not root or not velocity or not orient then
		return
	end
	local look = root.CFrame.LookVector
	local c: Current = {
		model = model,
		root = root,
		velocity = velocity :: LinearVelocity,
		orient = orient :: AlignOrientation,
		facing = Vector3.new(look.X, 0, look.Z).Unit,
		up = false,
		down = false,
		t = 0,
	}
	current = c
	params.FilterDescendantsInstances = { model, player.Character :: Instance }
	ContextActionService:BindAction(DISMOUNT_ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			NetClient.Fire("DismountDragon")
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.V, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle(DISMOUNT_ACTION, "Descer")
	ContextActionService:SetPosition(DISMOUNT_ACTION, UDim2.new(1, -170, 1, -150))

	-- Espaço: decolar/subir (voo), mergulhar/sair (Wyrm). Prioridade alta para não fazer o
	-- personagem pular do dragão.
	ContextActionService:BindActionAtPriority(UP_ACTION, function(_, state)
		local m = mode(c)
		if state == Enum.UserInputState.Begin then
			if m == "Fly" then
				c.up = true
			elseif m == "Burrow" then
				NetClient.Fire("MountMode", "Ground")
			elseif model:GetAttribute("CanFly") then
				NetClient.Fire("MountMode", "Fly")
				c.up = true
			elseif model:GetAttribute("CanBurrow") then
				NetClient.Fire("MountMode", "Burrow")
			end
		elseif state == Enum.UserInputState.End then
			c.up = false
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	ContextActionService:SetTitle(UP_ACTION, if model:GetAttribute("CanBurrow") then "Terra" else "Subir")
	ContextActionService:SetPosition(UP_ACTION, UDim2.new(1, -100, 1, -150))
	ContextActionService:BindAction(DOWN_ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			c.down = true
		elseif state == Enum.UserInputState.End then
			c.down = false
		end
		return Enum.ContextActionResult.Sink
	end, model:GetAttribute("CanFly") == true, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonL2)
	ContextActionService:SetTitle(DOWN_ACTION, "Baixar")
	ContextActionService:SetPosition(DOWN_ACTION, UDim2.new(1, -100, 1, -80))
end

local function hookCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then
		return
	end
	hum.Seated:Connect(function(active: boolean, seat: BasePart?)
		if active and seat and seat.Name == "Saddle" then
			start(seat)
		else
			stop()
		end
	end)
	hum.Died:Connect(stop)
end

function MountController.Init()
	if player.Character then
		task.spawn(hookCharacter, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		stop()
		hookCharacter(char)
	end)
	RunService.RenderStepped:Connect(step)
end

function MountController.IsMounted(): boolean
	return current ~= nil
end

return MountController
