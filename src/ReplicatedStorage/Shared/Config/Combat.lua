--!strict
-- Fase 5: combate em tempo real (GAME-DESIGN §10.5). TODOS os números são PROVISÓRIOS
-- (balanceamento). O servidor usa estes valores para validar e calcular; o cliente só para mostrar.

local Combat = {}

Combat.Player = {
	MaxHealth = 100,
	RegenPerSecond = 1.5, -- fora de combate
	OutOfCombatSeconds = 8,
}

-- Espada: combo de 3 golpes + Golpe Giratório. Bloqueio reduz dano vindo da frente.
Combat.Sword = {
	ComboDamage = { 10, 12, 18 },
	Range = 9,
	ArcDegrees = 110,
	SwingInterval = 0.42, -- mínimo entre golpes
	ComboWindow = 1.0, -- tempo para emendar o próximo golpe
	Spin = { Damage = 22, Radius = 11, Cooldown = 8 },
	BlockReduction = 0.7,
	BlockArcDegrees = 120,
	BlockWalkSpeed = 8,
}

-- Arco: segurar para carregar; flechas finitas (item Arrow). Flecha Tripla gasta 3.
Combat.Bow = {
	MinDamage = 8,
	MaxDamage = 28,
	ChargeSeconds = 1.2,
	ArrowSpeed = 220,
	Range = 320,
	Gravity = 30, -- queda leve da flecha (studs/s²)
	ShotInterval = 0.35,
	Triple = { Damage = 14, SpreadDegrees = 7, Cooldown = 10, Arrows = 3 },
}

Combat.Dodge = {
	Distance = 18,
	Duration = 0.25,
	InvulnerableSeconds = 0.3,
	-- recarga: Rules.Combat.DodgeCooldownSeconds
}

-- Dragão: vida e ataque básico por estágio (Ovo e Bebê não lutam).
Combat.DragonStage = {
	Young = { Health = 220, Bite = 12, PowerMult = 1.0 },
	Subadult = { Health = 380, Bite = 18, PowerMult = 1.25 },
	Adult = { Health = 600, Bite = 26, PowerMult = 1.55 },
	Elder = { Health = 800, Bite = 32, PowerMult = 1.85 }, -- versões mais fortes dos poderes
}

Combat.DragonBite = { Range = 10, Interval = 1.3, AggroRange = 60, LeashFromOwner = 90 }

-- Papel da espécie muda vida/dano/defesa (GAME-DESIGN §4.2).
Combat.Roles = {
	AerialStriker = { Health = 0.85, Damage = 1.2, Defense = 0.0 },
	Brute = { Health = 1.25, Damage = 1.15, Defense = 0.05 },
	Mobility = { Health = 0.85, Damage = 1.0, Defense = 0.0 },
	DefenseAmbush = { Health = 1.3, Damage = 0.95, Defense = 0.2 },
	AreaSupport = { Health = 1.0, Damage = 0.9, Defense = 0.05 },
}

-- Raridade: mecânica extra simples por nível (acrescenta opções, não anula fraquezas).
Combat.RarityPowerBonus = { Common = 1.0, Uncommon = 1.03, Rare = 1.06, Epic = 1.09, Legendary = 1.12, Mythic = 1.15, Secret = 1.18 }

-- Poderes. Kind: "Projectile" (bola que explode), "Cone" (sopro à frente), "Line" (raio em linha),
-- "Area" (área em volta de um ponto), "Heal" (cura aliados na área), "Self" (escudo).
export type PowerDef = {
	Id: string,
	Name: string,
	Element: string,
	Kind: string,
	Damage: number,
	Radius: number,
	Range: number,
	Cooldown: number,
	Knockback: number?,
	Heal: number?,
	Slow: number?,
	Shield: number?,
	Duration: number?,
}

