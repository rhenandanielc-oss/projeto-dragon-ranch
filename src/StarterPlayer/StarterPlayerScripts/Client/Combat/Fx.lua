--!strict
-- Efeitos visuais do combate (só aparência; quem decide dano e acerto é o servidor).

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Elements = require(ReplicatedStorage.Shared.Config.Elements)
local CharacterAnim = require(script.Parent.CharacterAnim)

local function charOf(d: { [string]: any }): Model?
	local plr = d.Player
	return if typeof(plr) == "Instance" and plr:IsA("Player") then plr.Character else nil
end

local Fx = {}

local folder: Folder

local function elementColor(element: string?): Color3
	local first = element and string.split(element, "+")[1] or "Fire"
	local def = (Elements :: any)[first]
	return def and def.Color or Color3.fromRGB(255, 160, 80)
end

local function part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = folder
	return p
end

local function fadeOut(p: BasePart, t: number, grow: Vector3?)
	local goal: { [string]: any } = { Transparency = 1 }
	if grow then
		goal.Size = grow
	end
	TweenService:Create(p, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
	Debris:AddItem(p, t + 0.05)
end

local function damageNumber(pos: Vector3, text: string, color: Color3)
	local anchor = part({ Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CFrame = CFrame.new(pos + Vector3.new(math.random() * 2 - 1, 1, math.random() * 2 - 1)) })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 40)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 140
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = gui
	TweenService:Create(anchor, TweenInfo.new(0.9), { CFrame = anchor.CFrame + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

local function burst(pos: Vector3, color: Color3, size: number, t: number)
	local s = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1) * size * 0.3, Color = color, Transparency = 0.2, CFrame = CFrame.new(pos) })
	fadeOut(s, t, Vector3.new(1, 1, 1) * size)
end

local function ring(pos: Vector3, color: Color3, radius: number, t: number, height: number?)
	local r = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(height or 0.4, 2, 2), Color = color, Transparency = 0.25, CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)) })
	fadeOut(r, t, Vector3.new(height or 0.4, radius * 2, radius * 2))
end

local function travel(p: BasePart, from: Vector3, to: Vector3, t: number, onDone: (() -> ())?)
	p.CFrame = CFrame.new(from)
	local tw = TweenService:Create(p, TweenInfo.new(math.max(0.05, t), Enum.EasingStyle.Linear), { CFrame = CFrame.new(to) })
	tw.Completed:Connect(function()
		p:Destroy()
		if onDone then
			onDone()
		end
	end)
	tw:Play()
end

local arrowParams = RaycastParams.new()
arrowParams.FilterType = Enum.RaycastFilterType.Exclude
arrowParams.IgnoreWater = true

local function arrow(origin: Vector3, velocity: Vector3, gravity: number)
	local a = part({ Size = Vector3.new(0.15, 0.15, 2.4), Material = Enum.Material.Wood, Color = Color3.fromRGB(150, 110, 70), CFrame = CFrame.lookAt(origin, origin + velocity) })
	local tip = part({ Size = Vector3.new(0.25, 0.25, 0.5), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 205), CFrame = a.CFrame * CFrame.new(0, 0, -1.3) })
	local pos, vel, life = origin, velocity, 0
	arrowParams.FilterDescendantsInstances = { folder }
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function(dt)
		life += dt
		local nv = vel - Vector3.new(0, gravity * dt, 0)
		local step = (vel + nv) * 0.5 * dt
		local hit = workspace:Raycast(pos, step, arrowParams)
		if hit or life > 2 then
			if conn then
				conn:Disconnect()
			end
			if hit then
				a.CFrame = CFrame.lookAt(hit.Position - step.Unit * 1, hit.Position + step.Unit)
				tip.CFrame = a.CFrame * CFrame.new(0, 0, -1.3)
				Debris:AddItem(a, 4)
				Debris:AddItem(tip, 4)
			else
				a:Destroy()
				tip:Destroy()
			end
			return
		end
		pos += step
		vel = nv
		a.CFrame = CFrame.lookAt(pos, pos + vel)
		tip.CFrame = a.CFrame * CFrame.new(0, 0, -1.3)
	end)
end

