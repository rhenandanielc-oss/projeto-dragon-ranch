--!strict
-- Viagem: lista de obeliscos despertados (abre ao tocar um obelisco) e barra de canalização
-- da Pedra do Retorno. Quem confere tudo é o servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)

local TravelPanel = {}

local panel: Frame
local list: ScrollingFrame
local channel: Frame
local channelFill: Frame
local channelText: TextLabel
local channelTween: Tween? = nil

function TravelPanel.Open(currentId: number, dests: { { Id: number, Name: string, X: number, Z: number } })
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if #dests == 0 then
		Theme.label("Desperte outros obeliscos pelo mundo para poder viajar entre eles.", 15, { TextColor3 = Theme.Colors.TextDim, Size = UDim2.new(1, -8, 0, 44), Parent = list })
	end
	for i, d in ipairs(dests) do
		local dist = hrp and math.floor((Vector3.new(d.X, hrp.Position.Y, d.Z) - hrp.Position).Magnitude) or 0
		local b = Theme.button(string.format("%s  ·  %d m", d.Name, dist), { Size = UDim2.new(1, -8, 0, 48), TextSize = 16, LayoutOrder = i, Parent = list })
		b.Activated:Connect(function()
			NetClient.Fire("TravelWaypoint", d.Id)
			panel.Visible = false
		end)
	end
	panel.Visible = true
	panel:SetAttribute("FromWaypoint", currentId)
end

function TravelPanel.Channel(seconds: number, text: string)
	if channelTween then
		channelTween:Cancel()
		channelTween = nil
	end
	if seconds <= 0 then
		channel.Visible = false
		return
	end
	channel.Visible = true
	channelText.Text = text
	channelFill.Size = UDim2.fromScale(0, 1)
	local tw = TweenService:Create(channelFill, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
	channelTween = tw
	tw.Completed:Connect(function()
		if channelTween == tw then
			channel.Visible = false
		end
	end)
	tw:Play()
end

function TravelPanel.Init(screen: ScreenGui)
	panel = Theme.new("Frame", {
		Name = "TravelPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(380, 420),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.04,
		Visible = false,
		Parent = screen,
	}, { Theme.corner(14), Theme.stroke(), Theme.padding(12) })
	Theme.label("Viajar pelos obeliscos", 22, { Font = Theme.TitleFont, Size = UDim2.new(1, -50, 0, 30), Parent = panel })
	local close = Theme.button("X", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(44, 36), BackgroundColor3 = Theme.Colors.ButtonAlt, Parent = panel })
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	list = Theme.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = panel,
	}, { Theme.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

	channel = Theme.new("Frame", {
		Name = "ChannelBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -84),
		Size = UDim2.fromOffset(320, 30),
		BackgroundColor3 = Color3.fromRGB(20, 16, 24),
		Visible = false,
		Parent = screen,
	}, { Theme.corner(8), Theme.stroke() })
	channelFill = Theme.new("Frame", { BackgroundColor3 = Color3.fromRGB(110, 180, 255), Size = UDim2.fromScale(0, 1), Parent = channel }, { Theme.corner(8) })
	channelText = Theme.label("", 15, { Font = Theme.BoldFont, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextStrokeTransparency = 0.5, ZIndex = 3, Parent = channel })
end

return TravelPanel
