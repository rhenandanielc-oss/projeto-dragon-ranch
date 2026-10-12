--!strict
-- Visual comum da interface: fantasia estilizada, legível em PC e celular.

local Theme = {}

Theme.Colors = {
	Panel = Color3.fromRGB(34, 28, 40),
	PanelLight = Color3.fromRGB(52, 44, 60),
	Stroke = Color3.fromRGB(214, 170, 92),
	Text = Color3.fromRGB(250, 242, 228),
	TextDim = Color3.fromRGB(190, 180, 170),
	Accent = Color3.fromRGB(240, 170, 60),
	Good = Color3.fromRGB(110, 200, 110),
	Warn = Color3.fromRGB(240, 180, 60),
	Bad = Color3.fromRGB(230, 90, 80),
	Hunger = Color3.fromRGB(230, 130, 70),
	Thirst = Color3.fromRGB(80, 160, 240),
	Growth = Color3.fromRGB(170, 120, 240),
	Button = Color3.fromRGB(196, 120, 40),
	ButtonAlt = Color3.fromRGB(80, 70, 92),
}

Theme.TitleFont = Enum.Font.FredokaOne
Theme.BodyFont = Enum.Font.GothamMedium
Theme.BoldFont = Enum.Font.GothamBold

-- Cria uma instância com propriedades e filhos.
function Theme.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Theme.corner(radius: number?): UICorner
	return Theme.new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function Theme.stroke(color: Color3?, thickness: number?): UIStroke
	return Theme.new("UIStroke", { Color = color or Theme.Colors.Stroke, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function Theme.padding(px: number): UIPadding
	return Theme.new("UIPadding", { PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px), PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px) })
end

function Theme.label(text: string, size: number, props: { [string]: any }?): TextLabel
	local p = {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size,
		Font = Theme.BodyFont,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, size + 6),
	}
	if props then
		for k, v in pairs(props) do
			p[k] = v
		end
	end
	return Theme.new("TextLabel", p)
end

-- Botão com tamanho mínimo confortável para toque (44 px).
function Theme.button(text: string, props: { [string]: any }?): TextButton
	local p = {
		Text = text,
		TextSize = 18,
		Font = Theme.BoldFont,
		TextColor3 = Theme.Colors.Text,
		BackgroundColor3 = Theme.Colors.Button,
		AutoButtonColor = true,
		Size = UDim2.fromOffset(140, 44),
	}
	if props then
		for k, v in pairs(props) do
			p[k] = v
		end
	end
	return Theme.new("TextButton", p, { Theme.corner(8) })
end

-- Barra de progresso; retorna o frame e uma função para atualizar.
function Theme.bar(color: Color3, height: number?): (Frame, (fraction: number, text: string?) -> ())
	local frame = Theme.new("Frame", {
		BackgroundColor3 = Color3.fromRGB(20, 16, 24),
		Size = UDim2.new(1, 0, 0, height or 16),
	}, { Theme.corner(6) })
	local fill = Theme.new("Frame", { Name = "Fill", BackgroundColor3 = color, Size = UDim2.fromScale(0, 1), Parent = frame }, { Theme.corner(6) })
	local label = Theme.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Theme.BoldFont,
		TextSize = math.max(11, (height or 16) - 4),
		TextColor3 = Theme.Colors.Text,
		TextStrokeTransparency = 0.6,
		Text = "",
		ZIndex = 3,
		Parent = frame,
	})
	local function set(fraction: number, text: string?)
		fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		label.Text = text or ""
	end
	return frame, set
end

return Theme
