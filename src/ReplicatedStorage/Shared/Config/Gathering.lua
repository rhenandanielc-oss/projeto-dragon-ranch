--!strict
-- Fase 4: pontos de coleta espalhados pelo mundo (GAME-DESIGN §13). Valores PROVISÓRIOS.
-- O servidor cria os pontos ao iniciar, de forma determinística (mesma semente = mesmos lugares),
-- e cada ponto reaparece Rules.Economy.ResourceRespawnSeconds depois de coletado.

local Gathering = {}

-- Tipos de ponto: item entregue, quantidade (min..max) e tempo segurando a tecla.
Gathering.Nodes = {
	LogPile = { Item = "Wood", Min = 2, Max = 4, Hold = 1.2, Action = "Pegar madeira" },
	RockPile = { Item = "Stone", Min = 2, Max = 4, Hold = 1.4, Action = "Quebrar pedras" },
	HerbPatch = { Item = "Herb", Min = 1, Max = 3, Hold = 0.8, Action = "Colher ervas" },
	FeatherNest = { Item = "Feather", Min = 1, Max = 3, Hold = 0.8, Action = "Pegar penas" },
	CrystalNode = { Item = "Crystal", Min = 1, Max = 2, Hold = 2.0, Action = "Extrair cristal" },
	ObsidianNode = { Item = "Obsidian", Min = 1, Max = 2, Hold = 1.8, Action = "Extrair obsidiana" },
}

-- Quantos pontos de cada tipo por região (ids de WorldData.REGIONS).
Gathering.PerRegion = {
	forest = { LogPile = 28, HerbPatch = 10, RockPile = 6 },
	enchanted = { LogPile = 12, HerbPatch = 12, FeatherNest = 4 },
	meadow = { HerbPatch = 14, LogPile = 6, FeatherNest = 6, RockPile = 4 },
	lakeland = { HerbPatch = 8, FeatherNest = 8, LogPile = 6, RockPile = 4 },
	lake = { FeatherNest = 4 },
	coast = { FeatherNest = 12, RockPile = 10, HerbPatch = 6 },
	swamp = { HerbPatch = 14, LogPile = 8 },
	swampcore = { HerbPatch = 8, CrystalNode = 2 },
	mountain = { RockPile = 22, FeatherNest = 8, CrystalNode = 3 },
	snow = { RockPile = 10, CrystalNode = 8 },
	volcanic = { ObsidianNode = 14, RockPile = 10 },
	crystal = { CrystalNode = 16, RockPile = 6 },
	ruins = { RockPile = 12, HerbPatch = 6, CrystalNode = 3 },
	castle = { RockPile = 8, ObsidianNode = 4, CrystalNode = 3 },
}

Gathering.Seed = 7341
Gathering.InteractDistance = 14
Gathering.MinSecondsBetween = 0.7 -- anti-macro: intervalo mínimo entre coletas do mesmo jogador
Gathering.AvoidFarmRadius = 340 -- não nasce dentro das fazendas
Gathering.AvoidHubRadius = 520
Gathering.MaxSlope = 0.55 -- 0 = plano; acima disso o ponto é descartado

-- Fontes de água: cocho da fazenda e lagos dos acampamentos enchem cantis.
Gathering.WaterRefill = { Amount = 3, CooldownSeconds = 60 }
Gathering.CampFood = { Amount = 2, CooldownSeconds = 120 }

return table.freeze(Gathering)
