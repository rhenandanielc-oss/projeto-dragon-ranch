--!strict
-- Formato do perfil salvo de cada jogador (B8).
-- Ao mudar o formato: aumentar VERSION e adicionar uma migração em DataService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Config.Rules)
local Inventory = require(ReplicatedStorage.Shared.Config.Inventory)

local ProfileTemplate = {}

ProfileTemplate.VERSION = 1

-- Dragão salvo (referência; criado pelos sistemas da fase 2):
-- {
--   Id = "D1", Species = "Wyvern", Rarity = "Common", CustomName = "",
--   GrowthPoints = 0, Stage = "Egg",
--   Hunger = 100, Thirst = 100,
--   FlightUnlocked = false, BurrowUnlocked = false,
--   CareToday = 0, CareDay = 0,
--   CreatedAt = os.time(),
-- }

function ProfileTemplate.New(): { [string]: any }
	return {
		Version = ProfileTemplate.VERSION,

		Coins = Rules.Economy.StartCoins,

		StarterChosen = false,
		Dragons = {}, -- [dragonId] = dragão
		ActiveDragonId = nil,
		DragonSlots = Rules.Farm.StartDragonSlots,

		Backpack = { Capacity = Inventory.Backpack.StartCapacity, Slots = {} }, -- Slots[i] = { Item, Count, Uid? }
		Storage = { Capacity = Inventory.StorageCapacity, Slots = {} },
		Hotbar = {}, -- [1..8] = índice de slot da mochila
		QuestItems = {}, -- [itemId] = quantidade (não ocupa espaço)

		Quests = { Active = {}, Completed = {} },
		Farm = { Placed = {}, PreferredBiome = "" }, -- bioma preferido (escolha liberada com dragão Jovem)

		Travel = { Waypoints = {}, ReturnReadyAt = 0 }, -- Waypoints["3"] = true quando despertado

		Protection = { NewPlayer = true },
		Dungeon = { FinalChestReadyAt = 0 },

		Settings = { Graphics = "" }, -- "" = padrão do aparelho

		Stats = { FirstJoin = os.time(), PlayTimeSeconds = 0, Sessions = 0 },

		NextUid = 1, -- gerador de códigos únicos (dragões, equipamentos)
	}
end

-- Preenche campos que faltam em perfis antigos, sem apagar nada existente.
function ProfileTemplate.Reconcile(data: { [string]: any })
	local template = ProfileTemplate.New()
	local function fill(target: { [string]: any }, source: { [string]: any })
		for k, v in pairs(source) do
			if target[k] == nil then
				target[k] = v
			elseif type(v) == "table" and type(target[k]) == "table" and next(v) ~= nil then
				fill(target[k], v)
			end
		end
	end
	fill(data, template)
end

return ProfileTemplate
