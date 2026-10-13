--!strict
-- Animações procedurais dos personagens (R15), feitas em cada cliente para TODOS os jogadores:
-- golpes de espada (3 do combo), Golpe Giratório, bloqueio, mira e disparo do arco.
-- Não precisa de animações publicadas: o laço sobrepõe Motor6D.Transform logo depois do
-- Animator (PreSimulation), misturando com a animação de andar/correr do Roblox.
-- É só visual; quem decide dano e acerto é o servidor.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CharacterAnim = {}

type Action = { kind: string, t0: number, dur: number, combo: number }
type Rig = {
	char: Model,
	root: Motor6D?,
	waist: Motor6D?,
	neck: Motor6D?,
	rs: Motor6D?,
	re: Motor6D?,
	ls: Motor6D?,
	le: Motor6D?,
	action: Action?,
	draw: number, -- 0..1 peso da pose de mira (suavizado)
	block: number,
}

local rigs: { [Model]: Rig } = {}
local localDraw: () -> (boolean, number, number) = function()
	return false, 0, 0
end

local function rad(d: number): number
	return math.rad(d)
end

local function A(x: number, y: number, z: number): CFrame
	return CFrame.Angles(rad(x), rad(y), rad(z))
end

local function motor(char: Model, part: string, name: string): Motor6D?
	local p = char:FindFirstChild(part)
	local m = p and p:FindFirstChild(name)
	return if m and m:IsA("Motor6D") then m else nil
end

local function rigFor(char: Model): Rig?
	local r = rigs[char]
	if r and r.rs and r.rs.Parent then
		return r
	end
	if not char:FindFirstChild("UpperTorso") then
		return nil
	end
	r = {
		char = char,
		root = motor(char, "LowerTorso", "Root"),
		waist = motor(char, "UpperTorso", "Waist"),
		neck = motor(char, "Head", "Neck"),
		rs = motor(char, "RightUpperArm", "RightShoulder"),
		re = motor(char, "RightLowerArm", "RightElbow"),
		ls = motor(char, "LeftUpperArm", "LeftShoulder"),
		le = motor(char, "LeftLowerArm", "LeftElbow"),
		action = if r then r.action else nil,
		draw = 0,
		block = 0,
	}
	rigs[char] = r
	return r
end

