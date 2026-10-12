--!strict
-- Mesa do cartógrafo (Hub): mostra os biomas de fazenda livres neste servidor e,
-- para quem já tem dragão Jovem, permite escolher o bioma (o servidor valida tudo).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)
local Biomes = require(ReplicatedStorage.Shared.Config.Biomes)

local FarmChooser = {}

local root: Frame
local list: ScrollingFrame
local note: TextLabel

function FarmChooser.Init(screen: ScreenGui)
	root = Theme.new("Frame", {
		Name = "FarmChooser",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 460, 0.8, 0),
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		ZIndex = 8,
		Parent = screen,
	}, {
		Theme.corner(14),
		Theme.stroke(),
		Theme.padding(14),
		Theme.new("UISizeConstraint", { MaxSize = Vector2.new(460, 640) }),
		Theme.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Theme.label("Mesa do cartógrafo", 26, { Font = Theme.TitleFont, LayoutOrder = 1, Parent = root })
	note = Theme.label("", 15, { TextColor3 = Theme.Colors.TextDim, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 40), Parent = root })
	list = Theme.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -130),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		LayoutOrder = 3,
		Parent = root,
	}, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local close = Theme.button("Fechar", { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Colors.ButtonAlt, Parent = root })
	close.Activated:Connect(function()
		root.Visible = false
	end)
end

function FarmChooser.Open(free: { string }, current: string, canChoose: boolean)
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if canChoose then
		note.Text = "Escolha um bioma livre para a sua fazenda. Seus dragões vão junto."
	else
		note.Text = "Você poderá escolher o bioma da fazenda quando um dragão seu ficar Jovem. Fazendas livres agora:"
	end
	for i, id in ipairs(free) do
		local def = Biomes.List[id]
		if def then
			local row = Theme.new("Frame", { BackgroundColor3 = Theme.Colors.PanelLight, Size = UDim2.new(1, -8, 0, 64), LayoutOrder = i, Parent = list }, {
				Theme.corner(10),
				Theme.padding(8),
			})
			Theme.label(def.DisplayName, 18, { Font = Theme.BoldFont, Size = UDim2.new(1, -120, 0, 22), Parent = row })
			Theme.label(def.Text, 13, { TextColor3 = Theme.Colors.TextDim, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, -120, 0, 30), Parent = row })
			if canChoose then
				local b = Theme.button(if id == current then "Atual" else "Mudar", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(100, 38),
					Parent = row,
				})
				b.Activated:Connect(function()
					if id ~= current then
						NetClient.Fire("ChooseFarmBiome", id)
						root.Visible = false
					end
				end)
			end
		end
	end
	root.Visible = true
end

return FarmChooser
