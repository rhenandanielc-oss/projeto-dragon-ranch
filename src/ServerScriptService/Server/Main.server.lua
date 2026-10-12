--!strict
-- Ponto de entrada do servidor. Inicializa os serviços na ordem certa.

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Server = ServerScriptService:WaitForChild("Server")
local NetService = require(Server.Services.NetService)
local DataService = require(Server.Data.DataService)
local FarmService = require(Server.Services.FarmService)
local DragonService = require(Server.Dragons.DragonService)
local NPCService = require(Server.Services.NPCService)

NetService.SetLoadedCheck(DataService.IsLoaded)
NetService.Init()

-- Mudanças no perfil são enviadas ao dono (cópia somente-leitura).
DataService.SetChangedCallback(function(player: Player, key: string, value: any)
	NetService.Fire(player, "ProfileChanged", key, value)
end)

-- Cliente pronto -> envia cópia do perfil quando estiver carregado.
local clientReady: { [Player]: boolean } = {}

local function sendSnapshot(player: Player)
	local data = DataService.Get(player)
	if data then
		NetService.Fire(player, "ProfileSnapshot", data)
	end
end

NetService.On("ClientReady", function(player: Player)
	clientReady[player] = true
	sendSnapshot(player)
end)

DataService.ProfileLoaded:Connect(function(player: Player)
	FarmService.Assign(player, DataService.Get(player))
	if clientReady[player] then
		sendSnapshot(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	clientReady[player] = nil
end)

-- Mesa do cartógrafo no Hub: mapa e escolha do bioma da fazenda (D3/D8)
local function setupMapTable()
	local hub = workspace:FindFirstChild("Hub")
	local plaza = hub and hub:FindFirstChild("Plaza")
	local mapTable = plaza and plaza:FindFirstChild("MapTable")
	if not mapTable or not mapTable:IsA("BasePart") then
		warn("[Server] Mesa do cartógrafo não encontrada")
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenMap"
	prompt.ActionText = "Ver mapa e fazendas"
	prompt.ObjectText = "Mesa do cartógrafo"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = mapTable
	prompt.Triggered:Connect(function(player: Player)
		local data = DataService.Get(player)
		if not data then
			return
		end
		local plot = FarmService.GetPlot(player)
		NetService.Fire(player, "FarmChooser", FarmService.FreeBiomes(), plot and plot:GetAttribute("Biome") or "", FarmService.IsAdvanced(data))
	end)
end

NetService.On("ChooseFarmBiome", function(player: Player, biome: string)
	local data = DataService.Get(player)
	local ok, message = FarmService.ChooseBiome(player, data, biome)
	if data then
		DataService.MarkChanged(player, "Farm")
	end
	NetService.Fire(player, "Notify", message, if ok then "success" else "info")
end)

NetService.On("Ping", function(_player: Player, n: number)
	return n
end)

FarmService.Init()
DragonService.Init()
NPCService.Init()
setupMapTable()
DataService.Init()

print("[Server] Servidor iniciado (mundo aberto, fazenda e dragões)")
