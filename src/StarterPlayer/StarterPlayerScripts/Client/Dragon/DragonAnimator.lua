--!strict
-- Anima os dragões (só visual, em cada cliente): respiração, cabeça olhando em volta,
-- cauda balançando, patas andando, asas batendo no voo e planando, corpo inclinando nas curvas.
-- Usa as juntas J_* criadas pelo DragonRig. Vale para companheiros, dragões da fazenda, os
-- soltos para passear e os dragões selvagens do céu (AmbientDragons).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local DragonAnimator = {}

type Joints = { [string]: Motor6D }
type Anim = {
	model: Model,
	root: BasePart,
	joints: Joints,
	phase: number, -- passada
	flap: number, -- batida de asa
	t: number,
	lastPos: Vector3,
	speed: number,
	vy: number,
	yawRate: number,
	lastLook: Vector3,
	fly: number, -- 0..1 mistura chão/voo
	seed: number,
	size: number,
}

local anims: { [Model]: Anim } = {}
local MAX_DIST = 420

local function collect(model: Model): Joints
	local j: Joints = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and string.sub(d.Name, 1, 2) == "J_" then
			j[string.sub(d.Name, 3)] = d
		end
	end
	return j
end

local function track(model: Instance)
	if not model:IsA("Model") or anims[model] then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("Root") :: BasePart?
	if not root then
		-- o modelo pode chegar aos poucos (streaming): tenta de novo
		task.delay(1, function()
			if model.Parent then
				track(model)
			end
		end)
		return
	end
	local joints = collect(model)
	if next(joints) == nil then
		task.delay(1, function()
			if model.Parent and not anims[model] then
				track(model)
			end
		end)
		return
	end
	local _, size = model:GetBoundingBox()
	anims[model] = {
		model = model,
		root = root,
		joints = joints,
		phase = math.random() * 10,
		flap = math.random() * 10,
		t = math.random() * 10,
		lastPos = root.Position,
		speed = 0,
		vy = 0,
		yawRate = 0,
		lastLook = root.CFrame.LookVector,
		fly = 0,
		seed = math.random() * 100,
		size = math.max(4, size.Y),
	}
end

local function untrack(model: Instance)
	anims[model :: Model] = nil
end

local function A(x: number, y: number, z: number): CFrame
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

local function set(j: Motor6D?, cf: CFrame)
	if j then
		j.Transform = cf
	end
end

