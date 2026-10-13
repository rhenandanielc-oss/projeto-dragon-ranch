--!strict
-- Quadro de missões da Mestra Lira + lista curta das missões ativas no canto da tela.
-- Também mostra os tutoriais (voo, entrar na terra) quando o servidor libera.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)
local NetClient = require(ReplicatedStorage.Shared.Net.NetClient)

local QuestPanel = {}

local panel: Frame
local list: ScrollingFrame
local tracker: Frame
local tutorial: Frame
local tutorialTitle: TextLabel
local tutorialText: TextLabel
local log: { any } = {}

local function rewardText(r: any): string
	local parts = {}
	if r.Coins then
		table.insert(parts, r.Coins .. " moedas")
	end
	if r.Points then
		table.insert(parts, r.Points .. " pontos")
	end
	if r.Items then
		for _, it in ipairs(r.Items) do
			table.insert(parts, it.Count .. "× " .. it.Item)
		end
	end
	return #parts > 0 and ("Recompensa: " .. table.concat(parts, ", ")) or ""
end

local function render()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, q in ipairs(log) do
		local card = Theme.new("Frame", {
			BackgroundColor3 = Theme.Colors.PanelLight,
			Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = i,
			Parent = list,
		}, { Theme.corner(10), Theme.padding(8), Theme.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
		local status = if q.Active then "  · em andamento" elseif q.Done and not q.CanAccept then "  · concluída" else ""
		Theme.label(q.Name .. status, 18, { Font = Theme.BoldFont, LayoutOrder = 1, TextColor3 = if q.Active then Theme.Colors.Accent else Theme.Colors.Text, Parent = card })
		Theme.label(q.Summary, 14, { TextColor3 = Theme.Colors.TextDim, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = card })
		for k, s in ipairs(q.Steps) do
			local mark = if q.Active and k < q.Step then "✓ " elseif q.Active and k == q.Step then "➤ " else "• "
			local text = s.Text
			if q.Active and k == q.Step and s.Kind == "Kill" then
				text ..= string.format(" (%d/%d)", q.Progress, s.Count or 1)
			end
			Theme.label(mark .. text, 14, { LayoutOrder = 2 + k, AutomaticSize = Enum.AutomaticSize.Y, TextColor3 = if q.Active and k == q.Step then Theme.Colors.Text else Theme.Colors.TextDim, Parent = card })
		end
		Theme.label(rewardText(q.Reward), 13, { LayoutOrder = 20, TextColor3 = Theme.Colors.Good, Parent = card })
		local row = Theme.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 21, Parent = card }, {
			Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
		})
		if q.Active then
			local step = q.Steps[q.Step]
			if step and (step.Kind == "Collect" or step.Kind == "Talk") then
				local b = Theme.button(if step.Kind == "Collect" then "Entregar" else "Falar", { Size = UDim2.fromOffset(130, 40), TextSize = 15, Parent = row })
				b.Activated:Connect(function()
					NetClient.Fire("QuestTurnIn", q.Id)
				end)
			elseif step and step.Kind == "Feed" then
				local b = Theme.button("Dar a poção ao dragão", { Size = UDim2.fromOffset(210, 40), TextSize = 15, Parent = row })
				b.Activated:Connect(function()
					NetClient.Fire("QuestFeed", q.Id)
				end)
			end
		elseif q.CanAccept then
			local b = Theme.button("Aceitar", { Size = UDim2.fromOffset(130, 40), TextSize = 15, Parent = row })
			b.Activated:Connect(function()
				NetClient.Fire("QuestAccept", q.Id)
			end)
		elseif q.Why then
			Theme.label(q.Why, 13, { TextColor3 = Theme.Colors.Warn, Size = UDim2.new(1, 0, 0, 40), TextYAlignment = Enum.TextYAlignment.Center, Parent = row })
		end
	end

	-- lista curta das ativas (canto esquerdo)
	for _, c in ipairs(tracker:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local n = 0
	for _, q in ipairs(log) do
		if q.Active then
			n += 1
			local step = q.Steps[q.Step]
			local text = step and step.Text or ""
			if step and step.Kind == "Kill" then
				text ..= string.format(" (%d/%d)", q.Progress, step.Count or 1)
			end
			Theme.label(q.Name, 14, { Font = Theme.BoldFont, TextColor3 = Theme.Colors.Accent, LayoutOrder = n * 2, TextStrokeTransparency = 0.5, Parent = tracker })
			Theme.label("➤ " .. text, 13, { AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = n * 2 + 1, TextStrokeTransparency = 0.5, Parent = tracker })
		end
	end
	tracker.Visible = n > 0
end

function QuestPanel.SetLog(newLog: { any })
	log = newLog
	render()
end

function QuestPanel.Open()
	panel.Visible = true
end

local TUTORIALS = {
	Flight = {
		Title = "Seu dragão pode voar!",
		Text = "Monte nele (V). Aperte Espaço para decolar e subir, Ctrl (ou o botão Descer) para descer. O dragão voa para onde a câmera aponta. Espaço perto do chão faz pousar. Dragões mais raros voam mais rápido.",
	},
	Burrow = {
		Title = "Seu Wyrm entra na terra!",
		Text = "Monte nele (V) e aperte Espaço para mergulhar no chão: ele anda por baixo da terra, mais rápido e sem poder ser atingido. Aperte Espaço de novo para sair — quem estiver por perto leva um golpe saindo do chão.",
	},
}

function QuestPanel.Tutorial(kind: string)
	local t = TUTORIALS[kind]
	if not t then
		return
	end
	tutorialTitle.Text = t.Title
	tutorialText.Text = t.Text
	tutorial.Visible = true
end

function QuestPanel.Init(screen: ScreenGui)
	panel = Theme.new("Frame", {
		Name = "QuestPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.new(0.55, 0, 0.72, 0),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.04,
		Visible = false,
		Parent = screen,
	}, { Theme.corner(14), Theme.stroke(), Theme.padding(12), Theme.new("UISizeConstraint", { MinSize = Vector2.new(330, 320), MaxSize = Vector2.new(620, 680) }) })
	Theme.label("Missões · Mestra Lira", 24, { Font = Theme.TitleFont, Size = UDim2.new(1, -50, 0, 32), Parent = panel })
	local close = Theme.button("X", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(44, 36), BackgroundColor3 = Theme.Colors.ButtonAlt, Parent = panel })
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	list = Theme.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = panel,
	}, { Theme.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

	tracker = Theme.new("Frame", {
		Name = "QuestTracker",
		Position = UDim2.new(0, 12, 0.32, 0),
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.45,
		Visible = false,
		Parent = screen,
	}, { Theme.corner(8), Theme.padding(8), Theme.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

	tutorial = Theme.new("Frame", {
		Name = "Tutorial",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(440, 230),
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		Parent = screen,
	}, { Theme.corner(14), Theme.stroke(Theme.Colors.Accent, 3), Theme.padding(14) })
	tutorialTitle = Theme.label("", 24, { Font = Theme.TitleFont, TextColor3 = Theme.Colors.Accent, Parent = tutorial })
	tutorialText = Theme.label("", 16, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -96), TextYAlignment = Enum.TextYAlignment.Top, Parent = tutorial })
	local ok = Theme.button("Entendi", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Parent = tutorial })
	ok.Activated:Connect(function()
		tutorial.Visible = false
	end)

	-- pede a lista quando o perfil chega ou as missões mudam (no máximo 1 pedido por segundo)
	local pending = false
	State.Changed:Connect(function(key: string)
		if (key == "*" or key == "Quests" or key == "ActiveDragonId" or key == "Dragons" or key == "QuestItems") and not pending then
			pending = true
			task.delay(1.1, function()
				pending = false
				NetClient.Fire("QuestLogRequest")
			end)
		end
	end)
end

return QuestPanel
