--!strict
-- Ponto de entrada do cliente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetClient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("NetClient"))

-- Cópia somente-leitura do perfil, usada pela interface.
local profile: { [string]: any }? = nil

NetClient.On("ProfileSnapshot", function(data: { [string]: any })
	profile = data
	print(string.format("[Client] Perfil recebido: %d moedas, mochila %d espaços, sessão %d", data.Coins, data.Backpack.Capacity, data.Stats.Sessions))
end)

NetClient.On("ProfileChanged", function(key: string, value: any)
	if profile then
		profile[key] = value
	end
end)

NetClient.Fire("ClientReady")
