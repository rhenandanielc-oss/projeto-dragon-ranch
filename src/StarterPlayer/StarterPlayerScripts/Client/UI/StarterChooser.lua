--!strict
-- Tela de escolha do primeiro ovo (aparece só enquanto o jogador ainda não escolheu).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)
local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)
local Species = require(ReplicatedStorage.Shared.Config.Species)
local Elements = require(ReplicatedStorage.Shared.Config.Elements)

local StarterChooser = {}

local ORDER = { "WesternDragon", "Wyvern", "Amphiptere", "Wyrm", "AsianDragon" }

local root: Frame
local selected: string? = nil
local cards: { [string]: TextButton } = {}
local confirm: TextButton
local sent = false

local function refreshSelection()
	for id, card in pairs(cards) do
		local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
		stroke.Thickness = id == selected and 4 or 2
		stroke.Color = id == selected and Theme.Colors.Accent or Theme.Colors.Stroke
		card.BackgroundColor3 = id == selected and Theme.Colors.PanelLight or Theme.Colors.Panel
	end
	confirm.Active = selected ~= nil and not sent
	confirm.AutoButtonColor = confirm.Active
	confirm.BackgroundColor3 = confirm.Active and Theme.Colors.Button or Theme.Colors.ButtonAlt
	confirm.Text = selected and ("Chocar ovo de " .. Species[selected].DisplayName) or "Escolha uma espécie"
end

local function makeCard(id: string, order: number): TextButton
	local def = Species[id]
	local card = Theme.new("TextButton", {
		Name = id,
		LayoutOrder = order,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Colors.Panel,
		Size = UDim2.fromOffset(190, 250),
	}, {
		Theme.corner(12),
		Theme.stroke(),
		Theme.padding(10),
		Theme.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Theme.label(def.DisplayName, 22, { Font = Theme.TitleFont, LayoutOrder = 1, Parent = card, TextXAlignment = Enum.TextXAlignment.Center })

	local chips = Theme.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 2, Parent = card }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
	for _, elementId in ipairs(def.Elements) do
		local e = Elements[elementId]
		Theme.new("TextLabel", {
			BackgroundColor3 = e.Color,
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = "  " .. e.DisplayName .. "  ",
			Font = Theme.BoldFont,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(25, 20, 30),
			Parent = chips,
		}, { Theme.corner(12) })
	end

	local traits = {}
	table.insert(traits, def.CanFly and (def.FlightStyle == "Undulate" and "Voa sem asas, ondulando" or "Voa com asas") or "Não voa · entra na terra")
	table.insert(traits, def.Legs == 0 and "Sem patas" or (tostring(def.Legs) .. " patas"))
	Theme.label(table.concat(traits, " · "), 14, { TextColor3 = Theme.Colors.Accent, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 36), Parent = card, TextXAlignment = Enum.TextXAlignment.Center })
	Theme.label(def.RoleText, 15, { TextColor3 = Theme.Colors.TextDim, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 110), TextYAlignment = Enum.TextYAlignment.Top, Parent = card })

	card.Activated:Connect(function()
		if sent then
			return
		end
		selected = id
		refreshSelection()
	end)
	return card
end

function StarterChooser.Init(screen: ScreenGui)
	root = Theme.new("Frame", {
		Name = "StarterChooser",
		BackgroundColor3 = Color3.fromRGB(10, 8, 14),
		BackgroundTransparency = 0.25,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 10,
		Parent = screen,
	})
	local column = Theme.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.96, 0, 0.92, 0),
		Parent = root,
	}, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Theme.label("Escolha seu primeiro dragão", 34, { Font = Theme.TitleFont, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = column })
	Theme.label("Seu ovo vai para o ninho da sua fazenda. Cuide dele e ele vai crescer com você.", 17, { TextColor3 = Theme.Colors.TextDim, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = column })

	-- Rolagem horizontal: em telas pequenas os cartões continuam acessíveis.
	local scroller = Theme.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 266),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 6,
		LayoutOrder = 3,
		Parent = column,
	}, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		Theme.padding(6),
	})
	for i, id in ipairs(ORDER) do
		cards[id] = makeCard(id, i)
		cards[id].Parent = scroller
	end

	confirm = Theme.button("Escolha uma espécie", { Size = UDim2.fromOffset(320, 54), TextSize = 20, LayoutOrder = 4, Parent = column })
	confirm.Activated:Connect(function()
		if not selected or sent then
			return
		end
		sent = true
		confirm.Text = "Enviando..."
		NetClient.Fire("ChooseStarter", selected)
		task.delay(5, function()
			-- se o servidor não confirmou, permite tentar de novo
			if root.Visible then
				sent = false
				refreshSelection()
			end
		end)
	end)
	refreshSelection()

	State.Changed:Connect(function(key: string)
		if key == "*" or key == "StarterChosen" then
			local data = State.Data
			root.Visible = data ~= nil and data.StarterChosen == false
		end
	end)
end

return StarterChooser
