--!strict
-- Dragões soltos para passear (pedido do responsável, 13/10/2026).
-- O dono pode soltar dragões da fazenda (que não são o ativo) para andarem pelo mundo:
--  * Com o dono na fazenda, passeiam pela fazenda e arredores.
--  * Com o dono fora, acompanham de longe, passeando perto dele (nunca muito longe).
--  * NÃO lutam e NÃO podem ser atacados (sem PvP, inimigos ignoram): eles nunca entram nas
--    listas de alvos do combate. Só o dragão ativo (companheiro) luta.
-- Movimento decidido só no servidor (o cliente não controla dragões soltos).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local RoamService = {}

type Entry = {
	player: Player,
	model: Model,
	root: BasePart,
	align: AlignPosition,
	orient: AlignOrientation,
	size: number,
	target: Vector3?,
	nextPick: number,
	farmCenter: Vector3?,
}

local entries: { [Model]: Entry } = {}
local rng = Random.new()

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace.Terrain }
rayParams.IgnoreWater = false

local function folder(): Folder
	local f = workspace:FindFirstChild("RoamingDragons")
	if not f then
		f = Instance.new("Folder")
		f.Name = "RoamingDragons"
		f.Parent = workspace
	end
	return f :: Folder
end

local function groundAt(x: number, z: number, nearY: number): Vector3?
	local hit = workspace:Raycast(Vector3.new(x, nearY + 120, z), Vector3.new(0, -400, 0), rayParams)
	if hit and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
end

-- `model` vem do DragonModels.Build (Root ancorado, peças soldadas). farmCenter = centro da fazenda.
function RoamService.Attach(player: Player, model: Model, farmCenter: Vector3?)
	local root = model.PrimaryPart :: BasePart
	local _, ext = model:GetBoundingBox()
	local att = Instance.new("Attachment")
	att.Name = "Center"
	att.Parent = root
	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.MaxForce = 1e7
	align.Responsiveness = 10
	align.MaxVelocity = Rules.Roam.WalkSpeed
	align.Position = root.Position
	align.Parent = root
	local orient = Instance.new("AlignOrientation")
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = att
	orient.MaxTorque = 1e7
	orient.Responsiveness = 8
	orient.CFrame = root.CFrame.Rotation
	orient.Parent = root
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Roaming", true)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = folder()
	root.Anchored = false
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	entries[model] = {
		player = player,
		model = model,
		root = root,
		align = align,
		orient = orient,
		size = math.max(ext.X, ext.Z),
		target = nil,
		nextPick = 0,
		farmCenter = farmCenter,
	}
end

local function step(e: Entry, now: number)
	local char = e.player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local R = Rules.Roam
	local pos = e.root.Position
	-- centro do passeio: a fazenda (dono lá) ou o próprio dono (dono fora)
	local center: Vector3
	local radius: number
	if hrp and e.farmCenter and (hrp.Position - e.farmCenter).Magnitude < R.FarmRadius then
		center, radius = e.farmCenter, R.FarmRadius * 0.6
	elseif hrp then
		center, radius = hrp.Position, R.NearOwnerRadius
	elseif e.farmCenter then
		center, radius = e.farmCenter, R.FarmRadius * 0.6
	else
		return
	end
	local away = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
	-- muito longe (dono viajou/teleportou): reaparece perto
	if away > R.TeleportDistance then
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(radius * 0.5, radius)
		local g = groundAt(center.X + math.cos(a) * d, center.Z + math.sin(a) * d, center.Y)
		if g then
			e.model:PivotTo(CFrame.new(g) * e.root.CFrame.Rotation)
			e.align.Position = g
			e.target = nil
		end
		return
	end
	-- escolhe um novo ponto de passeio de tempos em tempos (ou se ficou para trás)
	if not e.target or now >= e.nextPick or away > radius * 1.6 then
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(radius * 0.3, radius)
		local g = groundAt(center.X + math.cos(a) * d, center.Z + math.sin(a) * d, center.Y)
		if g then
			e.target = g
		end
		e.nextPick = now + rng:NextNumber(R.PauseMin, R.PauseMax)
	end
	local t = e.target
	if not t then
		return
	end
	-- mais longe do centro = anda mais rápido para alcançar
	e.align.MaxVelocity = if away > radius * 1.3 then R.CatchUpSpeed else R.WalkSpeed
	-- segue o chão entre a posição atual e o alvo
	local flat = Vector3.new(t.X - pos.X, 0, t.Z - pos.Z)
	if flat.Magnitude > 2 then
		local stepDist = math.min(flat.Magnitude, 12)
		local nxt = pos + flat.Unit * stepDist
		local g = groundAt(nxt.X, nxt.Z, pos.Y)
		e.align.Position = if g then g else Vector3.new(nxt.X, pos.Y, nxt.Z)
		e.orient.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit)
	end
end

function RoamService.Init()
	task.spawn(function()
		while true do
			task.wait(0.4)
			local now = os.clock()
			for model, e in pairs(entries) do
				if not model.Parent or not e.player.Parent then
					entries[model] = nil
				else
					local ok, err = pcall(step, e, now)
					if not ok then
						warn("[Roam] " .. tostring(err))
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for model, e in pairs(entries) do
			if e.player == player then
				entries[model] = nil
				model:Destroy()
			end
		end
	end)
end

return RoamService
