--!strict
-- Interface do combate: vida do jogador, arma e flechas, recargas (habilidade, esquiva),
-- vida e poderes do dragão (Z/X/C), mira e carga do arco.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local CombatHud = {}

local setHealth: (number, string?) -> ()
local setDragon: (number, string?) -> ()
local dragonFrame: Frame
local weaponLabel: TextLabel
local crosshair: Frame
local chargeBar: Frame
local setCharge: (number, string?) -> ()
local skillSlots: { [string]: { frame: Frame, shade: Frame, label: TextLabel, readyAt: number, total: number } } = {}
local chargingFn: () -> number? = function()
	return nil
end

local function arrows(): number
	local data = State.Data
	local n = 0
	if data then
		for _, s in ipairs(data.Backpack.Slots) do
			if s.Item == "Arrow" then
				n += s.Count
			end
		end
	end
	return n
end

local function slot(parent: Instance, key: string, title: string, order: number)
	local f = Theme.new("Frame", {
		Name = key,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.15,
		Size = UDim2.fromOffset(64, 50),
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.corner(8), Theme.stroke(Color3.fromRGB(90, 80, 100), 1) })
	Theme.label(key, 15, { Font = Theme.BoldFont, TextColor3 = Theme.Colors.Accent, Position = UDim2.fromOffset(4, 0), Size = UDim2.fromOffset(30, 18), Parent = f })
	local label = Theme.label(title, 11, { Position = UDim2.fromOffset(3, 18), Size = UDim2.new(1, -6, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Parent = f })
	local shade = Theme.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), ZIndex = 4, Parent = f }, { Theme.corner(8) })
	skillSlots[key] = { frame = f, shade = shade, label = label, readyAt = 0, total = 1 }
end

