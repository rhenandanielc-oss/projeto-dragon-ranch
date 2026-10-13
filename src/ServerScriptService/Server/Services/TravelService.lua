--!strict
-- Viagem (WORLD-DESIGN D7): waypoints despertados por exploração e Pedra do Retorno.
--  * Tocar um obelisco o desperta (fica salvo no perfil).
--  * Num obelisco despertado, o jogador pode viajar para qualquer outro já despertado.
--  * Ao despertar Rules.Travel.ReturnStoneUnlockWaypoints obeliscos, ganha a Pedra do Retorno:
--    parado por alguns segundos, volta para a própria fazenda (com recarga).
-- Também trata o uso de itens da barra (UseItem).
-- Anti-exploit: distância do obelisco no servidor, destino precisa estar despertado, recargas
-- guardadas no servidor/perfil, canalização cancela se o jogador se mover.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Rules = require(ReplicatedStorage.Shared.Config.Rules)
local Items = require(ReplicatedStorage.Shared.Config.Items)

local Server = ServerScriptService.Server
local DataService = require(Server.Data.DataService)
local NetService = require(Server.Services.NetService)
local FarmService = require(Server.Services.FarmService)
local InventoryService = require(Server.Services.InventoryService)
local CompanionService = require(Server.Dragons.CompanionService)

local TravelService = {}

type Waypoint = { id: number, name: string, model: Model, pos: Vector3 }
local waypoints: { [number]: Waypoint } = {}
local travelCooldown: { [Player]: number } = {}
local channeling: { [Player]: boolean } = {}
local potionCooldown: { [Player]: number } = {}

local HEALTH_POTION_HEAL = 45 -- provisório (combate chega na Fase 5)
local HEALTH_POTION_COOLDOWN = 8

local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

local function hrpOf(player: Player): BasePart?
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function awakened(data: { [string]: any }): { [string]: boolean }
	data.Travel = data.Travel or { Waypoints = {}, ReturnReadyAt = 0 }
	data.Travel.Waypoints = data.Travel.Waypoints or {}
	return data.Travel.Waypoints
end

local function countAwakened(data: { [string]: any }): number
	local n = 0
	for _, v in pairs(awakened(data)) do
		if v then
			n += 1
		end
	end
	return n
end

-- Teleporta o jogador (desmonta antes; o dragão companheiro reaparece ao lado sozinho).
local function teleport(player: Player, pos: Vector3)
	local hrp = hrpOf(player)
	if not hrp then
		return
	end
	if CompanionService.IsMounted(player) then
		CompanionService.Dismount(player)
	end
	pcall(function()
		player:RequestStreamAroundAsync(pos, 5)
	end)
	local char = player.Character :: Model
	char:PivotTo(CFrame.new(pos + Vector3.new(0, 4, 0)) * hrp.CFrame.Rotation)
end

local function nearestWaypoint(player: Player): Waypoint?
	local hrp = hrpOf(player)
	if not hrp then
		return nil
	end
	for _, w in pairs(waypoints) do
		if (hrp.Position - w.pos).Magnitude <= Rules.Travel.WaypointDistance + 12 then
			return w
		end
	end
	return nil
end

local function giveReturnStone(player: Player, data: { [string]: any })
	if InventoryService.Count(player, "ReturnStone") > 0 then
		return
	end
	for _, s in ipairs(data.Storage.Slots) do
		if s.Item == "ReturnStone" then
			return
		end
	end
	if InventoryService.Add(player, "ReturnStone", 1) > 0 then
		notify(player, "Você ganhou a Pedra do Retorno! Use-a (pela mochila ou pela barra) para voltar à sua fazenda.", "success")
	else
		notify(player, "Você ganhou a Pedra do Retorno, mas a mochila está cheia. Abra espaço e desperte um obelisco de novo.", "warning")
	end
end

local function onWaypointPrompt(player: Player, w: Waypoint)
	local data = DataService.Get(player)
	local hrp = hrpOf(player)
	if not data or not hrp or (hrp.Position - w.pos).Magnitude > Rules.Travel.WaypointDistance + 12 then
		return
	end
	local list = awakened(data)
	local key = tostring(w.id)
	if not list[key] then
		list[key] = true
		DataService.MarkChanged(player, "Travel")
		notify(player, "Obelisco despertado: " .. w.name .. ".", "success")
		if countAwakened(data) >= Rules.Travel.ReturnStoneUnlockWaypoints then
			giveReturnStone(player, data)
		end
	elseif countAwakened(data) >= Rules.Travel.ReturnStoneUnlockWaypoints then
		giveReturnStone(player, data)
	end
	-- lista de destinos (só despertados)
	local dests = {}
	for id, wp in pairs(waypoints) do
		if list[tostring(id)] and id ~= w.id then
			table.insert(dests, { Id = id, Name = wp.name, X = wp.pos.X, Z = wp.pos.Z })
		end
	end
	table.sort(dests, function(a, b)
		return a.Id < b.Id
	end)
	NetService.Fire(player, "OpenWaypoints", w.id, dests)
end

