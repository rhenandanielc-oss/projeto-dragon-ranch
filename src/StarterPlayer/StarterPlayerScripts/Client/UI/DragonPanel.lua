--!strict
-- Painel "Meus dragões": estágio, progresso de crescimento, fome/sede, dragão ativo e nome.
-- Também mostra moedas e um resumo dos itens até a mochila completa chegar (Fase 4).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)
local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)
local Species = require(ReplicatedStorage.Shared.Config.Species)
local Growth = require(ReplicatedStorage.Shared.Config.Growth)
local Rarity = require(ReplicatedStorage.Shared.Config.Rarity)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)
local Items = require(ReplicatedStorage.Shared.Config.Items)

local DragonPanel = {}

local panel: Frame
local list: ScrollingFrame
local footer: TextLabel
local expandButton: TextButton
local coinsLabel: TextLabel
local itemsLabel: TextLabel
local renaming: string? = nil

local function nextStage(stage: string): string?
	local i = Growth.StageIndex(stage)
	return Growth.Stages[i + 1]
end

local function dragonCard(dragon: { [string]: any }, isActive: boolean, order: number): Frame
	local def = Species[dragon.Species]
	local rarity = Rarity.Defs[dragon.Rarity] or Rarity.Defs.Common
	local card = Theme.new("Frame", {
		Name = dragon.Id,
		LayoutOrder = order,
		BackgroundColor3 = isActive and Theme.Colors.PanelLight or Theme.Colors.Panel,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		Theme.corner(10),
		Theme.stroke(isActive and Theme.Colors.Accent or Color3.fromRGB(90, 80, 100), isActive and 3 or 1),
		Theme.padding(10),
		Theme.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local title = (dragon.CustomName ~= nil and dragon.CustomName ~= "") and dragon.CustomName or def.DisplayName
	Theme.label(title .. (isActive and "  ★ Ativo" or ""), 20, { Font = Theme.TitleFont, LayoutOrder = 1, Parent = card })
	Theme.label(string.format("%s · %s · %s", def.DisplayName, Growth.StageNames[dragon.Stage], rarity.DisplayName), 14, { TextColor3 = rarity.Color, LayoutOrder = 2, Parent = card })

	-- Progresso de crescimento (o jogo sempre explica o que falta)
	local nxt = nextStage(dragon.Stage)
	local bar, setBar = Theme.bar(Theme.Colors.Growth, 20)
	bar.LayoutOrder = 3
	bar.Parent = card
	if nxt then
		local from = Growth.Thresholds[dragon.Stage]
		local to = Growth.Thresholds[nxt]
		local frac = (dragon.GrowthPoints - from) / (to - from)
		local missing = math.max(0, math.ceil(to - dragon.GrowthPoints))
		setBar(frac, string.format("Faltam %d pontos para %s", missing, Growth.StageNames[nxt]))
	else
		setBar(1, "Estágio máximo")
	end

	if dragon.Stage == "Egg" then
		Theme.label("Chocando no ninho. O ovo ganha pontos enquanto você está no jogo.", 14, { TextColor3 = Theme.Colors.TextDim, LayoutOrder = 4, Parent = card })
	else
		local hBar, setH = Theme.bar(Theme.Colors.Hunger, 16)
		hBar.LayoutOrder = 4
		hBar.Parent = card
		setH(dragon.Hunger / Growth.Needs.Max, string.format("Fome %d%%", math.floor(dragon.Hunger)))
		local tBar, setT = Theme.bar(Theme.Colors.Thirst, 16)
		tBar.LayoutOrder = 5
		tBar.Parent = card
		setT(dragon.Thirst / Growth.Needs.Max, string.format("Sede %d%%", math.floor(dragon.Thirst)))
		if dragon.Hunger < Growth.Needs.HungryThreshold or dragon.Thirst < Growth.Needs.HungryThreshold then
			Theme.label("Com fome ou sede: ganha só metade dos pontos.", 14, { TextColor3 = Theme.Colors.Warn, LayoutOrder = 6, Parent = card })
		end
		-- montaria em terra a partir de Jovem
		local land = Rules.Mount.LandSpeedByStage[dragon.Stage]
		if land then
			local speed = math.floor(land * (dragon.Species == "Wyrm" and Rules.Mount.WyrmLandMultiplier or 1))
			Theme.label(string.format("Montaria em terra: velocidade %d (V perto dele para montar)", speed), 14, { TextColor3 = Theme.Colors.TextDim, LayoutOrder = 6, Parent = card })
		elseif isActive then
			Theme.label("Ele te acompanha pelo mundo. Pode ser montado a partir de Jovem.", 14, { TextColor3 = Theme.Colors.TextDim, LayoutOrder = 6, Parent = card })
		end
	end

	local row = Theme.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 7, Parent = card }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
	})
	if not isActive then
		local b = Theme.button("Tornar ativo", { Size = UDim2.fromOffset(130, 44), TextSize = 16, Parent = row })
		b.Activated:Connect(function()
			NetClient.Fire("SetActiveDragon", dragon.Id)
		end)
	end
	if not isActive and dragon.Stage ~= "Egg" then
		local roaming = dragon.Roaming == true
		local b = Theme.button(roaming and "Recolher" or "Soltar", { Size = UDim2.fromOffset(100, 44), TextSize = 16, BackgroundColor3 = roaming and Theme.Colors.ButtonAlt or Theme.Colors.Button, Parent = row })
		b.Activated:Connect(function()
			NetClient.Fire("SetRoaming", dragon.Id, not roaming)
		end)
	end
	if isActive and dragon.Stage ~= "Egg" then
		local out = Players.LocalPlayer:GetAttribute("CompanionOut") == true
		local b = Theme.button(out and "Guardar" or "Chamar", { Size = UDim2.fromOffset(110, 44), TextSize = 16, Parent = row })
		b.Activated:Connect(function()
			NetClient.Fire("ToggleCompanion")
		end)
	end
	local renameButton = Theme.button("Renomear", { Size = UDim2.fromOffset(110, 44), TextSize = 16, BackgroundColor3 = Theme.Colors.ButtonAlt, Parent = row })
	renameButton.Activated:Connect(function()
		renaming = renaming == dragon.Id and nil or dragon.Id
		DragonPanel.Render()
	end)

	if renaming == dragon.Id then
		local editRow = Theme.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 8, Parent = card }, {
			Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
		})
		local box = Theme.new("TextBox", {
			Size = UDim2.new(1, -96, 1, 0),
			BackgroundColor3 = Color3.fromRGB(20, 16, 24),
			TextColor3 = Theme.Colors.Text,
			PlaceholderText = "Novo nome (até 20 letras)",
			PlaceholderColor3 = Theme.Colors.TextDim,
			Text = dragon.CustomName or "",
			Font = Theme.BodyFont,
			TextSize = 16,
			ClearTextOnFocus = false,
			Parent = editRow,
		}, { Theme.corner(8), Theme.padding(6) })
		local ok = Theme.button("OK", { Size = UDim2.fromOffset(88, 44), Parent = editRow })
		ok.Activated:Connect(function()
			local text = box.Text
			if #text > 0 then
				NetClient.Fire("RenameDragon", dragon.Id, string.sub(text, 1, 60))
			end
			renaming = nil
			DragonPanel.Render()
		end)
	end
	return card
