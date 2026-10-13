--!strict
-- Fase 4: loja do mercador (Tobias, no Hub). Compra, venda a preço fixo e ovo do mercador.
-- Anti-exploit: só perto do NPC; preços sempre do servidor; quantidade inteira e limitada;
-- a moeda só é cobrada depois de confirmar que o item cabe na mochila.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Items = require(ReplicatedStorage.Shared.Config.Items)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)
local Rarity = require(ReplicatedStorage.Shared.Config.Rarity)
local Species = require(ReplicatedStorage.Shared.Config.Species)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)

local Server = ServerScriptService.Server
local DataService = require(Server.Data.DataService)
local NetService = require(Server.Services.NetService)
local InventoryService = require(Server.Services.InventoryService)
local DragonService = require(Server.Dragons.DragonService)

local ShopService = {}

local rng = Random.new()

local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

local function merchantRoot(): BasePart?
	local hub = workspace:FindFirstChild("Hub")
	local npcs = hub and hub:FindFirstChild("NPCs")
	local npc = npcs and npcs:FindFirstChild("NPC_Merchant")
	return npc and npc:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nearMerchant(player: Player): boolean
	local root = merchantRoot()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not hrp then
		return false
	end
	return (hrp.Position - root.Position).Magnitude <= Shop.InteractDistance
end

local function isSellable(itemId: string): boolean
	local def = Items[itemId]
	return def ~= nil and def.SellPrice ~= nil and def.Category ~= "Quest"
end

local function isBuyable(itemId: string): boolean
	if not table.find(Shop.Buy, itemId) then
		return false
	end
	local def = Items[itemId]
	return def ~= nil and def.BuyPrice ~= nil
end

local function onBuy(player: Player, itemId: string, count: number)
	local data = DataService.Get(player)
	if not data or not nearMerchant(player) or not isBuyable(itemId) then
		return
	end
	count = math.clamp(math.floor(count), 1, Shop.MaxPerPurchase)
	local def = Items[itemId]
	local price = (def.BuyPrice :: number) * count
	if data.Coins < price then
		notify(player, string.format("Você precisa de %d %s.", price, Rules.Economy.CurrencyName), "warning")
		return
	end
	if InventoryService.Room(player, itemId) < count then
		notify(player, "Não cabe tudo na mochila.", "warning")
		return
	end
	data.Coins -= price
	InventoryService.Add(player, itemId, count)
	DataService.MarkChanged(player, "Coins")
	notify(player, string.format("Comprou %d× %s por %d.", count, def.DisplayName, price), "success")
end

local function onSell(player: Player, itemId: string, count: number)
	local data = DataService.Get(player)
	if not data or not nearMerchant(player) or not isSellable(itemId) then
		return
	end
	count = math.clamp(math.floor(count), 1, 10000)
	count = math.min(count, InventoryService.Count(player, itemId))
	if count <= 0 then
		return
	end
	local def = Items[itemId]
	if not InventoryService.Remove(player, itemId, count) then
		return
	end
	local gain = (def.SellPrice :: number) * count
	data.Coins += gain
	DataService.MarkChanged(player, "Coins")
	notify(player, string.format("Vendeu %d× %s por %d.", count, def.DisplayName, gain), "success")
end

local function weighted(list: { { Id: string, Weight: number } }): string
	local total = 0
	for _, e in ipairs(list) do
		total += e.Weight
	end
	local r = rng:NextNumber() * total
	for _, e in ipairs(list) do
		r -= e.Weight
		if r <= 0 then
			return e.Id
		end
	end
	return list[#list].Id
end

local function onBuyEgg(player: Player)
	local data = DataService.Get(player)
	if not data or not Shop.EggEnabled or not nearMerchant(player) then
		return
	end
	local price = Rules.Economy.MerchantEggPrice
	if data.Coins < price then
		notify(player, string.format("O ovo custa %d %s.", price, Rules.Economy.CurrencyName), "warning")
		return
	end
	local n = 0
	for _ in pairs(data.Dragons) do
		n += 1
	end
	if n >= data.DragonSlots then
		notify(player, "Sua fazenda não tem espaço para mais um dragão.", "warning")
		return
	end
	local speciesList = {}
	for id in pairs(Species) do
		table.insert(speciesList, id)
	end
	table.sort(speciesList)
	local speciesId = speciesList[rng:NextInteger(1, #speciesList)]
	local rarityId = weighted(Rarity.MerchantChances)
	-- cobra só depois de criar (CreateDragon confere espaço de novo)
	local id = DragonService.CreateDragon(player, speciesId, rarityId)
	if not id then
		return
	end
	data.Coins -= price
	DataService.MarkChanged(player, "Coins")
	notify(player, string.format("Você comprou um ovo %s! Ele já está no ninho da sua fazenda.", Rarity.Defs[rarityId].DisplayName), "success")
end

function ShopService.Init()
	NetService.On("ShopBuy", onBuy)
	NetService.On("ShopSell", onSell)
	NetService.On("ShopBuyEgg", onBuyEgg)
end

-- Chamado pelo NPCService quando o jogador escolhe "Comprar e vender".
function ShopService.Open(player: Player)
	if nearMerchant(player) then
		NetService.Fire(player, "OpenShop")
	end
end

return ShopService
