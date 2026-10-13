--!strict
-- Tempestade (só visual no cliente): céu escuro, chuva em volta da câmera e relâmpagos.
-- O servidor liga/desliga com workspace:SetAttribute("Storm", true/false).

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Weather = {}

local rainPart: Part? = nil
local saved: { [string]: any }? = nil
local flashing = false

local function setStorm(on: boolean)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if on then
		if not saved then
			saved = {
				Brightness = Lighting.Brightness,
				OutdoorAmbient = Lighting.OutdoorAmbient,
				Density = atmo and atmo.Density or 0,
				Haze = atmo and atmo.Haze or 0,
				AtmoColor = atmo and atmo.Color or Color3.new(1, 1, 1),
			}
		end
		local ti = TweenInfo.new(6)
		TweenService:Create(Lighting, ti, { Brightness = 1.1, OutdoorAmbient = Color3.fromRGB(90, 96, 110) }):Play()
		if atmo then
			TweenService:Create(atmo, ti, { Density = 0.45, Haze = 2.5, Color = Color3.fromRGB(150, 156, 170) }):Play()
		end
		if not rainPart then
			local p = Instance.new("Part")
			p.Name = "Rain"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Transparency = 1
			p.Size = Vector3.new(160, 1, 160)
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			e.Color = ColorSequence.new(Color3.fromRGB(190, 200, 220))
			e.LightEmission = 0.2
			e.Transparency = NumberSequence.new(0.35)
			e.Size = NumberSequence.new(0.12)
			e.Squash = NumberSequence.new(4)
			e.Rate = 900
			e.Lifetime = NumberRange.new(1.2, 1.6)
			e.Speed = NumberRange.new(90, 110)
			e.EmissionDirection = Enum.NormalId.Bottom
			e.Orientation = Enum.ParticleOrientation.VelocityParallel
			e.Parent = p
			p.Parent = workspace
			rainPart = p
		end
	else
		if saved then
			local ti = TweenInfo.new(8)
			TweenService:Create(Lighting, ti, { Brightness = saved.Brightness, OutdoorAmbient = saved.OutdoorAmbient }):Play()
			if atmo then
				TweenService:Create(atmo, ti, { Density = saved.Density, Haze = saved.Haze, Color = saved.AtmoColor }):Play()
			end
			saved = nil
		end
		if rainPart then
			rainPart:Destroy()
			rainPart = nil
		end
	end
end

local function flash()
	if flashing then
		return
	end
	flashing = true
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.5
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(0.35), { Brightness = 0 }):Play()
	task.delay(0.4, function()
		cc:Destroy()
		flashing = false
	end)
end

function Weather.Init()
	workspace:GetAttributeChangedSignal("Storm"):Connect(function()
		setStorm(workspace:GetAttribute("Storm") == true)
	end)
	if workspace:GetAttribute("Storm") then
		setStorm(true)
	end
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		local p = rainPart
		if p then
			local cam = workspace.CurrentCamera
			p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 60, 0))
			acc += dt
			if acc > 6 and math.random() < dt * 0.15 then
				acc = 0
				flash()
			end
		end
	end)
end

return Weather
