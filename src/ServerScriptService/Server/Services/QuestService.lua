--!strict
-- Missões (Fase 6) e desbloqueio do voo / entrar na terra (Fase 8, GAME-DESIGN §7).
-- A Mestra Lira (Hub) mostra o quadro de missões. Todo progresso e recompensa é do servidor.
-- Perfil: data.Quests.Active[id] = { Step, Progress, DragonId? }, data.Quests.Completed[id] = vezes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Species = require(ReplicatedStorage.Shared.Config.Species)
local Growth = require(ReplicatedStorage.Shared.Config.Growth)
local Items = require(ReplicatedStorage.Shared.Config.Items)

local Server = ServerScriptService.Server
local DataService = require(Server.Data.DataService)
local NetService = require(Server.Services.NetService)
local InventoryService = require(Server.Services.InventoryService)
local DragonService = require(Server.Dragons.DragonService)
local CompanionService = require(Server.Dragons.CompanionService)
local EnemyService = require(Server.Combat.EnemyService)

local QuestService = {}

local TALK_DISTANCE = 16

local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

local function hrpOf(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function npcRoot(id: string): BasePart?
	local hub = workspace:FindFirstChild("Hub")
	local npcs = hub and hub:FindFirstChild("NPCs")
	local npc = npcs and npcs:FindFirstChild("NPC_" .. id)
	return npc and npc:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nearGiver(player: Player, giver: string): boolean
	local root = npcRoot(giver)
	local hrp = hrpOf(player)
	return root ~= nil and hrp ~= nil and (hrp.Position - root.Position).Magnitude <= TALK_DISTANCE
end

local function placePosition(place: string): Vector3?
	if place == "DungeonGate" then
		local world = workspace:FindFirstChild("World")
		local lm = world and world:FindFirstChild("Landmarks")
		local gate = lm and lm:FindFirstChild("DungeonGate")
		local portal = gate and gate:FindFirstChild("Portal")
		return if portal and portal:IsA("BasePart") then portal.Position else nil
	end
	return nil
end

local function activeDragon(data: { [string]: any }): ({ [string]: any }?, string?)
	local id = data.ActiveDragonId
	local d = id and data.Dragons[id]
	return d, id
end

-- A missão pode ser aceita agora? (requisitos de dragão, já feita, por dragão)
local function canAccept(data: { [string]: any }, q: Quests.QuestDef): (boolean, string?)
	if data.Quests.Active[q.Id] then
		return false, "Em andamento"
	end
	local done = data.Quests.Completed[q.Id]
	if done and not q.Repeatable and not q.PerDragon then
		return false, "Concluída"
	end
	local req = q.Requires
	if req or q.PerDragon then
		local d = activeDragon(data)
		if not d then
			return false, "Precisa de um dragão ativo"
		end
		if req and req.ActiveStage and Growth.StageIndex(d.Stage) < Growth.StageIndex(req.ActiveStage) then
			return false, "Seu dragão ativo precisa ser " .. Growth.StageNames[req.ActiveStage]
		end
		if req and req.CanFly and not Species[d.Species].CanFly then
			return false, "Seu dragão ativo não voa"
		end
		if req and req.Species and d.Species ~= req.Species then
			return false, "Só para " .. Species[req.Species].DisplayName
		end
		if q.PerDragon == "Flight" and d.FlightUnlocked then
			return false, "Seu dragão ativo já voa"
		end
		if q.PerDragon == "Burrow" and d.BurrowUnlocked then
			return false, "Seu Wyrm já entra na terra"
		end
	end
	return true
end

-- Etapa automática concluída? (Waypoints, Reach, QuestItem são verificados sozinhos)
local function autoStepDone(player: Player, data: { [string]: any }, step: Quests.Step, st: { [string]: any }): boolean
	if step.Kind == "Waypoints" then
		local n = 0
		for _, v in pairs(data.Travel and data.Travel.Waypoints or {}) do
			if v then
				n += 1
			end
		end
		return n >= (step.Count or 1)
	elseif step.Kind == "Reach" then
		local pos = placePosition(step.Place or "")
		local hrp = hrpOf(player)
		return pos ~= nil and hrp ~= nil and (hrp.Position - pos).Magnitude <= (step.Radius or 50)
	elseif step.Kind == "QuestItem" then
		return InventoryService.CountQuestItem(player, step.Item or "") > 0
	elseif step.Kind == "Kill" then
		return (st.Progress or 0) >= (step.Count or 1)
	end
	return false
end

local function snapshot(player: Player): { any }
	local data = DataService.Get(player)
	local list = {}
	if not data then
		return list
	end
	for id, q in pairs(Quests) do
		local st = data.Quests.Active[id]
		local ok, why = canAccept(data, q)
		local entry = {
			Id = id,
			Name = q.Name,
			Summary = q.Summary,
			Order = q.Order,
			Active = st ~= nil,
			Step = st and st.Step or 0,
			Progress = st and st.Progress or 0,
			Steps = {},
			CanAccept = ok,
			Why = why,
			Done = data.Quests.Completed[id] ~= nil,
			Reward = q.Reward,
		}
		for i, s in ipairs(q.Steps) do
			entry.Steps[i] = { Text = s.Text, Kind = s.Kind, Count = s.Count }
		end
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	return list
end

function QuestService.Push(player: Player)
	NetService.Fire(player, "QuestLog", snapshot(player))
end

local function complete(player: Player, data: { [string]: any }, q: Quests.QuestDef)
	data.Quests.Active[q.Id] = nil
	data.Quests.Completed[q.Id] = (data.Quests.Completed[q.Id] or 0) + 1
	local r = q.Reward
	local parts = {}
	if r.Coins then
		data.Coins += r.Coins
		DataService.MarkChanged(player, "Coins")
		table.insert(parts, string.format("%d moedas", r.Coins))
	end
	if r.Items then
		for _, it in ipairs(r.Items) do
			local got = InventoryService.Add(player, it.Item, it.Count)
			if got > 0 then
				table.insert(parts, string.format("%d %s", got, Items[it.Item].DisplayName))
			end
		end
	end
	if r.Points then
		local _, id = activeDragon(data)
		if id then
			DragonService.AddPoints(player, id, r.Points, "quest")
			DataService.MarkChanged(player, "Dragons")
			table.insert(parts, string.format("%d pontos para o dragão", r.Points))
		end
	end
	DataService.MarkChanged(player, "Quests")
	notify(player, "Missão concluída: " .. q.Name .. (if #parts > 0 then " (" .. table.concat(parts, ", ") .. ")" else ""), "success")
end

-- Avança etapas automáticas em sequência.
local function advance(player: Player, data: { [string]: any }, q: Quests.QuestDef)
	local st = data.Quests.Active[q.Id]
	while st do
		local step = q.Steps[st.Step]
		if not step then
			complete(player, data, q)
			return
		end
		if autoStepDone(player, data, step, st) then
			st.Step += 1
			st.Progress = 0
			DataService.MarkChanged(player, "Quests")
			local nxt = q.Steps[st.Step]
			if nxt then
				notify(player, q.Name .. ": " .. nxt.Text, "info")
			end
		else
			return
		end
	end
end

local function onAccept(player: Player, id: string)
	local data = DataService.Get(player)
	local q = Quests[id]
	if not data or not q or not nearGiver(player, q.Giver) then
		return
	end
	local ok, why = canAccept(data, q)
	if not ok then
		notify(player, why or "Não dá para aceitar essa missão agora.", "warning")
		return
	end
	local _, dragonId = activeDragon(data)
	data.Quests.Active[id] = { Step = 1, Progress = 0, DragonId = if q.PerDragon then dragonId else nil }
	DataService.MarkChanged(player, "Quests")
	notify(player, "Nova missão: " .. q.Name .. " — " .. q.Steps[1].Text, "success")
	advance(player, data, q)
	QuestService.Push(player)
end

-- Entregar / falar: etapas Collect e Talk (perto da Mestra Lira).
local function onTurnIn(player: Player, id: string)
	local data = DataService.Get(player)
	local q = Quests[id]
	if not data or not q then
		return
	end
	local st = data.Quests.Active[id]
	if not st or not nearGiver(player, q.Giver) then
		return
	end
	local step = q.Steps[st.Step]
	if not step then
		return
	end
	if step.Kind == "Collect" then
		local need = step.Count or 1
		if not InventoryService.Remove(player, step.Item :: string, need) then
			notify(player, string.format("Você precisa de %d %s na mochila.", need, Items[step.Item :: string].DisplayName), "warning")
			return
		end
	elseif step.Kind ~= "Talk" then
		return
	end
	st.Step += 1
	st.Progress = 0
	DataService.MarkChanged(player, "Quests")
	advance(player, data, q)
	if data.Quests.Active[id] then
		local nxt = q.Steps[data.Quests.Active[id].Step]
		if nxt then
			notify(player, q.Name .. ": " .. nxt.Text)
		end
	end
	QuestService.Push(player)
end

-- Dar a poção ao dragão (etapa Feed): perto do dragão ativo, que cumpre os requisitos.
local function onFeedPotion(player: Player, id: string)
	local data = DataService.Get(player)
	local q = Quests[id]
	if not data or not q or not q.PerDragon then
		return
	end
	local st = data.Quests.Active[id]
	local step = st and q.Steps[st.Step]
	if not st or not step or step.Kind ~= "Feed" then
		return
	end
	local d, dragonId = activeDragon(data)
	if not d or not dragonId then
		return
	end
	-- a poção não ignora a idade: o dragão precisa ser Jovem e da espécie certa
	local ok, why = true, nil
	if Growth.StageIndex(d.Stage) < Growth.StageIndex(Growth.FlightStage) then
		ok, why = false, "Seu dragão ativo precisa ser Jovem."
	elseif q.PerDragon == "Flight" and (not Species[d.Species].CanFly or d.FlightUnlocked) then
		ok, why = false, "Esse dragão não pode receber a Poção do Voo."
	elseif q.PerDragon == "Burrow" and (d.Species ~= "Wyrm" or d.BurrowUnlocked) then
		ok, why = false, "Só um Wyrm que ainda não entra na terra pode receber essa poção."
	end
	if not ok then
		notify(player, why :: string, "warning")
		return
	end
	local comp = CompanionService.Get(player)
	local hrp = hrpOf(player)
	if not comp or not comp.PrimaryPart or not hrp or (comp.PrimaryPart.Position - hrp.Position).Magnitude > 30 then
		notify(player, "Chame seu dragão ativo e fique perto dele para dar a poção.", "warning")
		return
	end
	if not InventoryService.RemoveQuestItem(player, step.Item :: string, 1) then
		notify(player, "Você não tem a poção.", "warning")
		return
	end
	if q.PerDragon == "Flight" then
		d.FlightUnlocked = true
		NetService.Fire(player, "Tutorial", "Flight")
	else
		d.BurrowUnlocked = true
		NetService.Fire(player, "Tutorial", "Burrow")
	end
	DataService.MarkChanged(player, "Dragons")
	st.Step += 1
	advance(player, data, q)
	-- reconstrói o companheiro para liberar o novo modo
	DragonService.Refresh(player, dragonId)
	QuestService.Push(player)
end

function QuestService.Init()
	NetService.On("QuestAccept", onAccept)
	NetService.On("QuestTurnIn", onTurnIn)
	NetService.On("QuestFeed", onFeedPotion)
	NetService.On("QuestLogRequest", function(player: Player)
		QuestService.Push(player)
	end)

	EnemyService.OnKilled(function(player: Player, enemyId: string)
		local data = DataService.Get(player)
		if not data then
			return
		end
		for id, st in pairs(data.Quests.Active) do
			local q = Quests[id]
			local step = q and q.Steps[st.Step]
			if step and step.Kind == "Kill" and (not step.Enemies or #step.Enemies == 0 or table.find(step.Enemies, enemyId)) then
				st.Progress = (st.Progress or 0) + 1
				DataService.MarkChanged(player, "Quests")
				notify(player, string.format("%s: %d / %d", q.Name, math.min(st.Progress, step.Count or 1), step.Count or 1))
				advance(player, data, q)
			end
		end
	end)

	-- etapas automáticas (chegar a um lugar, obeliscos, item de missão) a cada 2 s
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.Get(player)
				if data then
					for id in pairs(data.Quests.Active) do
						local q = Quests[id]
						if q then
							pcall(advance, player, data, q)
						end
					end
				end
			end
		end
	end)
end

-- Chamado quando o jogador fala com a Mestra Lira.
function QuestService.Open(player: Player)
	QuestService.Push(player)
	NetService.Fire(player, "OpenQuests")
end

return QuestService
