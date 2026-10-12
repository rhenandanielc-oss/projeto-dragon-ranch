--!strict
-- Seis elementos aprovados (GAME-DESIGN.md §4.2). Cores são placeholders até a direção de arte definir as paletas.

local Elements = {
	Fire = { Id = "Fire", DisplayName = "Fogo", Color = Color3.fromRGB(255, 110, 40), Style = "Dano direto" },
	Electric = { Id = "Electric", DisplayName = "Eletricidade", Color = Color3.fromRGB(255, 230, 70), Style = "Rápido e direto: choques, correntes, alvo único ou em linha" },
	Wind = { Id = "Wind", DisplayName = "Vento", Color = Color3.fromRGB(190, 240, 230), Style = "Mobilidade e empurrões" },
	Earth = { Id = "Earth", DisplayName = "Terra", Color = Color3.fromRGB(150, 110, 70), Style = "Defesa e ataques saindo do chão" },
	Water = { Id = "Water", DisplayName = "Água", Color = Color3.fromRGB(40, 140, 255), Style = "Controla massas de água: mar, rios" },
	Rain = { Id = "Rain", DisplayName = "Chuva", Color = Color3.fromRGB(110, 120, 200), Style = "Em área e lento: tempestades, raios numa região, chuva" },
}

return table.freeze(Elements)
