--!strict
-- Janela de conversa com NPCs (parte de baixo da tela; botões grandes para toque).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local NPCs = require(ReplicatedStorage.Shared.Config.NPCs)

local Dialog = {}

local frame: Frame
local nameLabel: TextLabel
local textLabel: TextLabel
local nextButton: TextButton
local lines: { string } = {}
local index = 0

local function show()
	textLabel.Text = lines[index] or ""
	nextButton.Text = index < #lines and "Continuar" or "Fechar"
end

function Dialog.Open(npcId: string)
	local def = NPCs[npcId]
	if not def then
		return
	end
	nameLabel.Text = def.Name .. "  ·  " .. def.Title
	lines = def.Lines
	index = 1
	frame.Visible = true
	show()
end

function Dialog.Init(screen: ScreenGui)
	frame = Theme.new("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(0.6, 0, 0, 170),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.04,
		Visible = false,
		ZIndex = 20,
		Parent = screen,
	}, { Theme.corner(14), Theme.stroke(), Theme.padding(14), Theme.new("UISizeConstraint", { MinSize = Vector2.new(320, 150), MaxSize = Vector2.new(720, 220) }) })
	nameLabel = Theme.label("", 22, { Font = Theme.TitleFont, TextColor3 = Theme.Colors.Accent, ZIndex = 21, Parent = frame })
	textLabel = Theme.label("", 18, { Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -90), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 21, Parent = frame })
	nextButton = Theme.button("Continuar", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(150, 46), ZIndex = 21, Parent = frame })
	nextButton.Activated:Connect(function()
		if index < #lines then
			index += 1
			show()
		else
			frame.Visible = false
		end
	end)
end

return Dialog
