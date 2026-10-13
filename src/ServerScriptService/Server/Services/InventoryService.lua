--!strict
-- Inventário no servidor: mochila (30→60), armazém da fazenda (100), barra de 8 itens.
-- Toda alteração de itens passa por aqui; o cliente só PEDE (e o servidor confere tudo).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Items = require(ReplicatedStorage.Shared.Config.Items)
local InventoryConfig = require(ReplicatedStorage.Shared.Config.Inventory)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)
local DataService = require(ServerScriptService.Server.Data.DataService)

local InventoryService = {}

type Slot = { Item: string, Count: number, Uid: string? }
type Container = { Capacity: number, Slots: { Slot } }

local function stackSize(itemId: string): number
	local def = Items[itemId]
	if not def then
		return 0
	end
	return InventoryConfig.StackSize[def.Category] or 1
end

local function isInt(n: number): boolean
	return n == n and n == math.floor(n) and n > 0 and n < 1e6
end

--------------------------------------------------------------------------
-- Operações genéricas sobre um contêiner (mochila ou armazém)
--------------------------------------------------------------------------
local function countIn(c: Container, itemId: string): number
	local total = 0
	for _, slot in ipairs(c.Slots) do
		if slot.Item == itemId then
			total += slot.Count
		end
	end
	return total
end

