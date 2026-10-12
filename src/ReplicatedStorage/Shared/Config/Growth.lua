--!strict
-- Crescimento somente por pontos, ritmo demorado (GAME-DESIGN.md §5.2). Valores PROVISÓRIOS.
-- Referência de calibração: ~10 pontos por minuto de jogo ativo com o dragão.

local Growth = {}

Growth.Stages = { "Egg", "Baby", "Young", "Subadult", "Adult", "Elder" }

Growth.StageNames = {
	Egg = "Ovo",
	Baby = "Bebê",
	Young = "Jovem",
	Subadult = "Pré-adulto",
	Adult = "Adulto",
	Elder = "Ancião",
}

-- Pontos acumulados necessários para ENTRAR em cada estágio.
Growth.Thresholds = {
	Egg = 0,
	Baby = 300, -- ~30 min
	Young = 2100, -- ~3,5 h
	Subadult = 7800, -- ~13 h
	Adult = 19200, -- ~32 h
	Elder = 51000, -- ~85 h
}

Growth.PointsPerMinuteEstimate = 10

-- Fontes de pontos (por evento). Cuidados têm limite diário.
Growth.Sources = {
	Feed = 15,
	Drink = 15,
	Pet = 5,
	CareDailyCap = 300, -- soma máxima diária de pontos vindos de cuidados
	TrainingPerSession = 60,
	TrainingCooldownSeconds = 300,
	CombatKillBasic = 8,
	ExplorationDiscovery = 40,
	QuestSmall = 150,
	QuestLarge = 400,
	DungeonClear = 600,
	FarmIdleMultiplier = 0.25, -- dragões não ativos ganham uma fração com cuidados/treino
}

-- Fome e sede: abaixo do limite, o dragão ganha metade dos pontos. Nunca regride nem morre.
Growth.Needs = {
	Max = 100,
	HungryThreshold = 30,
	DecayPerMinuteActive = 1.0,
	DecayPerMinuteFarm = 0.3,
	HungryPointsMultiplier = 0.5,
}

-- Estágio mínimo para montar, voar (após missão) e entrar na terra (Wyrm, após missão).
Growth.RideStage = "Young"
Growth.FlightStage = "Young"
Growth.BurrowStage = "Young"
Growth.CombatStage = "Young" -- Ovo e Bebê não lutam

function Growth.StageIndex(stage: string): number
	for i, s in ipairs(Growth.Stages) do
		if s == stage then
			return i
		end
	end
	return 0
end

function Growth.StageForPoints(points: number): string
	local result = "Egg"
	for _, s in ipairs(Growth.Stages) do
		if points >= Growth.Thresholds[s] then
			result = s
		end
	end
	return result
end

return table.freeze(Growth)
