--!strict
-- Dragões selvagens voando pelo céu (só visual, no cliente; nenhum script por dragão).
-- Alguns dragões voam em rotas suaves e variadas perto do jogador: planam entre as
-- montanhas, passam rente às copas, pousam um tempo nas ilhas flutuantes e seguem.
-- Vistos de dentro da floresta, aparecem pelas aberturas entre as copas e na linha do horizonte.
-- Um único laço move todos; os distantes atualizam menos vezes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AmbientDragons = {}

local COUNT = 7
local MIN_R, MAX_R = 260, 1100 -- distância do jogador onde as rotas são sorteadas
local SPEED_MIN, SPEED_MAX = 45, 75

type Flyer = {
	model: Model,
	pts: { Vector3 }, -- pontos de controle da curva
	seg: number,
	t: number,
	speed: number,
	restUntil: number,
	pos: Vector3,
	look: Vector3,
	phase: number,
	scale: number,
}

local flyers: { Flyer } = {}
local rng = Random.new()
local folder: Folder
local player = Players.LocalPlayer
local enabled = true

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace.Terrain }

local function groundBelow(x: number, z: number): number
	local hit = workspace:Raycast(Vector3.new(x, 3000, z), Vector3.new(0, -3400, 0), rayParams)
	return if hit then hit.Position.Y else 0
end

local function center(): Vector3
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if hrp then hrp.Position else workspace.CurrentCamera.CFrame.Position
end

-- ilhas flutuantes por perto (para pousar)
local function islandSpots(): { Vector3 }
	local out = {}
	local world = workspace:FindFirstChild("World")
	local isl = world and world:FindFirstChild("SkyIslands")
	if isl then
		for _, m in ipairs(isl:GetChildren()) do
			local p = m:GetAttribute("LandingSpot")
			if typeof(p) == "Vector3" then
				table.insert(out, p :: Vector3)
			end
		end
	end
	return out
end

local function newPoint(from: Vector3, c: Vector3): Vector3
	local a = rng:NextNumber(0, math.pi * 2)
	local d = rng:NextNumber(MIN_R, MAX_R)
	local x, z = c.X + math.cos(a) * d, c.Z + math.sin(a) * d
	-- mistura com o ponto anterior para a curva não dar voltas bruscas
	x = from.X + (x - from.X) * 0.7
	z = from.Z + (z - from.Z) * 0.7
	local g = groundBelow(x, z)
	local alt = if rng:NextNumber() < 0.3 then rng:NextNumber(70, 130) else rng:NextNumber(160, 380)
	return Vector3.new(x, math.max(g, 0) + alt, z)
end

local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end

