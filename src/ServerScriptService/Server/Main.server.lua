--!strict
-- Ponto de entrada do servidor. Inicializa os serviços na ordem certa.

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Server = ServerScriptService:WaitForChild("Server")
local NetService = require(Server.Services.NetService)
local DataService = require(Server.Data.DataService)

NetService.SetLoadedCheck(DataService.IsLoaded)
NetService.Init()

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
	if clientReady[player] then
		sendSnapshot(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	clientReady[player] = nil
end)

NetService.On("Ping", function(_player: Player, n: number)
	return n
end)

DataService.Init()

print("[Server] Fundação iniciada")