Combat.Powers = {
	-- elemento único
	Fireball = { Id = "Fireball", Name = "Bola de Fogo", Element = "Fire", Kind = "Projectile", Damage = 30, Radius = 10, Range = 140, Cooldown = 7 },
	ChainShock = { Id = "ChainShock", Name = "Choque em Corrente", Element = "Electric", Kind = "Line", Damage = 26, Radius = 4, Range = 90, Cooldown = 7 },
	Gust = { Id = "Gust", Name = "Rajada", Element = "Wind", Kind = "Cone", Damage = 14, Radius = 30, Range = 40, Cooldown = 6, Knockback = 70 },
	Quake = { Id = "Quake", Name = "Tremor", Element = "Earth", Kind = "Area", Damage = 24, Radius = 18, Range = 0, Cooldown = 9, Slow = 0.5, Duration = 3 },
	TideJet = { Id = "TideJet", Name = "Jato de Água", Element = "Water", Kind = "Line", Damage = 22, Radius = 5, Range = 70, Cooldown = 6, Knockback = 40 },
	HealingRain = { Id = "HealingRain", Name = "Chuva Curativa", Element = "Rain", Kind = "Heal", Damage = 0, Radius = 22, Range = 0, Cooldown = 14, Heal = 35, Duration = 5 },
	-- Dragão Ocidental (elemento único): sopro no Pré-adulto e o terceiro poder de Fogo, mais forte, no Adulto
	FlameBreath = { Id = "FlameBreath", Name = "Sopro de Chamas", Element = "Fire", Kind = "Cone", Damage = 30, Radius = 34, Range = 30, Cooldown = 8 },
	Inferno = { Id = "Inferno", Name = "Inferno", Element = "Fire", Kind = "Cone", Damage = 48, Radius = 40, Range = 36, Cooldown = 14 },
	-- combinados (Adulto)
	StormFire = { Id = "StormFire", Name = "Tempestade de Brasas", Element = "Fire+Electric", Kind = "Area", Damage = 46, Radius = 22, Range = 80, Cooldown = 15 },
	FireWhirl = { Id = "FireWhirl", Name = "Redemoinho de Fogo", Element = "Wind+Fire", Kind = "Area", Damage = 40, Radius = 20, Range = 0, Cooldown = 14, Knockback = 50 },
	MudFlood = { Id = "MudFlood", Name = "Enxurrada de Lama", Element = "Earth+Water", Kind = "Cone", Damage = 38, Radius = 40, Range = 45, Cooldown = 14, Slow = 0.4, Duration = 4 },
	Thunderstorm = { Id = "Thunderstorm", Name = "Tempestade", Element = "Water+Rain", Kind = "Area", Damage = 42, Radius = 26, Range = 90, Cooldown = 16 },
	-- defesa (Wyrm, papel de defesa)
	StoneSkin = { Id = "StoneSkin", Name = "Pele de Pedra", Element = "Earth", Kind = "Self", Damage = 0, Radius = 0, Range = 0, Cooldown = 18, Shield = 0.5, Duration = 6 },
}

-- Poderes por espécie e estágio: Z = 1º elemento (Jovem), X = 2º elemento (Pré-adulto),
-- C = combinado (Adulto). Ancião usa os mesmos, mais fortes.
Combat.SpeciesPowers = {
	Wyvern = { Z = "Fireball", X = "ChainShock", C = "StormFire" },
	WesternDragon = { Z = "Fireball", X = "FlameBreath", C = "Inferno" }, -- elemento único: três poderes de Fogo
	Amphiptere = { Z = "Gust", X = "Fireball", C = "FireWhirl" },
	Wyrm = { Z = "Quake", X = "TideJet", C = "MudFlood" },
	AsianDragon = { Z = "TideJet", X = "HealingRain", C = "Thunderstorm" },
}
Combat.PowerSlotStage = { Z = "Young", X = "Subadult", C = "Adult" }

Combat.DragonRestSeconds = 60 -- derrotado: recua e só pode ser chamado de novo depois disso
Combat.CommandRange = 140 -- F: atacar o alvo mirado até essa distância

return table.freeze(Combat)
