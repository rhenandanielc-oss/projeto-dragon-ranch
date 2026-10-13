--!strict
-- Aviso de zona (GAME-DESIGN §11): ao entrar em cada tipo de zona, uma faixa explica o risco.
-- Também mostra um selo pequeno e fixo com a zona atual, embaixo da bússola.

local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)
local NetClient = require(game:GetService("ReplicatedStorage").Shared.Net.NetClient)

local player = Players.LocalPlayer
local ZoneBanner = {}

local INFO = {
	Safe = { Title = "Zona protegida", Text = "Sem PvP. Aqui ninguém pode atacar você.", Color = Color3.fromRGB(110, 200, 120) },
	Common = { Title = "Zona comum", Text = "PvP ativo, mas quem perde não perde itens.", Color = Color3.fromRGB(240, 190, 70) },
	Dungeon = { Title = "Dungeon", Text = "Sem PvP. Quem morrer sai da expedição (mas fica com o que coletou).", Color = Color3.fromRGB(150, 120, 255) },
	Danger = { Title = "Zona perigosa", Text = "PvP com perda: quem perde deixa até 40% dos materiais que carrega. Guarde tudo no baú antes!", Color = Color3.fromRGB(230, 80, 70) },
}

function ZoneBanner.Init(screen: ScreenGui)
	local banner = Theme.new("Frame", {
		Name = "ZoneBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 74),
		Size = UDim2.fromOffset(460, 64),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = screen,
	}, { Theme.corner(10), Theme.padding(8) })
	local stroke = Theme.stroke()
	stroke.Parent = banner
	local title = Theme.label("", 20, { Font = Theme.TitleFont, TextXAlignment = Enum.TextXAlignment.Center, Parent = banner })
	local text = Theme.label("", 14, { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Parent = banner })

	local chip = Theme.new("TextLabel", {
		Name = "ZoneChip",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 46),
		Size = UDim2.fromOffset(150, 20),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.25,
		Font = Theme.BoldFont,
		TextSize = 13,
		TextColor3 = Theme.Colors.Text,
		Text = "",
		Parent = screen,
	}, { Theme.corner(10) })

	-- botão para sair da expedição (só aparece dentro da dungeon)
	local leave = Theme.button("Sair da expedição", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(170, 34), TextSize = 14, BackgroundColor3 = Theme.Colors.ButtonAlt, Visible = false, Parent = screen })
	leave.Activated:Connect(function()
		NetClient.Fire("LeaveDungeon")
	end)
	player:GetAttributeChangedSignal("InDungeon"):Connect(function()
		leave.Visible = player:GetAttribute("InDungeon") ~= nil
	end)

	local token = 0
	local function show(zone: string)
		local info = INFO[zone]
		if not info then
			return
		end
		chip.Text = info.Title
		chip.TextColor3 = info.Color
		title.Text = info.Title
		title.TextColor3 = info.Color
		text.Text = info.Text
		stroke.Color = info.Color
		banner.Visible = true
		banner.BackgroundTransparency = 0.1
		token += 1
		local my = token
		task.delay(4.5, function()
			if my == token then
				banner.Visible = false
			end
		end)
	end
	player:GetAttributeChangedSignal("Zone"):Connect(function()
		show(player:GetAttribute("Zone") :: string)
	end)
	local z = player:GetAttribute("Zone")
	if type(z) == "string" then
		chip.Text = INFO[z] and INFO[z].Title or ""
	end
end

return ZoneBanner
