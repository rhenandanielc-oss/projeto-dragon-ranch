--!strict
-- Fase 9: PvP por zona (GAME-DESIGN §11).
--  * Zona protegida (Hub, fazendas, acampamentos): sem PvP.
--  * Zona comum: PvP sem perda de itens.
--  * Zona perigosa: quem perde deixa até 40% dos MATERIAIS carregados para quem venceu.
--  * Proteção de iniciante até o primeiro dragão virar Jovem (atacar alguém tira a proteção).
--  * 2 minutos de proteção ao renascer depois de perder em PvP.
--  * Anti-abuso: derrotar o mesmo jogador de novo em 30 min não dá loot.
--  * Aviso na tela ao entrar em cada tipo de zona (atributo "Zone" no jogador).
-- Nunca se perde: dragões, estágios, pontos, missões, desbloqueios, equipamentos, moedas, itens de missão.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Rules = require(ReplicatedStorage.Shared.Config.Rules)
local Items = require(ReplicatedStorage.Shared.Config.Items)

local Server = ServerScriptService.Server
local DataService = require(Server.Data.DataService)
local NetService = require(Server.Services.NetService)
local InventoryService = require(Server.Services.InventoryService)
local CombatService = require(Server.Combat.CombatService)
local WorldQuery = require(Server.World.WorldQuery)

local PvPService = {}

local respawnProtectedUntil: { [Player]: number } = {}
local lootCooldown: { [string]: number } = {} -- "vencedor:perdedor" -> os.time() liberado

local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

function PvPService.ZoneAt(pos: Vector3): string
	if WorldQuery.IsSafe(pos) then
		return "Safe"
	elseif WorldQuery.IsDanger(pos) then
		return "Danger"
	end
	return "Common"
end

local function zoneOf(player: Player): string
	if player:GetAttribute("InDungeon") then
		return "Dungeon" -- dungeon não é zona de PvP
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return "Safe"
	end
	return PvPService.ZoneAt(hrp.Position)
end

local function newPlayerProtected(player: Player): boolean
	local data = DataService.Get(player)
	return data ~= nil and data.Protection ~= nil and data.Protection.NewPlayer == true
end

local function protectedNow(player: Player): (boolean, string?)
	if newPlayerProtected(player) then
		return true, "proteção de iniciante"
	end
	if os.clock() < (respawnProtectedUntil[player] or 0) then
		return true, "proteção ao renascer"
	end
	return false
end

-- Regra usada pelo CombatService para todo dano entre jogadores (e seus dragões).
local function pvpRule(attacker: Player, victim: Player): boolean
	local za, zv = zoneOf(attacker), zoneOf(victim)
	if za == "Safe" or zv == "Safe" or za == "Dungeon" or zv == "Dungeon" then
		return false
	end
	local prot = protectedNow(victim)
	if prot then
		return false
	end
	-- quem ainda tem proteção de renascimento e ataca, perde a proteção (abaixo, no OnPlayerAttack)
	return true
end

local function lootOnDefeat(winner: Player, loser: Player)
	local key = tostring(winner.UserId) .. ":" .. tostring(loser.UserId)
	local now = os.time()
	if now < (lootCooldown[key] or 0) then
		notify(winner, "Você derrotou " .. loser.DisplayName .. " de novo em pouco tempo: sem loot desta vez.")
		return
	end
	lootCooldown[key] = now + Rules.PvP.SameVictimLootCooldownSeconds
	local data = DataService.Get(loser)
	if not data then
		return
	end
	-- só materiais coletados (Lootable), até 40% de cada um
	local totals: { [string]: number } = {}
	for _, s in ipairs(data.Backpack.Slots) do
		local def = Items[s.Item]
		if def and def.Lootable and def.Category == "Material" then
			totals[s.Item] = (totals[s.Item] or 0) + s.Count
		end
	end
	local lostParts, gotParts = {}, {}
	for itemId, n in pairs(totals) do
		local lose = math.floor(n * Rules.PvP.DangerZoneLossFraction)
		if lose > 0 and InventoryService.Remove(loser, itemId, lose) then
			local got = InventoryService.Add(winner, itemId, lose)
			table.insert(lostParts, string.format("%d %s", lose, Items[itemId].DisplayName))
			if got > 0 then
				table.insert(gotParts, string.format("%d %s", got, Items[itemId].DisplayName))
			end
		end
	end
	if #lostParts > 0 then
		notify(loser, "Você perdeu numa zona perigosa e deixou cair: " .. table.concat(lostParts, ", ") .. ".", "warning")
	end
	if #gotParts > 0 then
		notify(winner, "Loot de " .. loser.DisplayName .. ": " .. table.concat(gotParts, ", ") .. ".", "success")
	end
end

local function onDied(player: Player)
	local killer = CombatService.LastAttacker(player, 15)
	if not killer or killer == player then
		return
	end
	local zone = zoneOf(player)
	respawnProtectedUntil[player] = os.clock() + Rules.PvP.RespawnProtectionSeconds
	player:SetAttribute("RespawnProtectedUntil", workspace:GetServerTimeNow() + Rules.PvP.RespawnProtectionSeconds)
	notify(killer, "Você derrotou " .. player.DisplayName .. ".")
	if zone == "Danger" then
		lootOnDefeat(killer, player)
	else
		notify(player, killer.DisplayName .. " derrotou você. Zona comum: você não perdeu nada.")
	end
end

function PvPService.Init()
	CombatService.SetPvPRule(pvpRule)

	-- atacar outro jogador tira as proteções de quem atacou
	CombatService.OnPlayerAttack(function(attacker: Player, target: CombatService.Target)
		if target.kind == "Enemy" or not target.player or target.player == attacker then
			return
		end
		if os.clock() < (respawnProtectedUntil[attacker] or 0) then
			respawnProtectedUntil[attacker] = 0
			attacker:SetAttribute("RespawnProtectedUntil", 0)
		end
		local data = DataService.Get(attacker)
		if data and data.Protection and data.Protection.NewPlayer then
			data.Protection.NewPlayer = false
			DataService.MarkChanged(attacker, "Protection")
			notify(attacker, "Você atacou outro jogador e perdeu a proteção de iniciante.", "warning")
		end
	end)

	local function hook(player: Player)
		player.CharacterAdded:Connect(function(char)
			local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
			if hum then
				hum.Died:Connect(function()
					onDied(player)
				end)
			end
		end)
	end
	for _, p in ipairs(Players:GetPlayers()) do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	Players.PlayerRemoving:Connect(function(player)
		respawnProtectedUntil[player] = nil
	end)

	-- zona atual de cada jogador (o cliente mostra o aviso quando muda)
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, p in ipairs(Players:GetPlayers()) do
				local z = zoneOf(p)
				if p:GetAttribute("Zone") ~= z then
					p:SetAttribute("Zone", z)
				end
				p:SetAttribute("NewPlayerProtected", newPlayerProtected(p))
			end
		end
	end)
end

return PvPService
