--!strict
-- Catálogo de itens. Começa pequeno; cresce a cada fase.
-- Lootable = pode cair em derrota PvP em zona perigosa (somente materiais coletados).

export type ItemDef = {
	Id: string,
	DisplayName: string,
	Category: string, -- Material | Food | Potion | Equipment | Ammo | Egg | Quest
	SellPrice: number?,
	BuyPrice: number?,
	Lootable: boolean,
}

local Items: { [string]: ItemDef } = {
	Arrow = { Id = "Arrow", DisplayName = "Flecha", Category = "Ammo", SellPrice = nil, BuyPrice = 1, Lootable = false },
	Meat = { Id = "Meat", DisplayName = "Carne", Category = "Food", SellPrice = 2, BuyPrice = 5, Lootable = false },
	WaterFlask = { Id = "WaterFlask", DisplayName = "Cantil de Água", Category = "Food", SellPrice = 1, BuyPrice = 3, Lootable = false },
	Wood = { Id = "Wood", DisplayName = "Madeira", Category = "Material", SellPrice = 2, BuyPrice = nil, Lootable = true },
	Stone = { Id = "Stone", DisplayName = "Pedra", Category = "Material", SellPrice = 2, BuyPrice = nil, Lootable = true },
	Feather = { Id = "Feather", DisplayName = "Pena", Category = "Material", SellPrice = 3, BuyPrice = nil, Lootable = true },
	Herb = { Id = "Herb", DisplayName = "Erva", Category = "Material", SellPrice = 4, BuyPrice = nil, Lootable = true },
	Obsidian = { Id = "Obsidian", DisplayName = "Obsidiana", Category = "Material", SellPrice = 10, BuyPrice = nil, Lootable = true },
	Crystal = { Id = "Crystal", DisplayName = "Cristal", Category = "Material", SellPrice = 15, BuyPrice = nil, Lootable = true },
	HealthPotion = { Id = "HealthPotion", DisplayName = "Poção de Vida", Category = "Potion", SellPrice = 5, BuyPrice = 20, Lootable = false },
	ReturnStone = { Id = "ReturnStone", DisplayName = "Pedra do Retorno", Category = "Equipment", SellPrice = nil, BuyPrice = nil, Lootable = false },
	FlightPotion = { Id = "FlightPotion", DisplayName = "Poção do Voo", Category = "Quest", SellPrice = nil, BuyPrice = nil, Lootable = false },
	BurrowPotion = { Id = "BurrowPotion", DisplayName = "Poção da Terra", Category = "Quest", SellPrice = nil, BuyPrice = nil, Lootable = false },
}

return table.freeze(Items)