end

function DragonPanel.Render()
	local data = State.Data
	if not data then
		return
	end
	coinsLabel.Text = string.format("%d %s", data.Coins, Rules.Economy.CurrencyName)
	local counts: { [string]: number } = {}
	for _, slot in ipairs(data.Backpack.Slots) do
		counts[slot.Item] = (counts[slot.Item] or 0) + slot.Count
	end
	local parts = {}
	for itemId, n in pairs(counts) do
		local def = Items[itemId]
		table.insert(parts, string.format("%s ×%d", def and def.DisplayName or itemId, n))
	end
	table.sort(parts)
	itemsLabel.Text = #parts > 0 and table.concat(parts, "   ") or "Mochila vazia"

	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local ids = {}
	for id in pairs(data.Dragons) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return (data.Dragons[a].CreatedAt or 0) < (data.Dragons[b].CreatedAt or 0)
	end)
	for i, id in ipairs(ids) do
		dragonCard(data.Dragons[id], data.ActiveDragonId == id, i).Parent = list
	end
	footer.Text = string.format("Espaços na fazenda: %d / %d", #ids, data.DragonSlots)
	local cost = Rules.Farm.SlotExpansionCost[data.DragonSlots - Rules.Farm.StartDragonSlots + 1]
	expandButton.Visible = cost ~= nil
	if cost then
		expandButton.Text = string.format("Ampliar (%d)", cost)
	end
end

function DragonPanel.Init(screen: ScreenGui)
	-- Barra superior: moedas e itens
	local top = Theme.new("Frame", {
		Name = "TopBar",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.1,
		Parent = screen,
	}, { Theme.corner(10), Theme.stroke(), Theme.padding(8), Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), VerticalAlignment = Enum.VerticalAlignment.Center }) })
	coinsLabel = Theme.label("", 18, { Font = Theme.BoldFont, TextColor3 = Theme.Colors.Accent, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), TextWrapped = false, Parent = top })
	itemsLabel = Theme.label("", 14, { TextColor3 = Theme.Colors.TextDim, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), TextWrapped = false, Parent = top })

	-- Botão que abre o painel (canto inferior esquerdo, confortável para toque)
	local toggle = Theme.button("Dragões", {
		Name = "DragonsButton",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(120, 50),
		TextSize = 20,
		Parent = screen,
	})
	Theme.stroke().Parent = toggle

	panel = Theme.new("Frame", {
		Name = "DragonPanel",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 140, 1, -12),
		Size = UDim2.new(0.42, 0, 0.72, 0),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = screen,
	}, {
		Theme.corner(14),
		Theme.stroke(),
		Theme.padding(10),
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(300, 260), MaxSize = Vector2.new(460, 760) }),
	})
	Theme.label("Meus dragões", 24, { Font = Theme.TitleFont, Position = UDim2.fromOffset(0, 0), Parent = panel })
	list = Theme.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -92),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = panel,
	}, { Theme.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	footer = Theme.label("", 15, { Position = UDim2.new(0, 0, 1, -44), Size = UDim2.new(1, -150, 0, 44), TextColor3 = Theme.Colors.TextDim, Parent = panel })
	expandButton = Theme.button("Ampliar", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(140, 44), TextSize = 16, Parent = panel })
	expandButton.Activated:Connect(function()
		NetClient.Fire("ExpandDragonSlots")
	end)

	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			DragonPanel.Render()
		end
	end)

	Players.LocalPlayer:GetAttributeChangedSignal("CompanionOut"):Connect(function()
		if panel.Visible and renaming == nil then
			DragonPanel.Render()
		end
	end)

	State.Changed:Connect(function(key: string)
		if key == "*" or key == "Dragons" or key == "ActiveDragonId" or key == "Coins" or key == "DragonSlots" or key == "Backpack" then
			-- não redesenha enquanto o jogador digita um nome
			if renaming == nil or key ~= "Dragons" then
				DragonPanel.Render()
			end
		end
	end)
end

return DragonPanel
