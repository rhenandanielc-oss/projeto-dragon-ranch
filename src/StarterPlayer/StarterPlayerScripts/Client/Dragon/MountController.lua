--!strict
-- Fase 3: controle do dragão montado em terra (lado do cliente).
-- O servidor dá ao dono a física do dragão só enquanto ele está montado e confere a
-- velocidade; aqui o cliente apenas aplica a direção do controle, segue o relevo e vira o dragão.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetClient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("NetClient"))

local player = Players.LocalPlayer
local MountController = {}

local controls: any = nil
local current: { model: Model, root: BasePart, velocity: LinearVelocity, orient: AlignOrientation, facing: Vector3 }? = nil
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = false

local DISMOUNT_ACTION = "DragonDismount"

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

local function groundBelow(pos: Vector3): number?
	local hit = workspace:Raycast(pos + Vector3.new(0, 14, 0), Vector3.new(0, -90, 0), params)
	return hit and hit.Position.Y or nil
end

local function step(_dt: number)
	local c = current
	if not c then
		return
	end
	if not c.root.Parent or not c.velocity.Enabled then
		return
	end
	local move = Vector3.zero
	local ctl = getControls()
	if ctl then
		move = ctl:GetMoveVector()
	end
	local cam = workspace.CurrentCamera
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
	local pos = c.root.Position
	-- segue o relevo: olha o chão aqui e um pouco à frente (sobe rampas sem bater)
	local g0 = groundBelow(pos)
	local g1 = groundBelow(pos + dir * speed * 0.2)
	local target: number? = g0
	if g1 and (not target or g1 > target) then
		target = g1
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
	current = {
		model = model,
		root = root,
		velocity = velocity :: LinearVelocity,
		orient = orient :: AlignOrientation,
		facing = Vector3.new(look.X, 0, look.Z).Unit,
	}
	params.FilterDescendantsInstances = { model, player.Character :: Instance }
	ContextActionService:BindAction(DISMOUNT_ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			NetClient.Fire("DismountDragon")
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.V, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle(DISMOUNT_ACTION, "Descer")
	ContextActionService:SetPosition(DISMOUNT_ACTION, UDim2.new(1, -170, 1, -150))
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
