--!strict
-- Missões (Mestra Lira, no Hub). Valores e textos PROVISÓRIOS.
-- Tipos de etapa:
--   Collect  { Item, Count }        entregar itens da mochila (são consumidos na entrega)
--   Kill     { Enemies, Count }     derrotar inimigos (ids de Config/Enemies; vazio = qualquer)
--   Waypoints{ Count }              ter N obeliscos despertados
--   Reach    { Place, Radius }      chegar perto de um lugar ("DungeonGate")
--   QuestItem{ Item }               ter o item de missão (ex.: Poção do Voo da dungeon)
--   Talk     {}                     voltar e falar com a Mestra Lira
--   Feed     { Item }               dar o item de missão ao dragão ativo (perto dele)
-- PerDragon: a missão é feita uma vez POR DRAGÃO (voo / entrar na terra).

export type Step = { Kind: string, Text: string, Item: string?, Count: number?, Enemies: { string }?, Place: string?, Radius: number? }
export type QuestDef = {
	Id: string,
	Name: string,
	Giver: string,
	Summary: string,
	Steps: { Step },
	Reward: { Coins: number?, Points: number?, Items: { { Item: string, Count: number } }? },
	Requires: { [string]: any }?,
	Repeatable: boolean?,
	PerDragon: string?, -- "Flight" | "Burrow"
	Order: number,
}

local Quests: { [string]: QuestDef } = {
	FirstSteps = {
		Id = "FirstSteps",
		Name = "Primeiros Passos",
		Giver = "QuestMaster",
		Summary = "Junte um pouco de madeira e pedra pelo mundo para conhecer a coleta.",
		Steps = {
			{ Kind = "Collect", Text = "Entregue 5 Madeiras", Item = "Wood", Count = 5 },
			{ Kind = "Collect", Text = "Entregue 5 Pedras", Item = "Stone", Count = 5 },
		},
		Reward = { Coins = 60, Points = 60, Items = { { Item = "Arrow", Count = 20 } } },
		Order = 1,
	},
	Hunter = {
		Id = "Hunter",
		Name = "Caçador da Floresta",
		Giver = "QuestMaster",
		Summary = "Lobos e javalis andam atacando viajantes perto das estradas.",
		Steps = {
			{ Kind = "Kill", Text = "Derrote 5 lobos ou javalis", Enemies = { "Wolf", "Boar" }, Count = 5 },
			{ Kind = "Talk", Text = "Volte à Mestra Lira" },
		},
		Reward = { Coins = 90, Points = 80, Items = { { Item = "HealthPotion", Count = 2 } } },
		Order = 2,
	},
	Explorer = {
		Id = "Explorer",
		Name = "Os Obeliscos Antigos",
		Giver = "QuestMaster",
		Summary = "Obeliscos rúnicos espalhados pelas terras distantes permitem viajar. Desperte dois deles.",
		Steps = {
			{ Kind = "Waypoints", Text = "Desperte 2 obeliscos", Count = 2 },
			{ Kind = "Talk", Text = "Volte à Mestra Lira" },
		},
		Reward = { Coins = 120, Points = 120 },
		Order = 3,
	},
	Herbalist = {
		Id = "Herbalist",
		Name = "Ervas para a Vovó Brisa",
		Giver = "QuestMaster",
		Summary = "A Vovó Brisa precisa de ervas para preparar remédios para os dragões.",
		Steps = {
			{ Kind = "Collect", Text = "Entregue 6 Ervas", Item = "Herb", Count = 6 },
		},
		Reward = { Coins = 70, Items = { { Item = "HealthPotion", Count = 2 } } },
		Repeatable = true,
		Order = 4,
	},
	FirstFlight = {
		Id = "FirstFlight",
		Name = "O Primeiro Voo",
		Giver = "QuestMaster",
		Summary = "Existe uma poção capaz de fazer um dragão Jovem voar. Ela está numa dungeon ao norte, onde a água cai sobre pedra antiga.",
		Steps = {
			{ Kind = "Reach", Text = "Encontre o portão escondido ao norte (atrás de uma cachoeira)", Place = "DungeonGate", Radius = 70 },
			{ Kind = "QuestItem", Text = "Conclua a dungeon e pegue a Poção do Voo", Item = "FlightPotion" },
			{ Kind = "Talk", Text = "Volte à Mestra Lira com a poção" },
			{ Kind = "Feed", Text = "Dê a Poção do Voo ao seu dragão (perto dele)", Item = "FlightPotion" },
		},
		Reward = { Points = 200 },
		Requires = { ActiveStage = "Young", CanFly = true },
		PerDragon = "Flight",
		Order = 10,
	},
	EarthCall = {
		Id = "EarthCall",
		Name = "O Chamado da Terra",
		Giver = "QuestMaster",
		Summary = "Os Wyrms antigos sabiam nadar pela terra. A Poção da Terra está na mesma dungeon ao norte.",
		Steps = {
			{ Kind = "Reach", Text = "Encontre o portão escondido ao norte (atrás de uma cachoeira)", Place = "DungeonGate", Radius = 70 },
			{ Kind = "QuestItem", Text = "Conclua a dungeon e pegue a Poção da Terra", Item = "BurrowPotion" },
			{ Kind = "Talk", Text = "Volte à Mestra Lira com a poção" },
			{ Kind = "Feed", Text = "Dê a Poção da Terra ao seu Wyrm (perto dele)", Item = "BurrowPotion" },
		},
		Reward = { Points = 200 },
		Requires = { ActiveStage = "Young", Species = "Wyrm" },
		PerDragon = "Burrow",
		Order = 11,
	},
}

return table.freeze(Quests)
