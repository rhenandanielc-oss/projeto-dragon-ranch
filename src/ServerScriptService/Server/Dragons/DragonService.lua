--!strict
-- Dragões na fazenda: ovo inicial, incubação, cuidados, treino, pontos de crescimento,
-- troca de estágio, nome personalizado, dragão ativo e espaços da fazenda.
-- Tudo decidido no servidor. Regras: GAME-DESIGN.md §4, §5, §6.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local Species = require(ReplicatedStorage.Shared.Config.Species)
local Growth = require(ReplicatedStorage.Shared.Config.Growth)
local Rarity = require(ReplicatedStorage.Shared.Config.Rarity)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local Server = ServerScriptService.Server
local DataService = require(Server.Data.DataService)
local NetService = require(Server.Services.NetService)
local FarmService = require(Server.Services.FarmService)
local InventoryService = require(Server.Services.InventoryService)
local DragonModels = require(Server.Dragons.DragonModels)
local CompanionService = require(Server.Dragons.CompanionService)
local RoamService = require(Server.Dragons.RoamService)

local DragonService = {}

local TICK_SECONDS = 10
local INCUBATION_PER_MINUTE = 10 -- ovo no ninho, com o dono no jogo (Ovo -> Bebê em ~30 min)
local INTERACT_DISTANCE = 22
local PET_COOLDOWN = 60
local FEED_AMOUNT = 35
local POINTS_ONLY_IF_BELOW = 90 -- alimentar um dragão já satisfeito não dá pontos
local STARTER_ITEMS = { { "Meat", 10 }, { "WaterFlask", 10 } }

-- Acelerador de testes: SÓ funciona dentro do Studio, pelo atributo TestPointsMultiplier
-- em ServerScriptService. No jogo publicado é sempre 1 (o cliente não consegue alterar).
local RunService = game:GetService("RunService")
local function testMultiplier(): number
	if not RunService:IsStudio() then
		return 1
	end
	local v = ServerScriptService:GetAttribute("TestPointsMultiplier")
	return (type(v) == "number" and v > 0) and v or 1
end

local models: { [Player]: { [string]: Model } } = {}
local petCooldown: { [string]: number } = {}
local companionHome: { [Player]: boolean } = {} -- true = o jogador guardou o dragão ativo na fazenda
local restUntil: { [Player]: number } = {} -- dragão derrotado descansa na fazenda até esse momento

--------------------------------------------------------------------------
-- Utilidades
--------------------------------------------------------------------------
local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

local function dayNumber(): number
	return math.floor(os.time() / 86400)
end

local function displayName(dragon: { [string]: any }): string
	if dragon.CustomName and dragon.CustomName ~= "" then
		return dragon.CustomName
	end
	return Species[dragon.Species].DisplayName
end

local function countDragons(data: { [string]: any }): number
	local n = 0
	for _ in pairs(data.Dragons) do
		n += 1
	end
	return n
end

local function sortedIds(data: { [string]: any }): { string }
	local ids = {}
	for id in pairs(data.Dragons) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return (data.Dragons[a].CreatedAt or 0) < (data.Dragons[b].CreatedAt or 0)
	end)
	return ids
end

-- O dragão ativo, já nascido, acompanha o dono (a menos que ele o tenha guardado na fazenda).
local function isCompanion(player: Player, data: { [string]: any }, dragonId: string): boolean
	local dragon = data.Dragons[dragonId]
	return dragon ~= nil and dragon.Stage ~= "Egg" and data.ActiveDragonId == dragonId and not companionHome[player]
end

local function characterNear(player: Player, model: Model?): boolean
	if not model or not model.PrimaryPart then
		return false
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	return (hrp.Position - model.PrimaryPart.Position).Magnitude <= INTERACT_DISTANCE + model:GetExtentsSize().Magnitude / 2
end