local function step(dt: number)
	if dt <= 0 then
		return
	end
	local camPos = workspace.CurrentCamera.CFrame.Position
	for model, a in pairs(anims) do
		if not model.Parent or not a.root.Parent then
			anims[model] = nil
			continue
		end
		local pos = a.root.Position
		local dist = (pos - camPos).Magnitude
		if dist > MAX_DIST then
			a.lastPos = pos
			continue
		end
		-- velocidade medida pela posição (funciona com física, ancorado ou PivotTo)
		local v = (pos - a.lastPos) / dt
		a.lastPos = pos
		if v.Magnitude > 400 then
			v = Vector3.zero -- teleporte
		end
		local flat = Vector3.new(v.X, 0, v.Z).Magnitude
		a.speed += (flat - a.speed) * math.min(1, dt * 6)
		a.vy += (v.Y - a.vy) * math.min(1, dt * 4)
		local look = a.root.CFrame.LookVector
		local turn = a.lastLook:Cross(look).Y / dt
		a.lastLook = look
		a.yawRate += (math.clamp(turn, -3, 3) - a.yawRate) * math.min(1, dt * 5)
		local mode = model:GetAttribute("Mode")
		local flying = mode == "Fly" or model:GetAttribute("Flying") == true
		a.fly += ((if flying then 1 else 0) - a.fly) * math.min(1, dt * 3)
		a.t += dt
		local scale = 12 / a.size -- dragões grandes se mexem mais devagar

		local J = a.joints
		local t = a.t
		if a.fly > 0.5 then
			------------------------------------------------------------------
			-- VOO: asas batem (mais forte subindo, quase paradas planando)
			------------------------------------------------------------------
			local climb = math.clamp(a.vy / 30, -1, 1)
			local effort = math.clamp(0.55 + climb * 0.6 - math.clamp(a.speed / 160, 0, 0.35), 0.12, 1)
			local glide = math.sin(t * 0.35 + a.seed) > 0.55 and climb < 0.2 -- de vez em quando plana
			if glide then
				effort = 0.08
			end
			a.flap += dt * (3.2 + effort * 2.4) * math.clamp(scale, 0.6, 1.4)
			local w = math.sin(a.flap)
			local amp = 12 + 40 * effort
			local up = w * amp + 8 -- asas levemente acima da linha
			set(J.WingR, A(0, 0, up))
			set(J.WingL, A(0, 0, -up))
			set(J.Wings, A(w * amp * 0.4, 0, 0))
			-- corpo sobe e desce com a batida, inclina para subir/descer e nas curvas
			local bob = -w * 0.35 * effort * a.size / 12
			local pitch = math.clamp(a.vy * 0.5, -25, 25)
			local roll = math.clamp(-a.yawRate * 25, -35, 35)
			set(J.Body, CFrame.new(0, bob, 0) * A(pitch, 0, roll))
			set(J.Head, A(-pitch * 0.6 + math.sin(t * 1.3) * 3, math.sin(t * 0.7 + a.seed) * 6 - roll * 0.2, 0))
			-- cauda: ondula e compensa a curva
			set(J.Tail, A(math.sin(a.flap - 1) * 6 * effort - pitch * 0.4, math.sin(t * 1.6 + a.seed) * 8 + roll * 0.4, 0))
			-- patas recolhidas para trás
			set(J.LegsF, A(-55, 0, 0))
			set(J.LegsB, A(-65, 0, 0))
			set(J.Legs, A(-60, 0, 0))
		else
			------------------------------------------------------------------
			-- CHÃO: parado (respira, olha em volta) ou andando/correndo
			------------------------------------------------------------------
			local moving = math.clamp(a.speed / 8, 0, 1)
			local stride = 1.6 + a.speed / math.max(3, a.size * 0.35)
			a.phase += dt * stride * moving * math.clamp(scale, 0.6, 1.5) * 2.2
			local s = math.sin(a.phase)
			local breathe = math.sin(t * 1.4 + a.seed)
			local legAmp = 24 * moving
			set(J.LegsF, A(s * legAmp, 0, 0))
			set(J.LegsB, A(-s * legAmp, 0, 0))
			set(J.Legs, A(s * legAmp * 0.8, 0, 0))
			local bob = math.abs(math.cos(a.phase)) * 0.25 * moving * a.size / 12 + breathe * 0.06 * a.size / 12
			local sway = math.sin(a.phase) * 3 * moving
			local roll = math.clamp(-a.yawRate * 8, -10, 10)
			set(J.Body, CFrame.new(0, bob, 0) * A(breathe * 0.8, sway, roll))
			-- cabeça: acompanha a passada; parado, olha em volta devagar
			local lookAround = (1 - moving) * math.sin(t * 0.4 + a.seed) * 18
			local nod = math.sin(a.phase * 2) * 4 * moving + breathe * 1.5
			set(J.Head, A(nod, lookAround - sway, 0))
			-- cauda balança de um lado para o outro
			set(J.Tail, A(math.sin(t * 0.9 + a.seed) * 3, math.sin(t * (1 + moving * 2) + a.seed) * (8 + 8 * moving), 0))
			-- asas fechadas, mexendo de leve (às vezes se esticam)
			local stretch = math.max(0, math.sin(t * 0.13 + a.seed) - 0.92) * 220
			local wingRest = -6 + breathe * 2 + stretch
			set(J.WingR, A(0, 0, wingRest + s * 3 * moving))
			set(J.WingL, A(0, 0, -wingRest - s * 3 * moving))
			set(J.Wings, A(breathe * 2, 0, 0))
		end
	end
end

function DragonAnimator.Track(model: Model)
	track(model)
end

function DragonAnimator.Init()
	for _, m in ipairs(CollectionService:GetTagged("AnimatedDragon")) do
		track(m)
	end
	CollectionService:GetInstanceAddedSignal("AnimatedDragon"):Connect(track)
	CollectionService:GetInstanceRemovedSignal("AnimatedDragon"):Connect(untrack)
	RunService.PreSimulation:Connect(step)
end

return DragonAnimator
