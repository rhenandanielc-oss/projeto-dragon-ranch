--!strict
-- Fase 4: loja do Tobias. Comprar (comida, água, poções, flechas, ovo) e vender materiais.
-- Preços mostrados vêm da mesma configuração que o servidor usa; quem cobra é o servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)
local ItemTile = require(script.Parent.ItemTile)
local State = require(script.Parent.Parent.State)
local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)
local Items = require(ReplicatedStorage.Shared.Config.Items)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local ShopPanel = {}

local panel: Frame
local buyList: ScrollingFrame
local sellList: ScrollingFrame
local coinsLabel: TextLabel

local function row(parent: Instance, itemId: string?, titleText: string, subText: string, order: number): Frame
	local f = Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.PanelLight,
		Size = UDim2.new(1, -8, 0, 64),
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.corner(10), Theme.padding(6) })
	ItemTile.new(itemId, nil, 52, f).Active = false
	Theme.label(titleText, 16, { Font = Theme.BoldFont, Position = UDim2.fromOffset(60, 2), Size = UDim2.new(1, -200, 0, 22), TextWrapped = false, Parent = f })
	Theme.label(subText, 13, { TextColor3 = Theme.Colors.TextDim, Position = UDim2.fromOffset(60, 26), Size = UDim2.new(1, -200, 0, 22), Parent = f })
	local buttons = Theme.new("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(136, 44),
		Parent = f,
	}, { Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
	return buttons
end

local function smallButton(text: string, parent: Instance, onClick: () -> (), enabled: boolean)
	local b = Theme.button(text, { Size = UDim2.fromOffset(64, 44), TextSize = 14, Parent = parent })
	if not enabled then
		b.BackgroundColor3 = Theme.Colors.ButtonAlt
		b.AutoButtonColor = false
		b.TextTransparency = 0.4
	else
		b.Activated:Connect(onClick)
	end
end

function ShopPanel.Render()
	local data = State.Data
	if not data or not panel or not panel.Visible then
		return
	end
	coinsLabel.Text = string.format("%d %s", data.Coins, Rules.Economy.CurrencyName)
	for _, list in ipairs({ buyList, sellList }) do
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
	end

	for i, itemId in ipairs(Shop.Buy) do
		local def = Items[itemId]
		local price = def.BuyPrice or 0
		local b = row(buyList, itemId, def.DisplayName, string.format("%d cada", price), i)
		smallButton("×1", b, function()
			NetClient.Fire("ShopBuy", itemId, 1)
		end, data.Coins >= price)
		smallButton("×10", b, function()
			NetClient.Fire("ShopBuy", itemId, 10)
		end, data.Coins >= price * 10)
	end
	if Shop.EggEnabled then
		local price = Rules.Economy.MerchantEggPrice
		local b = row(buyList, nil, "Ovo de dragão", string.format("%d · espécie surpresa, Comum ou Incomum", price), 100)
		local n = 0
		for _ in pairs(data.Dragons) do
			n += 1
		end
		local ok = data.Coins >= price and n < data.DragonSlots
		local btn = Theme.button("Comprar", { Size = UDim2.fromOffset(132, 44), TextSize = 15, Parent = b })
		if ok then
			btn.Activated:Connect(function()
				NetClient.Fire("ShopBuyEgg")
			end)
		else
			btn.BackgroundColor3 = Theme.Colors.ButtonAlt
			btn.AutoButtonColor = false
			btn.Text = n >= data.DragonSlots and "Fazenda cheia" or "Faltam moedas"
		end
	end

	-- vender: o que houver na mochila com preço de venda
	local totals: { [string]: number } = {}
	for _, s in ipairs(data.Backpack.Slots) do
		totals[s.Item] = (totals[s.Item] or 0) + s.Count
	end
	local ids = {}
	for id in pairs(totals) do
		local def = Items[id]
		if def and def.SellPrice and def.Category ~= "Quest" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	for i, id in ipairs(ids) do
		local def = Items[id]
		local n = totals[id]
		local b = row(sellList, id, string.format("%s ×%d", def.DisplayName, n), string.format("%d cada · tudo: %d", def.SellPrice :: number, (def.SellPrice :: number) * n), i)
		smallButton("1", b, function()
			NetClient.Fire("ShopSell", id, 1)
		end, true)
		smallButton("Tudo", b, function()
			NetClient.Fire("ShopSell", id, n)
		end, true)
	end
	if #ids == 0 then
		Theme.label("Nada para vender. Colete madeira, pedra, ervas, penas e cristais pelo mundo.", 14, { TextColor3 = Theme.Colors.TextDim, Size = UDim2.new(1, -8, 0, 40), Parent = sellList })
	end
end

function ShopPanel.Open()
	panel.Visible = true
	ShopPanel.Render()
end

function ShopPanel.Init(screen: ScreenGui)
	panel = Theme.new("Frame", {
		Name = "ShopPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.new(0.7, 0, 0.7, 0),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.04,
		Visible = false,
		Parent = screen,
	}, { Theme.corner(14), Theme.stroke(), Theme.padding(12), Theme.new("UISizeConstraint", { MinSize = Vector2.new(340, 300), MaxSize = Vector2.new(860, 620) }) })
	Theme.label("Tobias, o Mercador", 24, { Font = Theme.TitleFont, Size = UDim2.new(1, -240, 0, 32), Parent = panel })
	coinsLabel = Theme.label("", 18, { Font = Theme.BoldFont, TextColor3 = Theme.Colors.Accent, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -52, 0, 4), Size = UDim2.fromOffset(180, 26), TextXAlignment = Enum.TextXAlignment.Right, Parent = panel })
	local close = Theme.button("X", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(44, 36), BackgroundColor3 = Theme.Colors.ButtonAlt, Parent = panel })
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	local function column(x: number, text: string): ScrollingFrame
		Theme.label(text, 18, { Font = Theme.BoldFont, Position = UDim2.new(x, 0, 0, 40), Size = UDim2.new(0.5, -6, 0, 24), Parent = panel })
		return Theme.new("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(x, x > 0 and 6 or 0, 0, 70),
			Size = UDim2.new(0.5, -6, 1, -70),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6,
			Parent = panel,
		}, { Theme.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	end
	buyList = column(0, "Comprar")
	sellList = column(0.5, "Vender")

	State.Changed:Connect(function(key: string)
		if key == "*" or key == "Coins" or key == "Backpack" or key == "Dragons" or key == "DragonSlots" then
			ShopPanel.Render()
		end
	end)
	-- fecha sozinha se o jogador se afastar do mercador
	task.spawn(function()
		while true do
			task.wait(1)
			if panel.Visible then
				local char = Players.LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local hub = workspace:FindFirstChild("Hub")
				local npcs = hub and hub:FindFirstChild("NPCs")
				local npc = npcs and npcs:FindFirstChild("NPC_Merchant")
				local root = npc and npc:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp and root and (hrp.Position - root.Position).Magnitude > Shop.InteractDistance + 6 then
					panel.Visible = false
				end
			end
		end
	end)
end

return ShopPanel
