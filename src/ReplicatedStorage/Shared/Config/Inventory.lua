--!strict
-- Inventário aprovado (GAME-DESIGN.md §12.1).

local Inventory = {}

Inventory.Backpack = {
	StartCapacity = 30,
	MaxCapacity = 60,
	ExpansionStep = 5,
}

Inventory.StorageCapacity = 100 -- armazém da fazenda, seguro (fora do PvP)
Inventory.HotbarSize = 8 -- barra de itens visível na tela

-- Empilhamento máximo por categoria.
Inventory.StackSize = {
	Material = 50,
	Food = 20,
	Potion = 10,
	Equipment = 1,
	Ammo = 50, -- flechas (provisório)
	Egg = 1,
}

return table.freeze(Inventory)
