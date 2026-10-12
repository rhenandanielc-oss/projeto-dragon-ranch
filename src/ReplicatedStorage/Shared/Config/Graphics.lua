--!strict
-- Níveis de gráfico da ferramenta de qualidade do jogo (aplicados só no cliente).
-- "Ultra" usa os valores completos configurados no Lighting do mapa.

export type Preset = {
	DisplayName: string,
	Text: string,
	Shadows: boolean, -- sombras globais
	Bloom: number, -- multiplicador da intensidade
	SunRays: boolean,
	ColorCorrection: boolean,
	DepthOfField: boolean,
	Atmosphere: number, -- multiplicador da densidade da névoa
	Details: boolean, -- arbustos, flores e samambaias pequenas
	Effects: boolean, -- partículas, fogo e luzes pequenas
	Clouds: boolean,
	Wind: boolean, -- folhas e arbustos balançando
}

local Graphics: { [string]: Preset } = {
	Low = { DisplayName = "Baixo", Text = "Para celulares e PCs fracos: sem sombras, sem efeitos de tela e sem detalhes pequenos.", Shadows = false, Bloom = 0, SunRays = false, ColorCorrection = false, DepthOfField = false, Atmosphere = 0.8, Details = false, Effects = false, Clouds = false, Wind = false },
	Medium = { DisplayName = "Médio", Text = "Sombras e cores, sem raios de sol nem desfoque; detalhes pequenos escondidos.", Shadows = true, Bloom = 0.5, SunRays = false, ColorCorrection = true, DepthOfField = false, Atmosphere = 1, Details = false, Effects = true, Clouds = true, Wind = true },
	High = { DisplayName = "Alto", Text = "Tudo ligado, menos o desfoque de distância.", Shadows = true, Bloom = 1, SunRays = true, ColorCorrection = true, DepthOfField = false, Atmosphere = 1, Details = true, Effects = true, Clouds = true, Wind = true },
	Ultra = { DisplayName = "Ultra", Text = "Visual completo, com desfoque cinematográfico ao longe.", Shadows = true, Bloom = 1, SunRays = true, ColorCorrection = true, DepthOfField = true, Atmosphere = 1, Details = true, Effects = true, Clouds = true, Wind = true },
}

return table.freeze({ Presets = Graphics, Order = { "Low", "Medium", "High", "Ultra" } })