local function onTravel(player: Player, targetId: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local here = nearestWaypoint(player)
	local target = waypoints[targetId]
	local list = awakened(data)
	if not here or not target or here.id == targetId then
		return
	end
	if not list[tostring(here.id)] or not list[tostring(targetId)] then
		return
	end
	local now = os.clock()
	if now < (travelCooldown[player] or 0) then
		notify(player, string.format("Os obeliscos ainda estão se recarregando (%d s).", math.ceil(travelCooldown[player] - now)))
		return
	end
	travelCooldown[player] = now + Rules.Travel.WaypointCooldownSeconds
	-- chega ao lado do obelisco, virado para fora
	local off = Vector3.new(0, 0, 24)
	teleport(player, target.pos + off)
	notify(player, "Você viajou até " .. target.name .. ".")
end

local function useReturnStone(player: Player, data: { [string]: any })
	if channeling[player] then
		return
	end
	if player:GetAttribute("InDungeon") then
		notify(player, "A Pedra do Retorno não funciona dentro da dungeon.")
		return
	end
	local readyAt = data.Travel and data.Travel.ReturnReadyAt or 0
	if os.time() < readyAt then
		notify(player, string.format("A Pedra do Retorno ainda está fria (%d s).", readyAt - os.time()))
		return
	end
	local plot = FarmService.GetPlot(player)
	local base = plot and plot:FindFirstChild("Base")
	local spawnAtt = base and base:FindFirstChild("Spawn")
	if not spawnAtt or not spawnAtt:IsA("Attachment") then
		return
	end
	local hrp = hrpOf(player)
	if not hrp then
		return
	end
	if CompanionService.IsMounted(player) then
		notify(player, "Desça do dragão para usar a Pedra do Retorno.")
		return
	end
	channeling[player] = true
	local start = hrp.Position
	local secs = Rules.Travel.ReturnChannelSeconds
	NetService.Fire(player, "ChannelStarted", secs, "Voltando para a fazenda…")
	task.delay(secs, function()
		channeling[player] = nil
		local h = hrpOf(player)
		if not h or not player.Parent then
			return
		end
		if (h.Position - start).Magnitude > Rules.Travel.ReturnMaxMove then
			notify(player, "Você se moveu: o retorno foi cancelado.", "warning")
			NetService.Fire(player, "ChannelStarted", 0, "")
			return
		end
		if InventoryService.Count(player, "ReturnStone") <= 0 then
			return
		end
		data.Travel.ReturnReadyAt = os.time() + Rules.Travel.ReturnCooldownSeconds
		DataService.MarkChanged(player, "Travel")
		teleport(player, (spawnAtt :: Attachment).WorldPosition)
		notify(player, "Bem-vindo de volta à fazenda!", "success")
	end)
end

local function onUseItem(player: Player, itemId: string)
	local data = DataService.Get(player)
	if not data or not Items[itemId] or InventoryService.Count(player, itemId) <= 0 then
		return
	end
	if itemId == "ReturnStone" then
		useReturnStone(player, data)
	elseif itemId == "HealthPotion" then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return
		end
		if os.clock() < (potionCooldown[player] or 0) then
			return
		end
		if hum.Health >= hum.MaxHealth then
			notify(player, "Sua vida já está cheia.")
			return
		end
		if InventoryService.Remove(player, "HealthPotion", 1) then
			potionCooldown[player] = os.clock() + HEALTH_POTION_COOLDOWN
			hum.Health = math.min(hum.MaxHealth, hum.Health + HEALTH_POTION_HEAL)
			notify(player, "Você bebeu uma Poção de Vida.", "success")
		end
	end
end

function TravelService.Init()
	local world = workspace:FindFirstChild("World")
	local folder = world and world:FindFirstChild("Waypoints")
	if folder then
		for _, m in ipairs(folder:GetChildren()) do
			local id = m:GetAttribute("WaypointId")
			if m:IsA("Model") and type(id) == "number" then
				local bcf, size = m:GetBoundingBox()
				local w: Waypoint = { id = id, name = tostring(m:GetAttribute("WaypointName") or ("Obelisco " .. id)), model = m, pos = bcf.Position - Vector3.new(0, size.Y / 2, 0) }
				waypoints[id] = w
				local anchor = Instance.new("Part")
				anchor.Name = "PromptAnchor"
				anchor.Size = Vector3.new(1, 1, 1)
				anchor.Transparency = 1
				anchor.Anchored = true
				anchor.CanCollide = false
				anchor.CanQuery = false
				anchor.CFrame = CFrame.new(w.pos + Vector3.new(0, 4, 0))
				anchor.Parent = m
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "Waypoint"
				prompt.ActionText = "Tocar o obelisco"
				prompt.ObjectText = w.name
				prompt.HoldDuration = 0.5
				prompt.MaxActivationDistance = Rules.Travel.WaypointDistance
				prompt.RequiresLineOfSight = false
				prompt.Parent = anchor
				prompt.Triggered:Connect(function(player: Player)
					onWaypointPrompt(player, w)
				end)
			end
		end
	else
		warn("[Travel] workspace.World.Waypoints não encontrado")
	end
	NetService.On("TravelWaypoint", onTravel)
	NetService.On("UseItem", onUseItem)
	Players.PlayerRemoving:Connect(function(player)
		travelCooldown[player] = nil
		channeling[player] = nil
		potionCooldown[player] = nil
	end)
end

return TravelService
