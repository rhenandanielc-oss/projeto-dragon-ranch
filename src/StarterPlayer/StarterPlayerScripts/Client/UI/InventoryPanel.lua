--!strict
-- Fase 4: mochila (30→60), armazém da fazenda (100) e barra de 8 itens.
-- O cliente só mostra e PEDE; o servidor confere distância do baú, quantidades e espaço.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local ItemTile = require(script.Parent.ItemTile)
local State = require(script.Parent.Parent.State)
local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)
local Items = require(ReplicatedStorage.Shared.Config.Items)
local Inventory = require(ReplicatedStorage.Shared.Config.Inventory)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local InventoryPanel = {}

local panel: Frame
local storagePanel: Frame
local grid: ScrollingFrame
local storageGrid: ScrollingFrame
local title: TextLabel
local actions: Frame
local storageActions: Frame
local expandButton: TextButton
local hotbar: Frame
local selected: number? = nil -- espaço selecionado na mochila
local selectedStorage: number? = nil
local storageOpen = false
local hotIndex = 1

local TILE = 62

local function clear(frame: Instance)
	for _, c in ipairs(frame:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function hotbarCount(itemId: string): number
	local data = State.Data
	if not data then
		return 0
	end
	local n = 0
	for _, s in ipairs(data.Backpack.Slots) do
		if s.Item == itemId then
			n += s.Count
		end
	end
	return n
end

function InventoryPanel.RenderHotbar()
	local data = State.Data
	clear(hotbar)
	for i = 1, Inventory.HotbarSize do
		local itemId = data and data.Hotbar and data.Hotbar[tostring(i)] or nil
		local n = itemId and hotbarCount(itemId) or 0
		local tile = ItemTile.new(itemId, n, 56, hotbar)
		tile.LayoutOrder = i
		if itemId and n == 0 then
			tile.BackgroundTransparency = 0.6
		end
		Theme.stroke(i == hotIndex and Theme.Colors.Accent or Color3.fromRGB(70, 60, 80), i == hotIndex and 3 or 1).Parent = tile
		Theme.label(tostring(i), 12, { Font = Theme.BoldFont, TextColor3 = Theme.Colors.TextDim, Position = UDim2.fromOffset(4, 0), Size = UDim2.fromOffset(14, 14), Parent = tile })
		tile.Activated:Connect(function()
			-- tocar de novo no espaço já escolhido usa o item
			if hotIndex == i and itemId and n > 0 then
				NetClient.Fire("UseItem", itemId)
			end
			hotIndex = i
			InventoryPanel.RenderHotbar()
		end)
	end
end

local function actionButton(text: string, parent: Instance, onClick: () -> (), alt: boolean?)
	local b = Theme.button(text, { Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, TextSize = 15, BackgroundColor3 = alt and Theme.Colors.ButtonAlt or Theme.Colors.Button, Parent = parent })
	Theme.padding(8).Parent = b
	b.Activated:Connect(onClick)
	return b
end

function InventoryPanel.Render()
	local data = State.Data
	if not data or not panel then
		return
	end
	local bp = data.Backpack
	title.Text = string.format("Mochila  %d / %d", #bp.Slots, bp.Capacity)
	if selected and not bp.Slots[selected] then
		selected = nil
	end
	clear(grid)
	for i = 1, bp.Capacity do
		local slot = bp.Slots[i]
		local tile = ItemTile.new(slot and slot.Item, slot and slot.Count, TILE, grid)
		tile.LayoutOrder = i
		if selected == i then
			Theme.stroke(Theme.Colors.Accent, 3).Parent = tile
		end
		if slot then
			tile.Activated:Connect(function()
				selected = if selected == i then nil else i
				InventoryPanel.Render()
			end)
		end
	end

	-- ações do item selecionado
	clear(actions)
	local slot = selected and bp.Slots[selected]
	if slot then
		local def = Items[slot.Item]
		Theme.label(string.format("%s ×%d", def.DisplayName, slot.Count), 15, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 40), TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = false, Parent = actions })
		if slot.Item == "ReturnStone" or slot.Item == "HealthPotion" then
			actionButton("Usar", actions, function()
				NetClient.Fire("UseItem", slot.Item)
			end)
		end
		actionButton("Pôr na barra (" .. hotIndex .. ")", actions, function()
			NetClient.Fire("SetHotbar", hotIndex, slot.Item)
		end)
		if storageOpen then
			actionButton("Guardar 1", actions, function()
				NetClient.Fire("StorageDeposit", selected, 1)
			end)
			actionButton("Guardar tudo", actions, function()
				NetClient.Fire("StorageDeposit", selected, math.min(slot.Count, 50))
			end)
		end
		actionButton("Jogar fora", actions, function()
			NetClient.Fire("DiscardItem", selected, 1)
		end, true)
	else
		Theme.label("Toque num item para ver as ações.", 14, { TextColor3 = Theme.Colors.TextDim, Size = UDim2.fromOffset(260, 40), TextYAlignment = Enum.TextYAlignment.Center, Parent = actions })
	end

	local cfg = Inventory.Backpack
	local step = math.floor((bp.Capacity - cfg.StartCapacity) / cfg.ExpansionStep) + 1
	local cost = bp.Capacity < cfg.MaxCapacity and Rules.Economy.BackpackExpansionCost[step] or nil
	expandButton.Visible = cost ~= nil
	if cost then
		expandButton.Text = string.format("+%d espaços (%d)", cfg.ExpansionStep, cost)
	end

	-- armazém (com ele aberto, a mochila vai para a esquerda)
	panel.Position = if storageOpen then UDim2.fromScale(0.27, 0.46) else UDim2.fromScale(0.5, 0.46)
	storagePanel.Visible = storageOpen and panel.Visible
	if storageOpen then
		local st = data.Storage
		if selectedStorage and not st.Slots[selectedStorage] then
			selectedStorage = nil
		end
		clear(storageGrid)
		for i = 1, math.max(#st.Slots + 5, 20) do
			if i > st.Capacity then
				break
			end
			local s = st.Slots[i]
			local tile = ItemTile.new(s and s.Item, s and s.Count, TILE, storageGrid)
			tile.LayoutOrder = i
			if selectedStorage == i then
				Theme.stroke(Theme.Colors.Accent, 3).Parent = tile
			end
			if s then
				tile.Activated:Connect(function()
					selectedStorage = if selectedStorage == i then nil else i
					InventoryPanel.Render()
				end)
			end
		end
		clear(storageActions)
		local s = selectedStorage and st.Slots[selectedStorage]
		Theme.label(string.format("Armazém  %d / %d", #st.Slots, st.Capacity), 15, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 40), TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = false, Parent = storageActions })
		if s then
			actionButton("Retirar 1", storageActions, function()
				NetClient.Fire("StorageWithdraw", selectedStorage, 1)
			end)
			actionButton("Retirar tudo", storageActions, function()
				NetClient.Fire("StorageWithdraw", selectedStorage, math.min(s.Count, 50))
			end)
		end
	end
	InventoryPanel.RenderHotbar()
end

function InventoryPanel.SetOpen(open: boolean)
	panel.Visible = open
	if not open then
		storageOpen = false
		storagePanel.Visible = false
		selected = nil
	end
	InventoryPanel.Render()
end

function InventoryPanel.OpenStorage()
	storageOpen = true
	panel.Visible = true
	InventoryPanel.Render()
end

function InventoryPanel.Init(screen: ScreenGui)
	-- barra de 8 itens (embaixo, no centro)
	hotbar = Theme.new("Frame", {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(0, 56),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = screen,
	}, { Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local toggle = Theme.button("Mochila", {
		Name = "BackpackButton",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -70),
		Size = UDim2.fromOffset(120, 50),
		TextSize = 20,
		Parent = screen,
	})
	Theme.stroke().Parent = toggle

	panel = Theme.new("Frame", {
		Name = "InventoryPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.new(0.5, 0, 0.62, 0),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = screen,
	}, { Theme.corner(14), Theme.stroke(), Theme.padding(10), Theme.new("UISizeConstraint", { MinSize = Vector2.new(320, 300), MaxSize = Vector2.new(560, 640) }) })
	title = Theme.label("Mochila", 22, { Font = Theme.TitleFont, Size = UDim2.new(1, -200, 0, 30), Parent = panel })
	expandButton = Theme.button("Ampliar", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -46, 0, 0), Size = UDim2.fromOffset(150, 34), TextSize = 14, Parent = panel })
	expandButton.Activated:Connect(function()
		NetClient.Fire("ExpandBackpack")
	end)
	local close = Theme.button("X", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(40, 34), BackgroundColor3 = Theme.Colors.ButtonAlt, Parent = panel })
	close.Activated:Connect(function()
		InventoryPanel.SetOpen(false)
	end)
	grid = Theme.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -96),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = panel,
	}, { Theme.new("UIGridLayout", { CellSize = UDim2.fromOffset(TILE, TILE), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	actions = Theme.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 48),
		Parent = panel,
	}, { Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })

	storagePanel = Theme.new("Frame", {
		Name = "StoragePanel",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 10, 0.5, 0),
		Size = UDim2.new(0.9, 0, 1, 0),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = panel,
	}, { Theme.corner(14), Theme.stroke(), Theme.padding(10) })
	storageGrid = Theme.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -56),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = storagePanel,
	}, { Theme.new("UIGridLayout", { CellSize = UDim2.fromOffset(TILE, TILE), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	storageActions = Theme.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 48),
		Parent = storagePanel,
	}, { Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })

	toggle.Activated:Connect(function()
		InventoryPanel.SetOpen(not panel.Visible)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			InventoryPanel.SetOpen(not panel.Visible)
			return
		end
		local n = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
		if n >= 1 and n <= Inventory.HotbarSize then
			local data = State.Data
			local itemId = data and data.Hotbar and data.Hotbar[tostring(n)]
			if hotIndex == n and itemId then
				NetClient.Fire("UseItem", itemId)
			end
			hotIndex = n
			InventoryPanel.RenderHotbar()
		end
	end)

	State.Changed:Connect(function(key: string)
		if key == "*" or key == "Backpack" or key == "Storage" or key == "Hotbar" then
			InventoryPanel.Render()
		end
	end)
end

function InventoryPanel.SelectedHotbarItem(): string?
	local data = State.Data
	return data and data.Hotbar and data.Hotbar[tostring(hotIndex)] or nil
end

return InventoryPanel
