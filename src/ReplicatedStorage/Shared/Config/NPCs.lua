--!strict
-- NPCs do Hub Central. As falas ficam aqui para ajustar sem mexer no código.
-- Body: cores do personagem (provisório até a arte final dos NPCs).

local NPCs = {
	Merchant = {
		Name = "Tobias",
		Title = "Mercador",
		Body = { Skin = Color3.fromRGB(234, 184, 146), Shirt = Color3.fromRGB(196, 120, 40), Pants = Color3.fromRGB(90, 64, 42) },
		Lines = {
			"Bem-vindo às Terras de Escamarra, viajante!",
			"Em breve vou vender comida, água, poções e até ovos de dragão.",
			"Também vou comprar os materiais que você coletar pelo mundo. Volte logo!",
		},
	},
	QuestMaster = {
		Name = "Mestra Lira",
		Title = "Missões",
		Body = { Skin = Color3.fromRGB(198, 140, 104), Shirt = Color3.fromRGB(110, 70, 160), Pants = Color3.fromRGB(60, 50, 80) },
		Lines = {
			"Olá! Eu guardo os pedidos de ajuda de toda a região.",
			"Quando seu dragão for Jovem, venha me procurar: há uma poção capaz de fazê-lo voar.",
			"Dizem que ela está numa dungeon ao norte, onde a água cai sobre pedra antiga...",
		},
	},
	Caretaker = {
		Name = "Vovó Brisa",
		Title = "Cuidadora de Dragões",
		Body = { Skin = Color3.fromRGB(240, 200, 170), Shirt = Color3.fromRGB(90, 150, 90), Pants = Color3.fromRGB(70, 90, 60) },
		Lines = {
			"Ah, um novo criador! Deixe-me dar alguns conselhos.",
			"Ovos só chocam aquecidos no ninho da sua fazenda, e só com você por perto.",
			"Dragões com fome ou sede crescem na metade do ritmo. Mantenha o cocho e o bebedouro em dia!",
			"Treine ou brinque com seu dragão a cada 5 minutos, e não esqueça do carinho.",
		},
	},
	Guard = {
		Name = "Guarda Hilda",
		Title = "Guarda da Vila",
		Body = { Skin = Color3.fromRGB(170, 120, 90), Shirt = Color3.fromRGB(150, 150, 160), Pants = Color3.fromRGB(70, 70, 80) },
		Lines = {
			"A vila e as fazendas são protegidas: aqui ninguém pode atacar você.",
			"Nas zonas comuns pode haver duelos, mas quem perde não perde nada.",
			"Nas zonas perigosas, quem perde deixa cair parte dos materiais. Guarde tudo no baú da fazenda antes de ir!",
		},
	},
}

return table.freeze(NPCs)