-- linha pequena do painel lateral do dragão montado: "[Z] Bola de Fogo"
local function rowSlot(parent: Instance, key: string, title: string, order: number): TextLabel
	local f = Theme.new("Frame", {
		Name = key,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.35,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.corner(5) })
	Theme.label(key, 12, { Font = Theme.BoldFont, TextColor3 = Theme.Colors.Accent, Position = UDim2.fromOffset(5, 0), Size = UDim2.fromOffset(46, 20), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = false, Parent = f })
	local label = Theme.label(title, 12, { Position = UDim2.fromOffset(52, 0), Size = UDim2.new(1, -56, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
	local shade = Theme.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = f }, { Theme.corner(5) })
	skillSlots[key] = { frame = f, shade = shade, label = label, readyAt = 0, total = 1, horizontal = true } :: any
	return label
end

function CombatHud.SkillUsed(name: string, cooldown: number)
	local key = ({ Spin = "T", Triple = "T", Dodge = "Q", DragonZ = "Z", DragonX = "X", DragonC = "C" } :: any)[name]
	local s = key and skillSlots[key]
	if s then
		s.readyAt = os.clock() + cooldown
		s.total = math.max(cooldown, 0.1)
	end
end

function CombatHud.SetDragonPowers(unlocked: { [string]: any }, canFight: boolean)
	for _, k in ipairs({ "Z", "X", "C" }) do
		local s = skillSlots[k]
		local p = unlocked[k]
		s.frame.Visible = canFight and p ~= nil
		s.label.Text = if p then p.Name else "Bloqueado"
		s.label.TextColor3 = if p then Theme.Colors.Text else Theme.Colors.TextDim
	end
end

local function companion(): Model?
	local f = workspace:FindFirstChild("Companions")
	if not f then
		return nil
	end
	for _, m in ipairs(f:GetChildren()) do
		if m:GetAttribute("OwnerUserId") == player.UserId then
			return m :: Model
		end
	end
	return nil
end

function CombatHud.Init(screen: ScreenGui, chargeGetter: () -> number?, aimingGetter: (() -> boolean)?)
	chargingFn = chargeGetter
	local isAiming = aimingGetter or function()
		return false
	end
	local root = Theme.new("Frame", {
		Name = "CombatHud",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -74),
		Size = UDim2.fromOffset(420, 70),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	local hp, setHp = Theme.bar(Color3.fromRGB(210, 70, 70), 18)
	hp.Size = UDim2.new(0.62, 0, 0, 18)
	hp.Position = UDim2.fromOffset(0, 48)
	hp.Parent = root
	setHealth = setHp
	weaponLabel = Theme.label("", 14, { Font = Theme.BoldFont, Position = UDim2.new(0.64, 0, 0, 46), Size = UDim2.new(0.36, 0, 0, 22), TextStrokeTransparency = 0.5, TextWrapped = false, Parent = root })

	local row = Theme.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, -8), Parent = root }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom }),
	})
	slot(row, "T", "Habilidade", 1)
	slot(row, "Q", "Esquiva", 2)

	-- painel lateral pequeno: aparece só montado no dragão, com cada tecla e o que ela faz
	local side = Theme.new("Frame", {
		Name = "MountControls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(190, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screen,
	}, { Theme.new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }) })
	Theme.label("Montado", 12, { Font = Theme.BoldFont, TextColor3 = Theme.Colors.Accent, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, TextStrokeTransparency = 0.5, Parent = side })
	local lines: { [string]: TextLabel } = {}
	local order = 1
	local function line(key: string, title: string)
		lines[key] = rowSlot(side, key, title, order)
		order += 1
	end
	line("W A S D", "Andar / voar")
	line("Espaço", "Voar")
	line("Ctrl", "Descer / pousar")
	line("Clique", "Morder")
	line("Z", "")
	line("X", "")
	line("C", "")
	line("V", "Descer do dragão")
	CombatHud.SetDragonPowers({}, false)

	-- vida do dragão (acima da linha de recargas)
	dragonFrame = Theme.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, -34), Size = UDim2.new(0.62, 0, 0, 22), Visible = false, Parent = root })
	local db, setD = Theme.bar(Color3.fromRGB(90, 200, 110), 14)
	db.Size = UDim2.new(1, 0, 0, 14)
	db.Parent = dragonFrame
	setDragon = setD

	-- mira do arco
	crosshair = Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, Parent = screen }, { Theme.corner(3), Theme.stroke(Color3.new(0, 0, 0), 1) })
	local cb, setC = Theme.bar(Theme.Colors.Accent, 10)
	cb.AnchorPoint = Vector2.new(0.5, 0)
	cb.Position = UDim2.new(0.5, 0, 0.5, 26)
	cb.Size = UDim2.fromOffset(120, 10)
	cb.Visible = false
	cb.Parent = screen
	chargeBar = cb
	setCharge = setC

	RunService.RenderStepped:Connect(function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			setHealth(hum.Health / math.max(hum.MaxHealth, 1), string.format("Vida %d / %d", math.floor(hum.Health + 0.5), hum.MaxHealth))
		end
		local w = char and char:GetAttribute("Weapon") or "Sword"
		if w == "Bow" then
			weaponLabel.Text = string.format("Arco · %d flechas", arrows())
			skillSlots.T.label.Text = "Flecha Tripla"
		else
			weaponLabel.Text = "Espada"
			skillSlots.T.label.Text = "Golpe Giratório"
		end
		local c = chargingFn()
		crosshair.Visible = w == "Bow"
		-- mirando (ou no celular): mira no centro da tela; senão acompanha o cursor
		local UIS = game:GetService("UserInputService")
		if isAiming() or c ~= nil and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter or (UIS.TouchEnabled and not UIS.MouseEnabled) then
			crosshair.Position = UDim2.fromScale(0.5, 0.5)
		else
			local m = UIS:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
			crosshair.Position = UDim2.fromOffset(m.X, m.Y)
		end
		crosshair.Size = if isAiming() then UDim2.fromOffset(8, 8) else UDim2.fromOffset(6, 6)
		chargeBar.Position = UDim2.new(crosshair.Position.X.Scale, crosshair.Position.X.Offset, crosshair.Position.Y.Scale, crosshair.Position.Y.Offset + 26)
		chargeBar.Visible = c ~= nil
		if c then
			setCharge(c)
		end
		local now = os.clock()
		for _, s in pairs(skillSlots) do
			local left = s.readyAt - now
			local frac = if left > 0 then math.clamp(left / s.total, 0, 1) else 0
			s.shade.Size = if (s :: any).horizontal then UDim2.fromScale(frac, 1) else UDim2.fromScale(1, frac)
		end
		local comp = companion()
		local mounted = comp ~= nil and comp:GetAttribute("Mounted") == true
		side.Visible = mounted
		row.Visible = not mounted
		weaponLabel.Visible = not mounted
		if mounted and comp then
			local mode = comp:GetAttribute("Mode")
			local canFly = comp:GetAttribute("CanFly") == true
			local canBurrow = comp:GetAttribute("CanBurrow") == true
			local space = lines["Espaço"]
			local ctrl = lines["Ctrl"]
			if mode == "Fly" then
				space.Text = "Subir"
				ctrl.Text = "Descer / pousar"
				lines["W A S D"].Text = "Voar (segue a câmera)"
			elseif mode == "Burrow" then
				space.Text = "Sair da terra (ataque)"
				ctrl.Text = "—"
				lines["W A S D"].Text = "Andar por baixo da terra"
			else
				space.Text = if canFly then "Decolar" elseif canBurrow then "Entrar na terra" else "Pular"
				ctrl.Text = "—"
				lines["W A S D"].Text = "Andar"
			end
			ctrl.Parent.Visible = mode == "Fly"
		end
		local h = comp and comp:GetAttribute("Health")
		local mh = comp and comp:GetAttribute("MaxHealth")
		if type(h) == "number" and type(mh) == "number" and mh > 1 then
			dragonFrame.Visible = true
			setDragon(h / mh, string.format("Dragão %d / %d", h, mh))
		else
			dragonFrame.Visible = false
		end
	end)
end

return CombatHud
