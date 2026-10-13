--!strict
-- Definição de TODA a comunicação cliente <-> servidor.
-- Nenhum remote existe fora desta lista; o servidor cria os remotes a partir dela.
--
-- Kind:      "Event" (RemoteEvent) | "Function" (RemoteFunction, só cliente -> servidor)
-- Direction: "C2S" (cliente pede) | "S2C" (servidor avisa)
-- Args:      esquema de validação dos argumentos que o CLIENTE envia (C2S).
--            Tipos: "string" (MaxLen), "number" (Min/Max), "integer" (Min/Max), "boolean", "enum" (Values), "Vector3" (MaxMagnitude)
-- Rate:      máximo de chamadas por segundo por jogador (balde de fichas; Burst = rajada permitida)
-- BeforeLoad: true se pode ser chamado antes do perfil carregar (padrão: false)

export type ArgSchema = {
	Type: string,
	Optional: boolean?,
	MaxLen: number?,
	Min: number?,
	Max: number?,
	Values: { string }?,
	MaxMagnitude: number?,
}

export type RemoteDef = {
	Kind: string,
	Direction: string,
	Args: { ArgSchema }?,
	Rate: number?,
	Burst: number?,
	BeforeLoad: boolean?,
}

local NetDefs: { [string]: RemoteDef } = {
	-- Cliente avisa que está pronto para receber os dados.
	ClientReady = { Kind = "Event", Direction = "C2S", Args = {}, Rate = 1, Burst = 3, BeforeLoad = true },

	-- Servidor envia uma cópia somente-leitura do perfil (o cliente nunca altera o perfil real).
	ProfileSnapshot = { Kind = "Event", Direction = "S2C" },

	-- Servidor avisa que um campo do perfil mudou (caminho, valor).
	ProfileChanged = { Kind = "Event", Direction = "S2C" },

	-- Servidor envia avisos curtos para a tela.
	Notify = { Kind = "Event", Direction = "S2C" },

	-- Fase 2: fazenda e dragões
	ChooseStarter = { Kind = "Event", Direction = "C2S", Args = { { Type = "enum", Values = { "Wyvern", "WesternDragon", "Amphiptere", "Wyrm", "AsianDragon" } } }, Rate = 0.5, Burst = 2 },
	RenameDragon = { Kind = "Event", Direction = "C2S", Args = { { Type = "string", MaxLen = 16 }, { Type = "string", MaxLen = 60 } }, Rate = 0.5, Burst = 3 },
	SetActiveDragon = { Kind = "Event", Direction = "C2S", Args = { { Type = "string", MaxLen = 16 } }, Rate = 1, Burst = 3 },
	ExpandDragonSlots = { Kind = "Event", Direction = "C2S", Args = {}, Rate = 0.5, Burst = 2 },

	-- Fase 3: dragão companheiro e montaria
	ToggleCompanion = { Kind = "Event", Direction = "C2S", Args = {}, Rate = 0.5, Burst = 2 }, -- chamar / guardar na fazenda
	MountDragon = { Kind = "Event", Direction = "C2S", Args = {}, Rate = 1, Burst = 3 },
	DismountDragon = { Kind = "Event", Direction = "C2S", Args = {}, Rate = 2, Burst = 4 },

	-- Fase 4: inventário, armazém e loja
	OpenStorage = { Kind = "Event", Direction = "S2C" },
	OpenShop = { Kind = "Event", Direction = "S2C" },
	StorageDeposit = { Kind = "Event", Direction = "C2S", Args = { { Type = "integer", Min = 1, Max = 60 }, { Type = "integer", Min = 1, Max = 50 } }, Rate = 6, Burst = 12 },
	StorageWithdraw = { Kind = "Event", Direction = "C2S", Args = { { Type = "integer", Min = 1, Max = 100 }, { Type = "integer", Min = 1, Max = 50 } }, Rate = 6, Burst = 12 },
	DiscardItem = { Kind = "Event", Direction = "C2S", Args = { { Type = "integer", Min = 1, Max = 60 }, { Type = "integer", Min = 1, Max = 50 } }, Rate = 3, Burst = 6 },
	ExpandBackpack = { Kind = "Event", Direction = "C2S", Args = {}, Rate = 0.5, Burst = 2 },
	SetHotbar = { Kind = "Event", Direction = "C2S", Args = { { Type = "integer", Min = 1, Max = 8 }, { Type = "string", MaxLen = 24 } }, Rate = 4, Burst = 10 },
	ShopBuy = { Kind = "Event", Direction = "C2S", Args = { { Type = "string", MaxLen = 24 }, { Type = "integer", Min = 1, Max = 50 } }, Rate = 3, Burst = 6 },
	ShopSell = { Kind = "Event", Direction = "C2S", Args = { { Type = "string", MaxLen = 24 }, { Type = "integer", Min = 1, Max = 10000 } }, Rate = 3, Burst = 6 },
	ShopBuyEgg = { Kind = "Event", Direction = "C2S", Args = {}, Rate = 0.3, Burst = 1 },

	-- Viagem: waypoints e Pedra do Retorno; uso de itens da barra
	OpenWaypoints = { Kind = "Event", Direction = "S2C" }, -- (id atual, { {Id, Name, X, Z} } despertados)
	TravelWaypoint = { Kind = "Event", Direction = "C2S", Args = { { Type = "integer", Min = 1, Max = 32 } }, Rate = 0.5, Burst = 2 },
	UseItem = { Kind = "Event", Direction = "C2S", Args = { { Type = "string", MaxLen = 24 } }, Rate = 1, Burst = 3 },
	ChannelStarted = { Kind = "Event", Direction = "S2C" }, -- (segundos, texto) barra de canalização na tela

	-- Mundo aberto: escolha do bioma da fazenda (mesa do cartógrafo no Hub).
	FarmChooser = { Kind = "Event", Direction = "S2C" }, -- (biomas livres, bioma atual, pode escolher)
	ChooseFarmBiome = { Kind = "Event", Direction = "C2S", Args = { { Type = "enum", Values = { "blossom", "coast", "crystal", "enchanted", "fir", "hidden", "lake", "meadow", "oak", "orchard", "pine", "rainforest", "redrock", "ruins", "snow", "swamp", "volcanic" } } }, Rate = 0.2, Burst = 2 },

	-- Ferramenta de qualidade gráfica: salva a escolha do jogador no perfil.
	SetGraphics = { Kind = "Event", Direction = "C2S", Args = { { Type = "enum", Values = { "Low", "Medium", "High", "Ultra" } } }, Rate = 1, Burst = 4 },

	-- Hub: servidor abre a conversa com um NPC (id do NPC).
	NpcDialog = { Kind = "Event", Direction = "S2C" },

	-- Diagnóstico: medir latência e testar a proteção de frequência.
	Ping = { Kind = "Function", Direction = "C2S", Args = { { Type = "integer", Min = 0, Max = 2 ^ 31 } }, Rate = 2, Burst = 5 },
}

return table.freeze(NetDefs)
