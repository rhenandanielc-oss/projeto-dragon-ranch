--!strict
-- Fase 10: ninhos selvagens (GAME-DESIGN §4.2). Valores PROVISÓRIOS.
-- Cada ninho é guardado por um dragão selvagem; vencendo o guardião, pega-se o ovo:
-- espécie aleatória, raridade pelas chances de Rarity.WildChances. Reaparecem com o tempo e são
-- mais comuns nas zonas perigosas. O Secreto só aparece num ninho escondido durante tempestades.

local Nests = {}

Nests.PerRegion = {
	forest = 1,
	enchanted = 1,
	coast = 1,
	mountain = 2,
	snow = 2,
	volcanic = 2,
	crystal = 2,
	ruins = 2,
	castle = 3,
	swampcore = 2,
}

Nests.Seed = 9157
Nests.RespawnSeconds = 1800 -- 30 min depois de pegarem o ovo
Nests.WakeDistance = 140 -- o guardião aparece quando alguém chega perto
Nests.ExclusiveSeconds = 60 -- quem venceu o guardião tem a vez de pegar o ovo
Nests.Guardian = { Enemy = "WildDrake", Leash = 70 }
Nests.DangerGuardianMult = 1.4 -- guardiões das zonas perigosas são mais fortes

-- Tempestades: de tempos em tempos, por alguns minutos (todos veem a chuva e os raios).
Nests.Storm = { MinGapSeconds = 90 * 60, MaxGapSeconds = 150 * 60, DurationSeconds = 8 * 60 }

-- Ninho secreto: lugar escondido numa zona perigosa, só durante a tempestade. Não aparece no mapa.
Nests.Secret = { x = 6950, y = -1250, GuardianScale = 1.35, GuardianHealthMult = 3, GuardianDamageMult = 1.5 }

return table.freeze(Nests)
