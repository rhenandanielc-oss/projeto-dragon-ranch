--!strict
-- Raridades aprovadas (GAME-DESIGN.md §4.2).
-- A raridade muda muito o dragão: visual dos ataques e do voo, velocidade de voo e mecânicas extras.
-- Bônus numéricos são PROVISÓRIOS e serão calibrados no balanceamento (cuidado com o PvP).

local Rarity = {}

Rarity.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

Rarity.Defs = {
	Common = { DisplayName = "Comum", Tier = 1, FlightSpeedMult = 1.00, ExtraMechanics = 0, Color = Color3.fromRGB(200, 200, 200) },
	Uncommon = { DisplayName = "Incomum", Tier = 2, FlightSpeedMult = 1.05, ExtraMechanics = 0, Color = Color3.fromRGB(90, 200, 90) },
	Rare = { DisplayName = "Raro", Tier = 3, FlightSpeedMult = 1.10, ExtraMechanics = 1, Color = Color3.fromRGB(70, 140, 255) },
	Epic = { DisplayName = "Épico", Tier = 4, FlightSpeedMult = 1.15, ExtraMechanics = 1, Color = Color3.fromRGB(170, 80, 255) },
	Legendary = { DisplayName = "Lendário", Tier = 5, FlightSpeedMult = 1.20, ExtraMechanics = 2, Color = Color3.fromRGB(255, 170, 30) },
	Mythic = { DisplayName = "Mítico", Tier = 6, FlightSpeedMult = 1.25, ExtraMechanics = 2, Color = Color3.fromRGB(255, 60, 90) },
	Secret = { DisplayName = "Secreto", Tier = 7, FlightSpeedMult = 1.30, ExtraMechanics = 3, Color = Color3.fromRGB(20, 255, 220) },
}

-- Chances para ninhos selvagens e baú da dungeon (soma = 100). Secreto nunca sai por sorte.
Rarity.WildChances = {
	{ Id = "Common", Weight = 55 },
	{ Id = "Uncommon", Weight = 25 },
	{ Id = "Rare", Weight = 12 },
	{ Id = "Epic", Weight = 5 },
	{ Id = "Legendary", Weight = 2.4 },
	{ Id = "Mythic", Weight = 0.6 },
}

-- Ovo do mercador: apenas Comum ou Incomum.
Rarity.MerchantChances = {
	{ Id = "Common", Weight = 80 },
	{ Id = "Uncommon", Weight = 20 },
}

Rarity.StarterRarity = "Common"

return table.freeze(Rarity)
