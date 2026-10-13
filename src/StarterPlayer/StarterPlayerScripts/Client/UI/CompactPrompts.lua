--!strict
-- Ações do dragão numa lista pequena ao lado dele ("[V] Montar", "[E] Alimentar"...),
-- em vez de várias caixas grandes empilhadas no meio da tela.
-- Vale para os ProximityPrompts com Style = Custom. As teclas continuam funcionando
-- normalmente; no celular cada linha é um botão.

local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)

local CompactPrompts = {}

type Board = { gui: BillboardGui, list: Frame, rows: { [ProximityPrompt]: Frame } }
local boards: { [Instance]: Board } = {}
local screenRef: ScreenGui

local function keyText(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "Toque"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return string.gsub(prompt.GamepadKeyCode.Name, "Button", "")
	end
	local k = prompt.KeyboardKeyCode.Name
	return k
end

local function boardFor(adornee: Instance): Board
	local b = boards[adornee]
	if b then
		return b
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "CompactPrompt"
	gui.Adornee = adornee
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(150, 130)
	gui.SizeOffset = Vector2.new(0.9, 0) -- ao lado do dragão, não em cima
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Parent = screenRef.Parent
	local list = Theme.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui }, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	b = { gui = gui, list = list, rows = {} }
	boards[adornee] = b
	return b
end

local function shown(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
		return
	end
	local adornee = prompt.Parent
	if not adornee then
		return
	end
	local b = boardFor(adornee)
	if b.rows[prompt] then
		b.rows[prompt]:Destroy()
	end
	local row = Theme.new("TextButton", {
		Name = prompt.Name,
		AutoButtonColor = true,
		Text = "",
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.25,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = (prompt:GetAttribute("Order") :: number?) or 0,
		Parent = b.list,
	}, { Theme.corner(6) })
	local key = keyText(prompt, inputType)
	Theme.new("TextLabel", {
		BackgroundColor3 = Color3.fromRGB(245, 235, 210),
		Text = key,
		TextColor3 = Color3.fromRGB(40, 30, 20),
		Font = Theme.BoldFont,
		TextSize = 12,
		Size = UDim2.fromOffset(if #key > 2 then 40 else 18, 18),
		Position = UDim2.fromOffset(2, 2),
		Parent = row,
	}, { Theme.corner(4) })
	Theme.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = prompt.ActionText,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.6,
		Font = Theme.BoldFont,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(if #key > 2 then 46 else 24, 0),
		Size = UDim2.new(1, -26, 1, 0),
		Parent = row,
	})
	local btn = row :: TextButton
	btn.MouseButton1Down:Connect(function()
		if UserInputService.TouchEnabled then
			prompt:InputHoldBegin()
		end
	end)
	btn.MouseButton1Up:Connect(function()
		if UserInputService.TouchEnabled then
			prompt:InputHoldEnd()
		end
	end)
	b.rows[prompt] = row :: Frame
end

local function hidden(prompt: ProximityPrompt)
	local adornee = prompt.Parent
	local b = adornee and boards[adornee]
	if not b or not adornee then
		return
	end
	local row = b.rows[prompt]
	if row then
		row:Destroy()
		b.rows[prompt] = nil
	end
	if next(b.rows) == nil then
		b.gui:Destroy()
		boards[adornee] = nil
	end
end

function CompactPrompts.Init(screen: ScreenGui)
	screenRef = screen
	ProximityPromptService.PromptShown:Connect(shown)
	ProximityPromptService.PromptHidden:Connect(hidden)
end

return CompactPrompts