local HANDLERS: { [string]: (data: { [string]: any }) -> () } = {
	Hit = function(d)
		local text = d.Text or tostring(d.Amount or "")
		if text ~= "" and text ~= "0" then
			damageNumber(d.Pos, text, d.Color or Color3.new(1, 1, 1))
		end
	end,
	Slash = function(d)
		local cf: CFrame = d.CF
		local combo = d.Combo or 1
		CharacterAnim.Play(charOf(d), "Slash", combo)
		-- rastro curvo da lâmina (aparece em sequência, acompanhando o golpe)
		local tilt = math.rad(if combo == 2 then -20 elseif combo == 3 then 80 else 20)
		local from, to = if combo == 2 then -70 else 70, if combo == 2 then 70 else -70
		local n = 9
		for i = 0, n - 1 do
			local t = i / (n - 1)
			local ang = math.rad(from + (to - from) * t)
			local seg = cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, tilt) * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -4.2)
			task.delay(0.1 + t * 0.12, function()
				local w = part({ Size = Vector3.new(1.5, 0.08, 1.5 - math.abs(t - 0.5) * 1.6), Color = Color3.fromRGB(225, 235, 255), Transparency = 0.3, CFrame = seg })
				fadeOut(w, 0.22, Vector3.new(1.6, 0.04, 0.2))
			end)
		end
	end,
	Spin = function(d)
		CharacterAnim.Play(charOf(d), "Spin")
		ring(d.Pos, Color3.fromRGB(235, 240, 255), d.Radius or 11, 0.35, 0.6)
	end,
	Arrow = function(d)
		CharacterAnim.Play(charOf(d), "Shoot")
		arrow(d.Origin, d.Velocity, d.Gravity or 30)
	end,
	Bite = function(d)
		burst(d.Pos, Color3.fromRGB(255, 240, 220), 4, 0.2)
	end,
	EnemyAttack = function(d)
		local p = (d.Pos :: Vector3) + (d.Dir :: Vector3) * 3
		burst(p, Color3.fromRGB(255, 120, 100), 3, 0.18)
	end,
	Death = function(d)
		for _ = 1, 6 do
			local off = Vector3.new(math.random() * 4 - 2, math.random() * 3, math.random() * 4 - 2)
			local s = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.SmoothPlastic, Size = Vector3.new(2, 2, 2), Color = Color3.fromRGB(200, 196, 190), Transparency = 0.3, CFrame = CFrame.new((d.Pos :: Vector3) + off) })
			TweenService:Create(s, TweenInfo.new(0.9), { CFrame = s.CFrame + Vector3.new(0, 4, 0) }):Play()
			fadeOut(s, 0.9, Vector3.new(5, 5, 5))
		end
	end,
	Power = function(d)
		local color = elementColor(d.Element)
		local kind = d.Kind
		-- raridade: Raro+ ganha um anel dourado; Lendário+ ganha brilho extra
		local tier = d.Tier or 1
		local at: Vector3? = d.To or d.From
		if tier >= 3 and at then
			task.delay(0.15, function()
				ring(at :: Vector3, if tier >= 7 then Color3.fromRGB(20, 255, 220) elseif tier >= 5 then Color3.fromRGB(255, 200, 60) else Color3.fromRGB(150, 190, 255), (d.Radius or 10) * 1.2, 0.6, 0.3)
			end)
		end
		if tier >= 5 and at then
			burst(at :: Vector3, Color3.fromRGB(255, 240, 200), (d.Radius or 10) * 0.8, 0.5)
		end
		if kind == "Projectile" then
			local ball = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Color = color })
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 16
			light.Brightness = 3
			light.Parent = ball
			travel(ball, d.From, d.To, d.Time or 0.4, function()
				burst(d.To, color, (d.Radius or 10) * 2, 0.45)
			end)
		elseif kind == "Cone" then
			local from: Vector3 = d.From
			local dir: Vector3 = d.Dir
			local range = d.Range or 30
			for i = 1, 7 do
				local spread = math.rad((d.Angle or 30) / 2) * (math.random() * 2 - 1)
				local dd = CFrame.fromAxisAngle(Vector3.yAxis, spread) * dir
				local b = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), Color = color, Transparency = 0.2 })
				local to = from + dd * range * (0.6 + math.random() * 0.4)
				task.delay(i * 0.03, function()
					travel(b, from, to, 0.35)
					TweenService:Create(b, TweenInfo.new(0.35), { Size = Vector3.new(7, 7, 7), Transparency = 0.8 }):Play()
				end)
			end
		elseif kind == "Line" then
			local from: Vector3 = d.From
			local to: Vector3 = d.To
			local len = (to - from).Magnitude
			local beam = part({ Size = Vector3.new((d.Radius or 3) * 0.8, (d.Radius or 3) * 0.8, len), Color = color, Transparency = 0.15, CFrame = CFrame.lookAt((from + to) / 2, to) })
			fadeOut(beam, 0.35)
		elseif kind == "Area" then
			local center: Vector3 = d.To
			ring(center, color, d.Radius or 15, 0.6, 1.2)
			task.delay(0.3, function()
				burst(center, color, (d.Radius or 15) * 1.2, 0.5)
			end)
		elseif kind == "Heal" then
			local t = d.Time or 4
			local disc = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, (d.Radius or 20) * 2, (d.Radius or 20) * 2), Color = Color3.fromRGB(120, 230, 160), Transparency = 0.6, CFrame = CFrame.new(d.To) * CFrame.Angles(0, 0, math.rad(90)) })
			local pe = Instance.new("ParticleEmitter")
			pe.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
			pe.Rate = 60
			pe.Lifetime = NumberRange.new(0.6, 1)
			pe.Speed = NumberRange.new(30, 40)
			pe.EmissionDirection = Enum.NormalId.Left
			pe.Size = NumberSequence.new(0.3)
			pe.Parent = disc
			fadeOut(disc, t)
		elseif kind == "Self" then
			local shell = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.ForceField, Size = Vector3.new(1, 1, 1) * (d.Radius or 6) * 2, Color = color, Transparency = 0, CFrame = CFrame.new(d.To) })
			Debris:AddItem(shell, d.Time or 5)
		end
	end,
}

function Fx.Play(kind: string, data: { [string]: any })
	local h = HANDLERS[kind]
	if h then
		local ok, err = pcall(h, data)
		if not ok then
			warn("[Fx] " .. tostring(err))
		end
	end
end

function Fx.Init()
	folder = Instance.new("Folder")
	folder.Name = "ClientFx"
	folder.Parent = workspace
end

return Fx
