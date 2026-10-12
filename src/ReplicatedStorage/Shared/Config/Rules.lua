--!strict
-- Regras gerais aprovadas: servidor, economia, PvP, dungeon, combate. Valores numéricos provisórios onde indicado.

local Rules = {}

Rules.Server = {
	MaxPlayers = 18,
	FarmPlots = 18,
	MapSize = 16000, -- studs por lado, centrado na origem
}

-- Mundo aberto (WORLD-DESIGN.md v0.2). Posição do Hub no mundo do Roblox (X = leste, Z = sul).
Rules.World = {
	HubPosition = Vector3.new(0, 16, 1500),
	FarmMoveCooldownSeconds = 120,
}

Rules.Farm = {
	StartDragonSlots = 3,
	MaxDragonSlots = 8,
	SlotExpansionCost = { 500, 1200, 2500, 5000, 9000 }, -- provisório: 4º ao 8º espaço
}

Rules.Economy = {
	CurrencyName = "Moedas", -- nome temático a definir
	StartCoins = 50,
	BackpackExpansionCost = { 300, 700, 1500, 3000, 6000, 10000 }, -- provisório: +5 espaços cada
	MerchantEggPrice = 2500, -- provisório
	ResourceRespawnSeconds = 240, -- provisório
	PlayerTrading = false, -- fora da V1
}

Rules.PvP = {
	DangerZoneLossFraction = 0.40, -- até 40% dos materiais carregados
	RespawnProtectionSeconds = 120,
	SameVictimLootCooldownSeconds = 1800,
	NewPlayerProtectionUntilStage = "Young", -- até o primeiro dragão virar Jovem
	-- Nunca perdidos: dragões, estágios, pontos, desbloqueios, equipamentos, moedas, itens de missão.
}

Rules.Dungeon = {
	MinGroup = 1,
	MaxGroup = 4,
	JoinWindowSeconds = 30,
	ReconnectGraceSeconds = 180,
	FinalChestCooldownSeconds = 20 * 3600,
	DeathEliminates = true, -- quem morre não volta à expedição; mantém o loot; sem baú final nem item de missão
}

Rules.Combat = {
	DragonRecallCooldownSeconds = 60,
	DodgeCooldownSeconds = 1.2, -- provisório
}

return table.freeze(Rules)
