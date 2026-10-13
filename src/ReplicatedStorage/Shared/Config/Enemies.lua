--!strict
-- Fase 5: inimigos básicos do mundo aberto. Valores PROVISÓRIOS.
-- Body: formato procedural simples (até a arte final). Drops vão direto para a mochila de quem
-- derrotou (sem item no chão: evita duplicação e roubo de loot).

export type EnemyDef = {
	Id: string,
	Name: string,
	Health: number,
	Damage: number,
	AttackRange: number,
	AttackInterval: number,
	WalkSpeed: number,
	AggroRange: number,
	Leash: number,
	Size: number, -- escala do corpo
	Body: string, -- "Quadruped" | "Spider" | "Golem" | "Humanoid"
	Color: Color3,
	Drops: { { Item: string, Min: number, Max: number, Chance: number } },
	Coins: { number },
}

local Enemies: { [string]: EnemyDef } = {
	Wolf = { Id = "Wolf", Name = "Lobo Cinzento", Health = 60, Damage = 8, AttackRange = 6, AttackInterval = 1.2, WalkSpeed = 20, AggroRange = 45, Leash = 140, Size = 1, Body = "Quadruped", Color = Color3.fromRGB(110, 108, 104), Drops = { { Item = "Meat", Min = 1, Max = 2, Chance = 0.7 } }, Coins = { 2, 5 } },
	Boar = { Id = "Boar", Name = "Javali", Health = 90, Damage = 10, AttackRange = 6, AttackInterval = 1.5, WalkSpeed = 17, AggroRange = 30, Leash = 120, Size = 1.1, Body = "Quadruped", Color = Color3.fromRGB(96, 70, 50), Drops = { { Item = "Meat", Min = 2, Max = 3, Chance = 0.9 } }, Coins = { 3, 6 } },
	Bandit = { Id = "Bandit", Name = "Saqueador", Health = 110, Damage = 12, AttackRange = 7, AttackInterval = 1.3, WalkSpeed = 16, AggroRange = 50, Leash = 160, Size = 1, Body = "Humanoid", Color = Color3.fromRGB(120, 60, 50), Drops = { { Item = "Arrow", Min = 3, Max = 8, Chance = 0.8 }, { Item = "HealthPotion", Min = 1, Max = 1, Chance = 0.12 } }, Coins = { 6, 12 } },
	Spider = { Id = "Spider", Name = "Aranha Gigante", Health = 130, Damage = 14, AttackRange = 7, AttackInterval = 1.4, WalkSpeed = 19, AggroRange = 55, Leash = 140, Size = 1.4, Body = "Spider", Color = Color3.fromRGB(40, 34, 40), Drops = { { Item = "Herb", Min = 1, Max = 2, Chance = 0.5 } }, Coins = { 6, 12 } },
	FireImp = { Id = "FireImp", Name = "Diabrete de Brasa", Health = 100, Damage = 15, AttackRange = 7, AttackInterval = 1.2, WalkSpeed = 18, AggroRange = 60, Leash = 150, Size = 0.9, Body = "Humanoid", Color = Color3.fromRGB(200, 70, 30), Drops = { { Item = "Obsidian", Min = 1, Max = 1, Chance = 0.35 } }, Coins = { 8, 14 } },
	IceWolf = { Id = "IceWolf", Name = "Lobo das Neves", Health = 120, Damage = 14, AttackRange = 6, AttackInterval = 1.1, WalkSpeed = 22, AggroRange = 55, Leash = 150, Size = 1.15, Body = "Quadruped", Color = Color3.fromRGB(220, 226, 236), Drops = { { Item = "Meat", Min = 1, Max = 2, Chance = 0.7 }, { Item = "Crystal", Min = 1, Max = 1, Chance = 0.12 } }, Coins = { 8, 14 } },
	CrystalGolem = { Id = "CrystalGolem", Name = "Golem de Cristal", Health = 320, Damage = 24, AttackRange = 9, AttackInterval = 2.2, WalkSpeed = 11, AggroRange = 45, Leash = 110, Size = 1.6, Body = "Golem", Color = Color3.fromRGB(140, 190, 240), Drops = { { Item = "Crystal", Min = 1, Max = 3, Chance = 0.9 } }, Coins = { 15, 28 } },
	StoneGolem = { Id = "StoneGolem", Name = "Golem de Pedra", Health = 360, Damage = 26, AttackRange = 9, AttackInterval = 2.4, WalkSpeed = 10, AggroRange = 40, Leash = 110, Size = 1.7, Body = "Golem", Color = Color3.fromRGB(120, 116, 110), Drops = { { Item = "Stone", Min = 3, Max = 6, Chance = 1 } }, Coins = { 15, 28 } },
}

-- Quantos inimigos manter por região perto dos jogadores (danger = zona perigosa: mais e mais fortes).
local Spawns = {
	forest = { Max = 6, List = { "Wolf", "Boar" } },
	meadow = { Max = 3, List = { "Boar" } },
	enchanted = { Max = 4, List = { "Wolf", "Spider" } },
	lakeland = { Max = 3, List = { "Boar", "Bandit" } },
	coast = { Max = 4, List = { "Bandit", "Boar" } },
	swamp = { Max = 5, List = { "Spider", "Boar" } },
	swampcore = { Max = 7, List = { "Spider", "Bandit" } },
	mountain = { Max = 4, List = { "Wolf", "Bandit" } },
	snow = { Max = 6, List = { "IceWolf", "StoneGolem" } },
	volcanic = { Max = 7, List = { "FireImp", "StoneGolem" } },
	crystal = { Max = 6, List = { "CrystalGolem", "Spider" } },
	ruins = { Max = 7, List = { "Bandit", "StoneGolem", "Spider" } },
	castle = { Max = 8, List = { "FireImp", "StoneGolem", "Bandit" } },
}

return table.freeze({ Defs = table.freeze(Enemies), Spawns = table.freeze(Spawns) })