local function ease(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- peso: entra rápido, sai suave
local function envelope(p: number, inT: number, outT: number): number
	if p < inT then
		return ease(p / inT)
	elseif p > 1 - outT then
		return ease((1 - p) / outT)
	end
	return 1
end

local function apply(m: Motor6D?, cf: CFrame, w: number)
	if m and w > 0.001 then
		m.Transform = m.Transform:Lerp(cf, math.clamp(w, 0, 1))
	end
end

local function addTo(m: Motor6D?, cf: CFrame)
	if m then
		m.Transform = m.Transform * cf
	end
end

-- Golpe de espada: preparação (0–35%), golpe (35–65%), volta.
local function slash(r: Rig, p: number, combo: number)
	local w = envelope(p, 0.12, 0.3)
	local strike = ease((p - 0.3) / 0.35)
	if combo == 3 then
		-- golpe de cima para baixo
		local pitch = 170 - 135 * strike
		apply(r.rs, A(pitch, 15, 0), w)
		apply(r.re, A(25 - 20 * strike, 0, 0), w)
		apply(r.ls, A(30 + 40 * strike, -20, 0), w * 0.6)
		apply(r.waist, A(8 - 22 * strike, 0, 0), w)
	else
		local dir = if combo == 2 then -1 else 1
		-- combo 1: da direita para a esquerda; combo 2: volta (revés)
		local yaw = dir * (-85 + 140 * strike)
		apply(r.rs, A(95, yaw, 0), w)
		apply(r.re, A(20 * (1 - strike), 0, 0), w)
		apply(r.ls, A(35, 0, -15), w * 0.6)
		apply(r.waist, A(0, dir * (-35 + 65 * strike), 0), w)
	end
end

local function spin(r: Rig, p: number)
	local w = envelope(p, 0.1, 0.15)
	apply(r.rs, A(0, 0, 95), w)
	apply(r.ls, A(0, 0, -95), w)
	apply(r.waist, A(-6, 0, 0), w)
	addTo(r.root, CFrame.Angles(0, -math.pi * 2 * ease(p), 0))
end

-- Pose do arco. aimPitch em graus (câmera para cima/baixo), pull 0..1 (carga).
local function bowPose(r: Rig, w: number, aimPitch: number, pull: number)
	-- corpo de lado para o alvo, braço esquerdo esticado segurando o arco
	apply(r.waist, A(0, -55, 0), w)
	apply(r.neck, A(0, 50, 0), w)
	apply(r.ls, A(0, 55, 0) * A(90 + aimPitch, 0, 0), w)
	apply(r.le, A(0, 0, 0), w)
	-- braço direito puxa a corda até o queixo (cotovelo para trás, longe do alvo)
	local back = 85 + 40 * pull
	apply(r.rs, A(0, -back, 0) * A(90 + aimPitch * 0.6, 0, 0) * A(0, 90, 0), w)
	apply(r.re, A(70 + 60 * pull, 0, 0), w)
end

local function blockPose(r: Rig, w: number)
	apply(r.rs, A(80, 55, 0), w)
	apply(r.re, A(50, 0, 0), w)
	apply(r.ls, A(40, 0, -10), w * 0.5)
end

local function step(dt: number)
	local now = os.clock()
	local lp = Players.LocalPlayer
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if not char then
			continue
		end
		local r = rigFor(char)
		if not r then
			continue
		end
		-- mira do arco
		local drawing, pull, pitch = false, 0, 0
		if plr == lp then
			drawing, pull, pitch = localDraw()
		elseif char:GetAttribute("BowDraw") == true then
			drawing, pull, pitch = true, 0.6, 0
		end
		local mounted = char:GetAttribute("Mounted") == true
		r.draw += ((if drawing and not mounted then 1 else 0) - r.draw) * math.min(1, dt * 14)
		local blocking = char:GetAttribute("Blocking") == true and not mounted
		r.block += ((if blocking then 1 else 0) - r.block) * math.min(1, dt * 14)

		local wm = char:FindFirstChild("WeaponModel")
		local gp = wm and wm:FindFirstChild("Grip")
		local grip = gp and gp:FindFirstChild("WeaponGrip") :: Motor6D?
		local isBow = char:GetAttribute("Weapon") == "Bow"
		local swordW = r.block
		if r.draw > 0.01 then
			bowPose(r, r.draw, pitch, pull)
		end
		if r.block > 0.01 then
			blockPose(r, r.block)
		end
		local a = r.action
		if a then
			local p = (now - a.t0) / a.dur
			local freeze = char:GetAttribute("AnimDebugP") -- só para conferir poses no Studio
			if typeof(freeze) == "number" and RunService:IsStudio() then
				p = freeze
			end
			if p >= 1 then
				r.action = nil
			elseif a.kind == "Slash" then
				slash(r, p, a.combo)
				swordW = math.max(swordW, envelope(p, 0.12, 0.3))
			elseif a.kind == "Spin" then
				spin(r, p)
				swordW = math.max(swordW, envelope(p, 0.1, 0.15))
			elseif a.kind == "Shoot" then
				-- recuo curto depois de soltar a flecha
				local w = envelope(p, 0.05, 0.6)
				apply(r.rs, A(0, -150, 0) * A(90, 0, 0) * A(0, 90, 0), w * 0.8)
				apply(r.ls, A(0, 55, 0) * A(95, 0, 0), w)
				apply(r.waist, A(0, -55, 0), w)
			end
		end
		-- encaixe da arma: lâmina acompanha o braço nos golpes; arco fica em pé ao mirar
		if grip then
			if isBow then
				local bw = r.draw
				local a2 = r.action
				if a2 and a2.kind == "Shoot" then
					bw = math.max(bw, 1 - (now - a2.t0) / a2.dur)
				end
				grip.Transform = CFrame.identity:Lerp(A(90, 0, 0), math.clamp(bw, 0, 1))
			else
				grip.Transform = CFrame.identity:Lerp(A(-80, 0, 0), math.clamp(swordW, 0, 1))
			end
		end
	end
	for char in pairs(rigs) do
		if not char.Parent then
			rigs[char] = nil
		end
	end
end

local DUR = { Slash = 0.36, Spin = 0.5, Shoot = 0.35 }

-- Toca uma ação no personagem (todos os clientes chamam ao receber o Fx do servidor).
function CharacterAnim.Play(char: Model?, kind: string, combo: number?)
	if not char then
		return
	end
	local r = rigFor(char)
	if not r then
		return
	end
	r.action = { kind = kind, t0 = os.clock(), dur = DUR[kind] or 0.4, combo = combo or 1 }
end

-- getDraw(): (mirando/puxando?, carga 0..1, inclinação da mira em graus) do jogador local.
function CharacterAnim.Init(getDraw: () -> (boolean, number, number))
	localDraw = getDraw
	RunService.PreSimulation:Connect(step)
end

return CharacterAnim