--------------------------------------------------------------------------
-- Modelos na fazenda
--------------------------------------------------------------------------
local function placementFor(plot: Model, data: { [string]: any }, dragonId: string): CFrame?
	local base = plot:FindFirstChild("Base")
	if not base then
		return nil
	end
	local dragon = data.Dragons[dragonId]
	if dragon.Stage == "Egg" then
		-- ovos ficam no ninho, lado a lado
		local eggIndex = 0
		for _, id in ipairs(sortedIds(data)) do
			if data.Dragons[id].Stage == "Egg" then
				eggIndex += 1
				if id == dragonId then
					break
				end
			end
		end
		local spot = base:FindFirstChild("EggSpot") :: Attachment
		local offsets = { Vector3.new(0, 0, 0), Vector3.new(2.6, 0, 0), Vector3.new(-2.6, 0, 0), Vector3.new(0, 0, 2.6), Vector3.new(0, 0, -2.6) }
		local off = offsets[((eggIndex - 1) % #offsets) + 1]
		return spot.WorldCFrame * CFrame.new(off - Vector3.new(0, 2.2, 0))
	end
	local penIndex = 0
	for _, id in ipairs(sortedIds(data)) do
		if data.Dragons[id].Stage ~= "Egg" then
			penIndex += 1
			if id == dragonId then
				break
			end
		end
	end
	local pen = base:FindFirstChild("Pen" .. math.clamp(penIndex, 1, 8)) :: Attachment
	-- o attachment já aponta para a entrada da fazenda
	return pen.WorldCFrame
end

local function addPrompt(model: Model, owner: Player, name: string, action: string, key: Enum.KeyCode, order: number)
	local root = model.PrimaryPart :: BasePart
	local att = root:FindFirstChild("PromptAttachment") :: Attachment?
	if not att then
		local a = Instance.new("Attachment")
		a.Name = "PromptAttachment"
		a.Position = Vector3.new(0, math.min(model:GetExtentsSize().Y * 0.5, 6), 0)
		a.Parent = root
		att = a
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = key
	prompt.UIOffset = Vector2.new(0, -order * 72)
	prompt.MaxActivationDistance = 14 + model:GetExtentsSize().Magnitude * 0.3
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt:SetAttribute("OwnerUserId", owner.UserId)
	prompt.Parent = att
end

local onPrompt: (player: Player, owner: Player, dragonId: string, action: string) -> ()

local function buildModel(player: Player, dragonId: string)
	local data = DataService.Get(player)
	local plot = FarmService.GetPlot(player)
	if not data or not plot then
		return
	end
	local dragon = data.Dragons[dragonId]
	if not dragon then
		return
	end
	local list = models[player]
	if not list then
		list = {}
		models[player] = list
	end
	if list[dragonId] then
		list[dragonId]:Destroy()
		list[dragonId] = nil
	end
	local at = placementFor(plot, data, dragonId)
	if not at then
		return
	end
	local model = DragonModels.Build(dragon, at)
	local companion = isCompanion(player, data, dragonId)
	-- solto para passear: não é o ativo, já nasceu e o dono marcou "Soltar"
	local roaming = not companion and dragon.Roaming == true and dragon.Stage ~= "Egg"
	if not companion and not roaming then
		local container = plot:FindFirstChild("Dragons")
		if not container then
			container = Instance.new("Folder")
			container.Name = "Dragons"
			container.Parent = plot
		end
		model.Parent = container
	end
	list[dragonId] = model

	if dragon.Stage ~= "Egg" then
		local isBaby = dragon.Stage == "Baby"
		addPrompt(model, player, "Feed", "Alimentar", Enum.KeyCode.E, 0)
		addPrompt(model, player, "Drink", "Dar água", Enum.KeyCode.R, 1)
		addPrompt(model, player, "Pet", "Carinho", Enum.KeyCode.H, 2)
		addPrompt(model, player, "Train", isBaby and "Brincar" or "Treinar", Enum.KeyCode.Y, 3)
		for _, prompt in ipairs(model:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") then
				prompt.ObjectText = displayName(dragon)
				prompt.Triggered:Connect(function(who: Player)
					onPrompt(who, player, dragonId, prompt.Name)
				end)
			end
		end
	end
	if companion then
		CompanionService.Attach(player, model, dragon)
		player:SetAttribute("CompanionOut", true)
	elseif roaming then
		local base = plot:FindFirstChild("Base") :: BasePart?
		RoamService.Attach(player, model, base and base.Position or nil)
	end
end

-- Soltar / recolher um dragão para passear pelo mundo (não luta e não pode ser atacado).
local function onSetRoaming(player: Player, dragonId: string, on: boolean)
	local data = DataService.Get(player)
	local dragon = data and data.Dragons[dragonId]
	if not data or not dragon then
		return
	end
	if on then
		if dragon.Stage == "Egg" then
			notify(player, "Ovos ficam no ninho.")
			return
		end
		if data.ActiveDragonId == dragonId then
			notify(player, "Esse é o seu dragão ativo: ele já anda com você.")
			return
		end
		local n = 0
		for _, d in pairs(data.Dragons) do
			if d.Roaming then
				n += 1
			end
		end
		if n >= Rules.Roam.MaxPerPlayer then
			notify(player, string.format("No máximo %d dragões soltos ao mesmo tempo.", Rules.Roam.MaxPerPlayer), "warning")
			return
		end
	end
	if (dragon.Roaming == true) == on then
		return
	end
	dragon.Roaming = on
	DataService.MarkChanged(player, "Dragons")
	buildModel(player, dragonId)
	notify(player, if on then displayName(dragon) .. " foi solto para passear. Ele fica por perto de você e não luta." else displayName(dragon) .. " voltou para o cercado.")
end

local function rebuildAll(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	-- remove modelos de dragões que não existem mais
	local list = models[player] or {}
	for id, model in pairs(list) do
		if not data.Dragons[id] then
			model:Destroy()
			list[id] = nil
		end
	end
	for _, id in ipairs(sortedIds(data)) do
		buildModel(player, id)
	end
end

local function clearModels(player: Player)
	CompanionService.Detach(player)
	player:SetAttribute("CompanionOut", false)
	local list = models[player]
	if list then
		for _, model in pairs(list) do
			model:Destroy()
		end
	end
	models[player] = nil
end

--------------------------------------------------------------------------
-- Pontos e estágios
--------------------------------------------------------------------------
local function isHungry(dragon: { [string]: any }): boolean
	return dragon.Hunger < Growth.Needs.HungryThreshold or dragon.Thirst < Growth.Needs.HungryThreshold
end

-- Única função que concede pontos de crescimento.
function DragonService.AddPoints(player: Player, dragonId: string, amount: number, reason: string): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local dragon = data.Dragons[dragonId]
	if not dragon or amount <= 0 then
		return 0
	end
	local mult = testMultiplier()
	if dragon.Stage ~= "Egg" and isHungry(dragon) then
		mult *= Growth.Needs.HungryPointsMultiplier
	end
	local gained = amount * mult
	dragon.GrowthPoints = math.min(dragon.GrowthPoints + gained, Growth.Thresholds.Elder + 1e6)

	local newStage = Growth.StageForPoints(dragon.GrowthPoints)
	if Growth.StageIndex(newStage) > Growth.StageIndex(dragon.Stage) then
		local oldStage = dragon.Stage
		dragon.Stage = newStage
		if oldStage == "Egg" then
			notify(player, "Seu ovo chocou! Nasceu um " .. Species[dragon.Species].DisplayName .. ".", "success")
		else
			notify(player, displayName(dragon) .. " cresceu! Agora é " .. Growth.StageNames[newStage] .. ".", "success")
		end
		-- Proteção de iniciante termina quando o primeiro dragão vira Jovem.
		if data.Protection.NewPlayer and Growth.StageIndex(newStage) >= Growth.StageIndex(Rules.PvP.NewPlayerProtectionUntilStage) then
			data.Protection.NewPlayer = false
			notify(player, "Seu dragão virou Jovem: sua proteção de iniciante contra PvP terminou.", "warning")
			DataService.MarkChanged(player, "Protection")
		end
		task.defer(rebuildAll, player)
	end
	return gained
end

-- Pontos de cuidado respeitam o limite diário por dragão.
local function addCarePoints(player: Player, dragonId: string, amount: number): number
	local data = DataService.Get(player) :: { [string]: any }
	local dragon = data.Dragons[dragonId]
	local today = dayNumber()
	if dragon.CareDay ~= today then
		dragon.CareDay = today
		dragon.CareToday = 0
	end
	local room = Growth.Sources.CareDailyCap - dragon.CareToday
	if room <= 0 then
		return 0
	end
	local base = math.min(amount, room)
	if data.ActiveDragonId ~= dragonId then
		base *= Growth.Sources.FarmIdleMultiplier
	end
	dragon.CareToday += math.min(amount, room)
	return DragonService.AddPoints(player, dragonId, base, "care")
end

--------------------------------------------------------------------------
-- Interações (ProximityPrompt no servidor)
--------------------------------------------------------------------------
onPrompt = function(player: Player, owner: Player, dragonId: string, action: string)
	if player ~= owner then
		return -- só o dono cuida dos próprios dragões
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local dragon = data.Dragons[dragonId]
	local model = models[player] and models[player][dragonId]
	if not dragon or dragon.Stage == "Egg" or not characterNear(player, model) then
		return
	end
	local name = displayName(dragon)

	if action == "Feed" or action == "Drink" then
		local item = action == "Feed" and "Meat" or "WaterFlask"
		local field = action == "Feed" and "Hunger" or "Thirst"
		if dragon[field] >= Growth.Needs.Max - 0.5 then
			notify(player, name .. (action == "Feed" and " não está com fome." or " não está com sede."))
			return
		end
		if not InventoryService.Remove(player, item, 1) then
			notify(player, action == "Feed" and "Você não tem carne." or "Você não tem água.", "warning")
			return
		end
		local before = dragon[field]
		dragon[field] = math.min(Growth.Needs.Max, dragon[field] + FEED_AMOUNT)
		local pts = 0
		if before < POINTS_ONLY_IF_BELOW then
			pts = addCarePoints(player, dragonId, action == "Feed" and Growth.Sources.Feed or Growth.Sources.Drink)
		end
		notify(player, string.format("%s %s (+%d pontos)", name, action == "Feed" and "comeu" or "bebeu", math.floor(pts)))
	elseif action == "Pet" then
		local key = tostring(player.UserId) .. ":" .. dragonId
		if os.clock() - (petCooldown[key] or -math.huge) < PET_COOLDOWN then
			notify(player, name .. " já recebeu carinho agora há pouco.")
			return
		end
		petCooldown[key] = os.clock()
		local pts = addCarePoints(player, dragonId, Growth.Sources.Pet)
		notify(player, string.format("%s gostou do carinho! (+%d pontos)", name, math.floor(pts)))
	elseif action == "Train" then
		local now = os.time()
		local readyAt = (dragon.LastTrainAt or 0) + Growth.Sources.TrainingCooldownSeconds
		if now < readyAt then
			notify(player, string.format("%s está descansando. Pode treinar de novo em %d s.", name, readyAt - now))
			return
		end
		dragon.LastTrainAt = now
		local verb = dragon.Stage == "Baby" and "brincou" or "treinou"
		local amount = Growth.Sources.TrainingPerSession
		if data.ActiveDragonId ~= dragonId then
			amount *= Growth.Sources.FarmIdleMultiplier
		end
		local pts = DragonService.AddPoints(player, dragonId, amount, "training")
		notify(player, string.format("%s %s! (+%d pontos)", name, verb, math.floor(pts)))
	end
	DataService.MarkChanged(player, "Dragons")
end

--------------------------------------------------------------------------
-- Pedidos do cliente
--------------------------------------------------------------------------
function DragonService.CreateDragon(player: Player, speciesId: string, rarityId: string): string?
	local data = DataService.Get(player)
	if not data or not Species[speciesId] or not Rarity.Defs[rarityId] then
		return nil
	end
	if countDragons(data) >= data.DragonSlots then
		notify(player, "Sua fazenda não tem espaço para mais dragões.", "warning")
		return nil
	end
	local id = DataService.NewUid(player, "D")
	if not id then
		return nil
	end
	data.Dragons[id] = {
		Id = id,
		Species = speciesId,
		Rarity = rarityId,
		CustomName = "",
		GrowthPoints = 0,
		Stage = "Egg",
		Hunger = Growth.Needs.Max,
		Thirst = Growth.Needs.Max,
		FlightUnlocked = false,
		BurrowUnlocked = false,
		CareToday = 0,
		CareDay = dayNumber(),
		LastTrainAt = 0,
		CreatedAt = os.time() + countDragons(data) * 0.001,
	}
	DataService.MarkChanged(player, "Dragons")
	buildModel(player, id)
	return id
end

local function onChooseStarter(player: Player, speciesId: string)
	local data = DataService.Get(player)
	if not data or data.StarterChosen then
		return
	end
	local id = DragonService.CreateDragon(player, speciesId, Rarity.StarterRarity)
	if not id then
		return
	end
	data.StarterChosen = true
	data.ActiveDragonId = id
	for _, pair in ipairs(STARTER_ITEMS) do
		InventoryService.Add(player, pair[1], pair[2])
	end
	DataService.MarkChanged(player, "StarterChosen")
	DataService.MarkChanged(player, "ActiveDragonId")
	notify(player, "Seu ovo de " .. Species[speciesId].DisplayName .. " está no ninho. Fique por perto para chocá-lo!", "success")
end

local function onRename(player: Player, dragonId: string, rawName: string)
	local data = DataService.Get(player)
	if not data or not data.Dragons[dragonId] then
		return
	end
	local name = rawName:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
	local len = utf8.len(name) or 0
	if len < 1 or len > 20 then
		notify(player, "O nome deve ter de 1 a 20 caracteres.", "warning")
		return
	end
	-- Filtro de texto obrigatório do Roblox para textos que outros jogadores veem.
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(name, player.UserId, Enum.TextFilterContext.PublicChat)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if not ok or type(filtered) ~= "string" then
		notify(player, "Não foi possível verificar o nome agora. Tente de novo.", "warning")
		return
	end
	if data.Dragons[dragonId] == nil then
		return
	end
	data.Dragons[dragonId].CustomName = filtered
	DataService.MarkChanged(player, "Dragons")
	buildModel(player, dragonId)
	notify(player, "Nome alterado para " .. filtered .. ".", "success")
end

local function onSetActive(player: Player, dragonId: string)
	local data = DataService.Get(player)
	if not data or not data.Dragons[dragonId] or data.ActiveDragonId == dragonId then
		return
	end
	local old = data.ActiveDragonId
	data.ActiveDragonId = dragonId
	DataService.MarkChanged(player, "ActiveDragonId")
	notify(player, displayName(data.Dragons[dragonId]) .. " agora é seu dragão ativo.")
	-- o antigo volta para o cercado; o novo vem acompanhar o dono
	CompanionService.Detach(player)
	player:SetAttribute("CompanionOut", false)
	if old and data.Dragons[old] then
		buildModel(player, old)
	end
	buildModel(player, dragonId)
end

local function onToggleCompanion(player: Player)
	local data = DataService.Get(player)
	if not data or not FarmService.GetPlot(player) then
		return
	end
	local id = data.ActiveDragonId
	local dragon = id and data.Dragons[id]
	if not dragon or dragon.Stage == "Egg" then
		notify(player, "Seu dragão ativo ainda é um ovo.")
		return
	end
	local rest = (restUntil[player] or 0) - os.clock()
	if companionHome[player] and rest > 0 then
		notify(player, string.format("%s ainda está descansando (%d s).", displayName(dragon), math.ceil(rest)))
		return
	end
	companionHome[player] = not companionHome[player]
	CompanionService.Detach(player)
	player:SetAttribute("CompanionOut", false)
	buildModel(player, id)
	notify(player, companionHome[player] and (displayName(dragon) .. " voltou para a fazenda.") or (displayName(dragon) .. " está com você."))
end

DragonService.ToggleCompanion = onToggleCompanion

-- Reconstrói o modelo de um dragão (ex.: depois de liberar voo).
function DragonService.Refresh(player: Player, dragonId: string)
	if dragonId == (DataService.Get(player) or {}).ActiveDragonId then
		CompanionService.Detach(player)
	end
	buildModel(player, dragonId)
end

function DragonService.IsCompanionHome(player: Player): boolean
	return companionHome[player] == true
end

-- Dragão derrotado em combate: volta para a fazenda e descansa (GAME-DESIGN §10.5).
function DragonService.Rest(player: Player, seconds: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	restUntil[player] = os.clock() + seconds
	player:SetAttribute("DragonRestUntil", workspace:GetServerTimeNow() + seconds)
	companionHome[player] = true
	CompanionService.Detach(player)
	player:SetAttribute("CompanionOut", false)
	local id = data.ActiveDragonId
	if id and data.Dragons[id] then
		buildModel(player, id)
		notify(player, string.format("%s foi derrotado e voltou para a fazenda para descansar. Chame-o de novo em %d s (G).", displayName(data.Dragons[id]), seconds), "warning")
	end
end

local function onExpandSlots(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if data.DragonSlots >= Rules.Farm.MaxDragonSlots then
		notify(player, "Sua fazenda já está no tamanho máximo.")
		return
	end
	local cost = Rules.Farm.SlotExpansionCost[data.DragonSlots - Rules.Farm.StartDragonSlots + 1]
	if not cost or data.Coins < cost then
		notify(player, string.format("Você precisa de %d %s.", cost or 0, Rules.Economy.CurrencyName), "warning")
		return
	end
	data.Coins -= cost
	data.DragonSlots += 1
	DataService.MarkChanged(player, "Coins")
	DataService.MarkChanged(player, "DragonSlots")
	notify(player, string.format("Fazenda ampliada: agora cabem %d dragões.", data.DragonSlots), "success")
end

--------------------------------------------------------------------------
-- Ciclo periódico: incubação e necessidades (só com o dono no jogo; nada acontece offline)
--------------------------------------------------------------------------
local function tickPlayer(player: Player, dt: number)
	local data = DataService.Get(player)
	if not data or not FarmService.GetPlot(player) then
		return
	end
	local minutes = dt / 60
	local changed = false
	for id, dragon in pairs(data.Dragons) do
		if dragon.Stage == "Egg" then
			DragonService.AddPoints(player, id, INCUBATION_PER_MINUTE * minutes, "incubation")
			changed = true
		else
			local decay = (data.ActiveDragonId == id and Growth.Needs.DecayPerMinuteActive or Growth.Needs.DecayPerMinuteFarm) * minutes
			dragon.Hunger = math.max(0, dragon.Hunger - decay)
			dragon.Thirst = math.max(0, dragon.Thirst - decay)
			changed = true
		end
	end
	if changed then
		DataService.MarkChanged(player, "Dragons")
	end
end

-- SÓ NO STUDIO: dragão Adulto que já voa, para testar o voo sem fazer a missão.
-- Uso: no modo Play, digite /testevoo no chat (ou /testeterra para um Wyrm que entra na terra).
function DragonService.TestFlight(player: Player, species: string?)
	if not RunService:IsStudio() then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	species = species or "Wyvern"
	local id = DragonService.CreateDragon(player, species :: string, "Rare")
	if not id then
		-- fazenda cheia: usa o dragão ativo (ou o primeiro)
		id = data.ActiveDragonId or next(data.Dragons)
	end
	if not id then
		return
	end
	local d = data.Dragons[id]
	d.GrowthPoints = Growth.Thresholds.Adult
	d.Stage = "Adult"
	d.Hunger, d.Thirst = Growth.Needs.Max, Growth.Needs.Max
	if Species[d.Species].CanFly then
		d.FlightUnlocked = true
	end
	if d.Species == "Wyrm" then
		d.BurrowUnlocked = true
	end
	data.StarterChosen = true
	data.ActiveDragonId = id
	companionHome[player] = false
	DataService.MarkChanged(player, "Dragons")
	DataService.MarkChanged(player, "ActiveDragonId")
	DataService.MarkChanged(player, "StarterChosen")
	CompanionService.Detach(player)
	buildModel(player, id)
	notify(player, "[TESTE] " .. displayName(d) .. " Adulto está ao seu lado. Chegue perto e segure V para montar; Espaço decola.", "success")
end

function DragonService.Init()
	if RunService:IsStudio() then
		local function hook(p: Player)
			p.Chatted:Connect(function(msg: string)
				local m = string.lower(msg)
				if m == "/testevoo" then
					DragonService.TestFlight(p, "Wyvern")
				elseif m == "/testeterra" then
					DragonService.TestFlight(p, "Wyrm")
				end
			end)
		end
		for _, p in ipairs(Players:GetPlayers()) do
			hook(p)
		end
		Players.PlayerAdded:Connect(hook)
	end
	NetService.On("ChooseStarter", onChooseStarter)
	NetService.On("RenameDragon", onRename)
	NetService.On("SetActiveDragon", onSetActive)
	NetService.On("ExpandDragonSlots", onExpandSlots)
	NetService.On("ToggleCompanion", onToggleCompanion)
	NetService.On("SetRoaming", onSetRoaming)
	RoamService.Init()
	NetService.On("MountDragon", function(player: Player)
		CompanionService.Mount(player)
	end)
	NetService.On("DismountDragon", function(player: Player)
		CompanionService.Dismount(player)
	end)
	NetService.On("MountMode", function(player: Player, mode: string)
		CompanionService.SetMode(player, mode)
	end)
	CompanionService.Init(notify)

	FarmService.PlotAssigned:Connect(function(player: Player)
		rebuildAll(player)
	end)
	FarmService.PlotReleasing:Connect(function(player: Player)
		clearModels(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		clearModels(player)
		companionHome[player] = nil
		restUntil[player] = nil
	end)

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(TICK_SECONDS)
			local now = os.clock()
			local dt = now - last
			last = now
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(tickPlayer, player, dt)
				if not ok then
					warn("[Dragon] Erro no ciclo de " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end)
end

return DragonService