local function spawnFlyer(templates: { Model })
	local src = templates[rng:NextInteger(1, #templates)]
	local m = src:Clone()
	local scale = rng:NextNumber(0.7, 1.25)
	if scale ~= 1 then
		m:ScaleTo(m:GetScale() * scale)
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = true -- a sombra passa pelas aberturas da floresta
		end
	end
	m.Parent = folder
	local c = center()
	local start = newPoint(c, c)
	local pts = { start, newPoint(start, c), newPoint(start, c), newPoint(start, c) }
	local f: Flyer = {
		model = m,
		pts = pts,
		seg = 1,
		t = rng:NextNumber(0, 1),
		speed = rng:NextNumber(SPEED_MIN, SPEED_MAX),
		restUntil = 0,
		pos = start,
		look = Vector3.new(1, 0, 0),
		phase = rng:NextNumber(0, 10),
		scale = scale,
	}
	table.insert(flyers, f)
end

local function step(dt: number)
	if not enabled then
		return
	end
	local now = os.clock()
	local c = center()
	for _, f in ipairs(flyers) do
		-- jogador viajou para longe: o dragão "reaparece" fora de vista, perto da nova região
		if (Vector3.new(f.pos.X, 0, f.pos.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude > 2600 then
			local a = rng:NextNumber(0, math.pi * 2)
			local start = Vector3.new(c.X + math.cos(a) * 1500, 0, c.Z + math.sin(a) * 1500)
			start = Vector3.new(start.X, groundBelow(start.X, start.Z) + 250, start.Z)
			f.pts = { start, newPoint(start, c), newPoint(start, c), newPoint(start, c) }
			f.t = 0
			f.restUntil = 0
			f.pos = start
		end
		if now < f.restUntil then
			continue -- pousado numa ilha
		end
		local p0, p1, p2, p3 = f.pts[1], f.pts[2], f.pts[3], f.pts[4]
		local segLen = math.max(30, (p2 - p1).Magnitude)
		f.t += f.speed * dt / segLen
		while f.t >= 1 do
			f.t -= 1
			table.remove(f.pts, 1)
			local last = f.pts[#f.pts]
			-- às vezes vai pousar numa ilha flutuante próxima
			local spots = islandSpots()
			local target: Vector3? = nil
			if #spots > 0 and rng:NextNumber() < 0.12 then
				local s = spots[rng:NextInteger(1, #spots)]
				if (s - c).Magnitude < 2500 then
					target = s
				end
			end
			-- longe demais do jogador: volta para perto
			if (Vector3.new(last.X, 0, last.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude > MAX_R * 1.6 then
				target = newPoint(c, c)
			end
			table.insert(f.pts, target or newPoint(last, c))
			p0, p1, p2, p3 = f.pts[1], f.pts[2], f.pts[3], f.pts[4]
		end
		local pos = catmull(p0, p1, p2, p3, f.t)
		local ahead = catmull(p0, p1, p2, p3, math.min(1, f.t + 0.02))
		local vel = ahead - pos
		if vel.Magnitude > 0.01 then
			f.look = f.look:Lerp(vel.Unit, math.min(1, dt * 3))
		end
		-- inclina nas curvas e "respira" (sobe e desce de leve, como batendo asas)
		local flat = Vector3.new(f.look.X, 0, f.look.Z)
		local turn = flat.Magnitude > 0.01 and Vector3.new(vel.X, 0, vel.Z).Magnitude > 0.01 and flat.Unit:Cross(Vector3.new(vel.X, 0, vel.Z).Unit).Y or 0
		local bob = math.sin(now * 2.2 + f.phase) * 1.4 * f.scale
		local cf = CFrame.lookAt(pos, pos + f.look) * CFrame.Angles(0, 0, -turn * 8) * CFrame.new(0, bob, 0)
		f.pos = pos
		-- longe da câmera, atualiza menos vezes
		local dist = (pos - workspace.CurrentCamera.CFrame.Position).Magnitude
		if dist < 600 or (math.floor(now * 20) + f.phase) % 3 < 1 then
			f.model:PivotTo(cf)
		end
		-- pouso: chegou perto de uma ilha marcada como alvo
		if f.t > 0.95 then
			for _, s in ipairs(islandSpots()) do
				if (p2 - s).Magnitude < 1 and now > f.restUntil then
					f.restUntil = now + rng:NextNumber(12, 30)
					f.model:PivotTo(CFrame.lookAt(s, s + Vector3.new(f.look.X, 0, f.look.Z)))
					break
				end
			end
		end
	end
end

function AmbientDragons.SetEnabled(on: boolean)
	enabled = on
	if folder then
		folder.Parent = if on then workspace else nil
	end
end

function AmbientDragons.Init()
	task.spawn(function()
		local src = ReplicatedStorage:WaitForChild("AmbientDragons", 30)
		if not src then
			return
		end
		local templates = {}
		for _, m in ipairs(src:GetChildren()) do
			if m:IsA("Model") then
				table.insert(templates, m)
			end
		end
		if #templates == 0 then
			return
		end
		folder = Instance.new("Folder")
		folder.Name = "AmbientDragons"
		folder.Parent = workspace
		for _ = 1, COUNT do
			spawnFlyer(templates)
		end
		RunService.Heartbeat:Connect(step)
	end)
end

return AmbientDragons
