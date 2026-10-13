--!strict
-- Quadrado de item usado na mochila, no armazém, na barra e na loja.
-- Sem ícones finais ainda (arte): cor da categoria + nome curto + quantidade.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Items = require(ReplicatedStorage.Shared.Config.Items)

local ItemTile = {}

ItemTile.CategoryColor = {
	Material = Color3.fromRGB(120, 96, 70),
	Food = Color3.fromRGB(160, 86, 60),
	Potion = Color3.fromRGB(140, 60, 120),
	Equipment = Color3.fromRGB(80, 100, 140),
	Ammo = Color3.fromRGB(110, 110, 90),
	Egg = Color3.fromRGB(200, 160, 80),
	Quest = Color3.fromRGB(70, 130, 120),
}

function ItemTile.new(itemId: string?, count: number?, size: number, parent: Instance?): TextButton
	local def = itemId and Items[itemId]
	local tile = Theme.new("TextButton", {
		Name = "Tile",
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = def and (ItemTile.CategoryColor[def.Category] or Theme.Colors.PanelLight) or Theme.Colors.PanelLight,
		BackgroundTransparency = def and 0 or 0.4,
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	}, { Theme.corner(8) })
	if def then
		Theme.label(def.DisplayName, math.max(11, math.floor(size / 5.5)), {
			Font = Theme.BoldFont,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextStrokeTransparency = 0.6,
			Size = UDim2.new(1, -6, 0.7, 0),
			Position = UDim2.fromOffset(3, 2),
			Parent = tile,
		})
		if count and count > 1 then
			Theme.label("×" .. tostring(count), math.max(11, math.floor(size / 5)), {
				Font = Theme.BoldFont,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Theme.Colors.Accent,
				TextStrokeTransparency = 0.4,
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -4, 1, -2),
				Size = UDim2.new(1, -8, 0.32, 0),
				Parent = tile,
			})
		end
	end
	return tile
end

return ItemTile
