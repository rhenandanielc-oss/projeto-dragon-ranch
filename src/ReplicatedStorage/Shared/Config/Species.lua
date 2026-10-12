--!strict
-- Espécies aprovadas (GAME-DESIGN.md §4.2). Valores numéricos são provisórios.

export type SpeciesDef = {
	Id: string,
	DisplayName: string,
	Elements: { string },
	Role: string,
	RoleText: string,
	CanFly: boolean,
	FlightStyle: string?, -- "Wings" | "Undulate"
	CanBurrow: boolean,
	Legs: number,
	HasWings: boolean,
}

local Species: { [string]: SpeciesDef } = {
	Wyvern = {
		Id = "Wyvern",
		DisplayName = "Wyvern",
		Elements = { "Fire", "Electric" },
		Role = "AerialStriker", -- dano explosivo, mergulhos; menos defesa
		RoleText = "Atacante aéreo: dano explosivo e mergulhos rápidos. Menos defesa.",
		CanFly = true,
		FlightStyle = "Wings",
		CanBurrow = false,
		Legs = 2,
		HasWings = true,
	},
	WesternDragon = {
		Id = "WesternDragon",
		DisplayName = "Dragão Ocidental",
		Elements = { "Fire" },
		Role = "Brute", -- mais vida e dano direto; velocidade média
		RoleText = "Força bruta: mais vida e dano direto. Velocidade média.",
		CanFly = true,
		FlightStyle = "Wings",
		CanBurrow = false,
		Legs = 4,
		HasWings = true,
	},
	Amphiptere = {
		Id = "Amphiptere",
		DisplayName = "Amphiptere",
		Elements = { "Wind", "Fire" },
		Role = "Mobility", -- o mais rápido no ar; menos vida
		RoleText = "Mobilidade: o mais rápido no ar, rajadas que empurram. Menos vida.",
		CanFly = true,
		FlightStyle = "Wings",
		CanBurrow = false,
		Legs = 0,
		HasWings = true,
	},
	Wyrm = {
		Id = "Wyrm",
		DisplayName = "Wyrm",
		Elements = { "Earth", "Water" },
		Role = "DefenseAmbush", -- mais defesa, muito rápido em terra; não voa
		RoleText = "Defesa e emboscada: muito rápido em terra, ataca saindo do chão. Não voa.",
		CanFly = false,
		FlightStyle = nil,
		CanBurrow = true, -- desbloqueado por missão no estágio Jovem
		Legs = 0,
		HasWings = false,
	},
	AsianDragon = {
		Id = "AsianDragon",
		DisplayName = "Dragão Asiático",
		Elements = { "Water", "Rain" },
		Role = "AreaSupport", -- tempestades em área, chuva cura aliados
		RoleText = "Área e suporte: tempestades em área e chuva que cura aliados. Dano direto menor.",
		CanFly = true,
		FlightStyle = "Undulate", -- voa sem asas, ondulando
		CanBurrow = false,
		Legs = 4,
		HasWings = false,
	},
}

return table.freeze(Species)
