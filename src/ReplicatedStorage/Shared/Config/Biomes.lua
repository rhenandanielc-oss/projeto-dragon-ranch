--!strict
-- Biomas das fazendas (WORLD-DESIGN.md §3). Os ids batem com WorldData.FARMS[i].biome.

local Biomes = {
	meadow = { DisplayName = "Prado do Riacho", Text = "Bétulas, carvalhos e um riacho; perto do Hub." },
	pine = { DisplayName = "Pinheiral", Text = "Pinheiros altos na borda da Floresta Densa." },
	lake = { DisplayName = "Lago", Text = "Salgueiros e juncos à beira do Grande Lago, ou numa ilha." },
	blossom = { DisplayName = "Colina das Flores", Text = "Cerejeiras e campos floridos ao norte do Hub." },
	orchard = { DisplayName = "Pomar do Moinho", Text = "Pomar e sebes altas no sudeste." },
	oak = { DisplayName = "Raízes Antigas", Text = "Carvalhos gigantes com raízes expostas." },
	rainforest = { DisplayName = "Cascata do Oeste", Text = "Floresta úmida junto ao Rio Principal." },
	enchanted = { DisplayName = "Bosque Encantado", Text = "Árvores que brilham e cogumelos gigantes." },
	fir = { DisplayName = "Mirante do Penhasco", Text = "Abetos em terraços com vista do mapa." },
	swamp = { DisplayName = "Brejo", Text = "Ciprestes e névoa na borda do Pântano." },
	coast = { DisplayName = "Costa Sul", Text = "Pinheiros da costa e dunas perto do Farol." },
	redrock = { DisplayName = "Garganta Rubra", Text = "Rochas vermelhas na borda do Cânion." },
	snow = { DisplayName = "Geleira", Text = "Pinheiros nevados nos Picos Gelados." },
	volcanic = { DisplayName = "Fontes Termais", Text = "Oásis de fontes quentes perto do Vulcão." },
	crystal = { DisplayName = "Cristalina", Text = "Pinheiros azulados e cristais no extremo leste." },
	ruins = { DisplayName = "Ruínas Antigas", Text = "Árvores entre colunas caídas no Planalto." },
	hidden = { DisplayName = "Vale Oculto", Text = "O lugar mais escondido do mapa, além de uma caverna." },
}

local ids = {}
for id in pairs(Biomes) do
	table.insert(ids, id)
end
table.sort(ids)

return table.freeze({ List = Biomes, Ids = table.freeze(ids) })
