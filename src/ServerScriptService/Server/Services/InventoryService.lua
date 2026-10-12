--!strict
-- Inventário no servidor (núcleo). A interface completa chega na Fase 4.
-- Toda alteração de itens passa por aqui; o cliente nunca altera a mochila.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Items = require(ReplicatedStorage.Shared.Config.Items)
local InventoryConfig = require(ReplicatedStorage.Shared.Config.Inventory)
local DataService = require(ServerScriptService.Server.Data.DataService)

local InventoryService = {}

local function stackSize(itemId: string): number
	local def = Items[itemId]
	if not def then
		return 0
	end
	return InventoryConfig.StackSize[def.Category] or 1
end

function InventoryService.Count(player: Player, itemId: string): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local total = 0
	for _, slot in ipairs(data.Backpack.Slots) do
		if slot.Item == itemId then
			total += slot.Count
		end
	end
	return total
end

-- Adiciona até `count` unidades. Retorna quantas couberam.
function InventoryService.Add(player: Player, itemId: string, count: number): number
	local data = DataService.Get(player)
	if not data or not Items[itemId] or count <= 0 or count ~= math.floor(count) then
		return 0
	end
	local max = stackSize(itemId)
	local backpack = data.Backpack
	local remaining = count
	for _, slot in ipairs(backpack.Slots) do
		if remaining <= 0 then
			break
		end
		if slot.Item == itemId and slot.Count < max then
			local put = math.min(max - slot.Count, remaining)
			slot.Count += put
			remaining -= put
		end
	end
	while remaining > 0 and #backpack.Slots < backpack.Capacity do
		local put = math.min(max, remaining)
		table.insert(backpack.Slots, { Item = itemId, Count = put })
		remaining -= put
	end
	local added = count - remaining
	if added > 0 then
		DataService.MarkChanged(player, "Backpack")
	end
	return added
end

-- Remove exatamente `count` unidades. Não remove nada se não houver o suficiente.
function InventoryService.Remove(player: Player, itemId: string, count: number): boolean
	if count <= 0 or count ~= math.floor(count) then
		return false
	end
	if InventoryService.Count(player, itemId) < count then
		return false
	end
	local data = DataService.Get(player) :: { [string]: any }
	local slots = data.Backpack.Slots
	local remaining = count
	for i = #slots, 1, -1 do
		local slot = slots[i]
		if slot.Item == itemId then
			local take = math.min(slot.Count, remaining)
			slot.Count -= take
			remaining -= take
			if slot.Count <= 0 then
				table.remove(slots, i)
			end
			if remaining <= 0 then
				break
			end
		end
	end
	DataService.MarkChanged(player, "Backpack")
	return true
end

return InventoryService