-- Quantas unidades cabem (sem alterar nada).
local function roomIn(c: Container, itemId: string): number
	local max = stackSize(itemId)
	local room = 0
	for _, slot in ipairs(c.Slots) do
		if slot.Item == itemId then
			room += max - slot.Count
		end
	end
	return room + (c.Capacity - #c.Slots) * max
end

local function addTo(c: Container, itemId: string, count: number): number
	local max = stackSize(itemId)
	local remaining = count
	for _, slot in ipairs(c.Slots) do
		if remaining <= 0 then
			break
		end
		if slot.Item == itemId and slot.Count < max then
			local put = math.min(max - slot.Count, remaining)
			slot.Count += put
			remaining -= put
		end
	end
	while remaining > 0 and #c.Slots < c.Capacity do
		local put = math.min(max, remaining)
		table.insert(c.Slots, { Item = itemId, Count = put })
		remaining -= put
	end
	return count - remaining
end

local function removeFrom(c: Container, itemId: string, count: number): boolean
	if countIn(c, itemId) < count then
		return false
	end
	local remaining = count
	for i = #c.Slots, 1, -1 do
		local slot = c.Slots[i]
		if slot.Item == itemId then
			local take = math.min(slot.Count, remaining)
			slot.Count -= take
			remaining -= take
			if slot.Count <= 0 then
				table.remove(c.Slots, i)
			end
			if remaining <= 0 then
				break
			end
		end
	end
	return true
end

--------------------------------------------------------------------------
-- API da mochila (usada pelos outros serviços)
--------------------------------------------------------------------------
function InventoryService.Count(player: Player, itemId: string): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	return countIn(data.Backpack, itemId)
end

function InventoryService.Room(player: Player, itemId: string): number
	local data = DataService.Get(player)
	if not data or not Items[itemId] then
		return 0
	end
	return roomIn(data.Backpack, itemId)
end

-- Adiciona até `count` unidades. Retorna quantas couberam.
function InventoryService.Add(player: Player, itemId: string, count: number): number
	local data = DataService.Get(player)
	if not data or not Items[itemId] or not isInt(count) then
		return 0
	end
	local added = addTo(data.Backpack, itemId, count)
	if added > 0 then
		DataService.MarkChanged(player, "Backpack")
	end
	return added
end

-- Remove exatamente `count` unidades. Não remove nada se não houver o suficiente.
function InventoryService.Remove(player: Player, itemId: string, count: number): boolean
	local data = DataService.Get(player)
	if not data or not isInt(count) then
		return false
	end
	if not removeFrom(data.Backpack, itemId, count) then
		return false
	end
	DataService.MarkChanged(player, "Backpack")
	return true
end

--------------------------------------------------------------------------
-- Armazém da fazenda (só perto do baú; quem confere a distância é o StorageService)
--------------------------------------------------------------------------
function InventoryService.Deposit(player: Player, slotIndex: number, count: number): (boolean, string?)
	local data = DataService.Get(player)
	if not data or not isInt(slotIndex) or not isInt(count) then
		return false
	end
	local slot = data.Backpack.Slots[slotIndex]
	if not slot then
		return false
	end
	local def = Items[slot.Item]
	if not def or def.Category == "Quest" then
		return false, "Esse item não pode ir para o armazém."
	end
	count = math.min(count, slot.Count)
	local itemId = slot.Item
	local fits = math.min(count, roomIn(data.Storage, itemId))
	if fits <= 0 then
		return false, "O armazém está cheio."
	end
	-- tira do espaço escolhido primeiro (o jogador vê exatamente o que saiu)
	slot.Count -= fits
	if slot.Count <= 0 then
		table.remove(data.Backpack.Slots, slotIndex)
	end
	addTo(data.Storage, itemId, fits)
	DataService.MarkChanged(player, "Backpack")
	DataService.MarkChanged(player, "Storage")
	return true
end

function InventoryService.Withdraw(player: Player, slotIndex: number, count: number): (boolean, string?)
	local data = DataService.Get(player)
	if not data or not isInt(slotIndex) or not isInt(count) then
		return false
	end
	local slot = data.Storage.Slots[slotIndex]
	if not slot then
		return false
	end
	count = math.min(count, slot.Count)
	local itemId = slot.Item
	local fits = math.min(count, roomIn(data.Backpack, itemId))
	if fits <= 0 then
		return false, "A mochila está cheia."
	end
	slot.Count -= fits
	if slot.Count <= 0 then
		table.remove(data.Storage.Slots, slotIndex)
	end
	addTo(data.Backpack, itemId, fits)
	DataService.MarkChanged(player, "Backpack")
	DataService.MarkChanged(player, "Storage")
	return true
end

-- Jogar fora (some de vez; não existe item no chão para outros pegarem).
function InventoryService.Discard(player: Player, slotIndex: number, count: number): boolean
	local data = DataService.Get(player)
	if not data or not isInt(slotIndex) or not isInt(count) then
		return false
	end
	local slot = data.Backpack.Slots[slotIndex]
	if not slot then
		return false
	end
	slot.Count -= math.min(count, slot.Count)
	if slot.Count <= 0 then
		table.remove(data.Backpack.Slots, slotIndex)
	end
	DataService.MarkChanged(player, "Backpack")
	return true
end

--------------------------------------------------------------------------
-- Ampliação da mochila e barra de itens
--------------------------------------------------------------------------
function InventoryService.ExpandBackpack(player: Player): (boolean, string)
	local data = DataService.Get(player)
	if not data then
		return false, ""
	end
	local bp = data.Backpack
	local cfg = InventoryConfig.Backpack
	if bp.Capacity >= cfg.MaxCapacity then
		return false, "Sua mochila já está no tamanho máximo."
	end
	local step = math.floor((bp.Capacity - cfg.StartCapacity) / cfg.ExpansionStep) + 1
	local cost = Rules.Economy.BackpackExpansionCost[step]
	if not cost then
		return false, "Sua mochila já está no tamanho máximo."
	end
	if data.Coins < cost then
		return false, string.format("Você precisa de %d %s.", cost, Rules.Economy.CurrencyName)
	end
	data.Coins -= cost
	bp.Capacity = math.min(cfg.MaxCapacity, bp.Capacity + cfg.ExpansionStep)
	DataService.MarkChanged(player, "Coins")
	DataService.MarkChanged(player, "Backpack")
	return true, string.format("Mochila ampliada: %d espaços.", bp.Capacity)
end

-- Hotbar["1".."8"] = id do item (a barra mostra a soma desse item na mochila).
function InventoryService.SetHotbar(player: Player, index: number, itemId: string)
	local data = DataService.Get(player)
	if not data or not isInt(index) or index > InventoryConfig.HotbarSize then
		return
	end
	if itemId ~= "" and not Items[itemId] then
		return
	end
	local key = tostring(index)
	-- o mesmo item não aparece em duas posições
	for k, v in pairs(data.Hotbar) do
		if v == itemId and k ~= key then
			data.Hotbar[k] = nil
		end
	end
	data.Hotbar[key] = if itemId == "" then nil else itemId
	DataService.MarkChanged(player, "Hotbar")
end

return InventoryService
