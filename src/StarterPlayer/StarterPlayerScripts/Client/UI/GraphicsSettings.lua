--!strict
-- Ferramenta de qualidade gráfica (D12): Baixo, Médio, Alto e Ultra.
-- Tudo é aplicado só no cliente (Lighting e objetos locais). A escolha fica salva no perfil.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Theme = require(script.Parent.Theme)
local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)
local GraphicsConfig = require(ReplicatedStorage.Shared.Config.Graphics)

local GraphicsSettings = {}

local current = ""
local base: { [string]: any } = {}
local panel: Frame
local buttons: { [string]: TextButton } = {}
local note: TextLabel

local function remember()
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	base.Bloom = bloom and bloom.Intensity or 0
	base.Density = atm and atm.Density or 0
end

local function isDetail(inst: Instance): boolean
	local p = inst.Parent
	while p and p ~= workspace do
		if p.Name == "Detail" then
			return true
		end
		p = p.Parent
	end
	return false
end

local function applyToInstance(inst: Instance, preset: GraphicsConfig.Preset)
	if inst:IsA("BasePart") then
		if isDetail(inst) then
			inst.LocalTransparencyModifier = if preset.Details then 0 else 1
		end
	elseif inst:IsA("ParticleEmitter") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
		(inst :: any).Enabled = preset.Effects
	elseif inst:IsA("PointLight") or inst:IsA("SpotLight") then
		-- luzes pequenas de decoração apagam no Baixo
		if (inst :: any).Range < 30 then
			(inst :: any).Enabled = preset.Effects
		end
	end
end

function GraphicsSettings.Apply(id: string)
	local preset = GraphicsConfig.Presets[id]
	if not preset then
		return
	end
	current = id
	Lighting.GlobalShadows = preset.Shadows
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Enabled = preset.Bloom > 0
		bloom.Intensity = base.Bloom * preset.Bloom
	end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then
		rays.Enabled = preset.SunRays
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		cc.Enabled = preset.ColorCorrection
	end
	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		dof.Enabled = preset.DepthOfField
	end
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		atm.Density = base.Density * preset.Atmosphere
	end
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds.Enabled = preset.Clouds
	end
	local world = workspace:FindFirstChild("World")
	if world then
		for _, d in ipairs(world:GetDescendants()) do
			applyToInstance(d, preset)
		end
	end
	for _, folderName in ipairs({ "Hub", "Farms" }) do
		local f = workspace:FindFirstChild(folderName)
		if f then
			for _, d in ipairs(f:GetDescendants()) do
				applyToInstance(d, preset)
			end
		end
	end
	for k, b in pairs(buttons) do
		b.BackgroundColor3 = if k == id then Theme.Colors.Button else Theme.Colors.ButtonAlt
	end
	if note then
		note.Text = preset.Text
	end
end

function GraphicsSettings.Current(): string
	return current
end

-- Nível inicial: celular começa no Médio, computador no Alto
function GraphicsSettings.DefaultId(): string
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Medium"
	end
	return "High"
end

function GraphicsSettings.Init(screen: ScreenGui)
	remember()
	-- objetos que chegam pelo streaming recebem o nível atual
	workspace.DescendantAdded:Connect(function(inst)
		local preset = GraphicsConfig.Presets[current]
		if preset then
			applyToInstance(inst, preset)
		end
	end)
	local _ = CollectionService

	local toggle = Theme.button("Gráficos", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 160, 1, -12),
		Size = UDim2.fromOffset(120, 44),
		TextSize = 16,
		BackgroundColor3 = Theme.Colors.ButtonAlt,
		Parent = screen,
	})
	panel = Theme.new("Frame", {
		Name = "GraphicsPanel",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -66),
		Size = UDim2.fromOffset(340, 210),
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		Parent = screen,
	}, { Theme.corner(12), Theme.stroke(), Theme.padding(12) })
	Theme.label("Qualidade gráfica", 22, { Font = Theme.TitleFont, Parent = panel })
	local row = Theme.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 44), Parent = panel }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, id in ipairs(GraphicsConfig.Order) do
		local b = Theme.button(GraphicsConfig.Presets[id].DisplayName, { LayoutOrder = i, Size = UDim2.new(0.25, -5, 1, 0), TextSize = 15, Parent = row })
		buttons[id] = b
		b.Activated:Connect(function()
			GraphicsSettings.Apply(id)
			NetClient.Fire("SetGraphics", id)
		end)
	end
	note = Theme.label("", 14, { Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 0, 60), TextColor3 = Theme.Colors.TextDim, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	GraphicsSettings.Apply(GraphicsSettings.DefaultId())
end

return GraphicsSettings
