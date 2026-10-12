--!strict
-- Bússola no topo da tela (D8): aponta para a sua fazenda e para o Hub, com a distância.
-- O mapa completo existe só no Hub (mesa do cartógrafo).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local Compass = {}

local WIDTH = 360
local FOV = math.rad(120) -- ângulo visível na faixa

local function marker(text: string, color: Color3, parent: Instance): TextLabel
	return Theme.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(84, 30),
		BackgroundTransparency = 1,
		Font = Theme.BoldFont,
		TextSize = 13,
		TextColor3 = color,
		TextStrokeTransparency = 0.4,
		Text = text,
		Parent = parent,
	})
end

function Compass.Init(screen: ScreenGui)
	local player = Players.LocalPlayer
	local bar = Theme.new("Frame", {
		Name = "Compass",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(WIDTH, 34),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.35,
		ClipsDescendants = true,
		Parent = screen,
	}, { Theme.corner(8), Theme.stroke(nil, 1) })
	local cardinals = {}
	for _, c in ipairs({ { "N", 0 }, { "L", 90 }, { "S", 180 }, { "O", 270 } }) do
		cardinals[c[1]] = { label = marker(c[1], Theme.Colors.TextDim, bar), deg = c[2] }
	end
	local farmMark = marker("Fazenda", Theme.Colors.Good, bar)
	local hubMark = marker("Hub", Theme.Colors.Accent, bar)

	local function place(label: TextLabel, bearing: number, heading: number): boolean
		local d = (bearing - heading + math.pi) % (2 * math.pi) - math.pi
		if math.abs(d) > FOV / 2 then
			label.Visible = false
			return false
		end
		label.Visible = true
		label.Position = UDim2.new(0.5, d / (FOV / 2) * (WIDTH / 2), 0, 2)
		return true
	end

	-- direção no plano: 0 = norte (-Z), aumenta no sentido horário (leste = +X)
	local function bearingTo(from: Vector3, to: Vector3): number
		local v = to - from
		return math.atan2(v.X, -v.Z)
	end

	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not cam or not root then
			return
		end
		local look = cam.CFrame.LookVector
		local heading = math.atan2(look.X, -look.Z)
		for _, c in pairs(cardinals) do
			place(c.label, math.rad(c.deg), heading)
		end
		local pos = root.Position
		local hub = Rules.World.HubPosition
		local dHub = (Vector3.new(hub.X, 0, hub.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
		hubMark.Text = string.format("Hub\n%dm", math.floor(dHub))
		place(hubMark, bearingTo(pos, hub), heading)
		local farm = player:GetAttribute("FarmPosition")
		if typeof(farm) == "Vector3" then
			local dFarm = (Vector3.new(farm.X, 0, farm.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
			farmMark.Text = string.format("Fazenda\n%dm", math.floor(dFarm))
			place(farmMark, bearingTo(pos, farm), heading)
		else
			farmMark.Visible = false
		end
	end)
end

return Compass
