--!strict
-- Fase 7: dungeon principal "Santuário da Cascata" (GAME-DESIGN §9.5). Valores PROVISÓRIOS.

local Dungeon = {}

Dungeon.Name = "Santuário da Cascata"
Dungeon.CircleRadius = 11
Dungeon.JoinWindowSeconds = 30 -- Rules.Dungeon.JoinWindowSeconds
Dungeon.MaxGroup = 4
Dungeon.ReconnectGraceSeconds = 180
Dungeon.ChestCooldownSeconds = 20 * 3600
Dungeon.AfterClearSeconds = 300 -- depois do chefe, tempo para abrir o baú e sair

-- Área isolada, fora do mapa, uma cópia por grupo (decisão técnica do V1-ROADMAP).
Dungeon.AreaOrigin = Vector3.new(26000, 600, 26000)
Dungeon.SlotSpacing = 2200
Dungeon.Slots = 5

-- Inimigos por sala (o número cresce com o tamanho do grupo: Base + PerMember × membros).
Dungeon.Rooms = {
	Spiders = { List = { "Spider", "Bandit" }, Base = 3, PerMember = 1 },
	Golems = { List = { "StoneGolem", "Spider" }, Base = 2, PerMember = 1 },
}

Dungeon.Boss = {
	Enemy = "StoneGolem",
	Name = "Guardião da Cascata",
	Scale = 1.8,
	HealthMultBase = 4, -- × vida do Golem de Pedra, + PerMember por membro
	HealthMultPerMember = 2,
	DamageMult = 1.3,
	SlamEvery = 6, -- segundos entre os golpes no chão (com aviso de 1 s)
	SlamRadius = 18,
	SlamDamage = 30,
}

Dungeon.SpikeDamage = 35

-- Baú final (loot individual). Recompensa completa só a cada 20 h por jogador.
Dungeon.Chest = {
	Coins = { 150, 250 },
	Items = {
		{ Item = "Crystal", Min = 2, Max = 4 },
		{ Item = "HealthPotion", Min = 1, Max = 2 },
		{ Item = "Arrow", Min = 15, Max = 25 },
	},
	ReducedCoins = 30, -- dentro do intervalo de 20 h
	-- item de missão para quem tem a missão ativa nessa etapa
	QuestItems = { FirstFlight = "FlightPotion", EarthCall = "BurrowPotion" },
	Points = 600, -- Growth.Sources.DungeonClear para o dragão ativo (recompensa completa)
}

return table.freeze(Dungeon)
