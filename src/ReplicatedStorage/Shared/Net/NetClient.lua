--!strict
-- Acesso do cliente aos remotes definidos em NetDefs.
-- O cliente apenas PEDE coisas; o servidor valida e decide.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NetDefs = require(script.Parent.NetDefs)

assert(RunService:IsClient(), "NetClient só pode ser usado no cliente")

local NetClient = {}

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30) :: Folder
assert(remotesFolder, "Pasta Remotes não encontrada")

local function getRemote(name: string): Instance
	local def = NetDefs[name]
	assert(def, "Remote não definido em NetDefs: " .. name)
	local remote = remotesFolder:WaitForChild(name, 10)
	assert(remote, "Remote não encontrado: " .. name)
	return remote :: Instance
end

-- Envia um pedido ao servidor (C2S).
function NetClient.Fire(name: string, ...: any)
	assert(NetDefs[name].Direction == "C2S", name .. " não é C2S")
	local re = getRemote(name) :: RemoteEvent
	re:FireServer(...)
end

-- Pede algo e espera a resposta (C2S, RemoteFunction).
function NetClient.Invoke(name: string, ...: any): ...any
	assert(NetDefs[name].Kind == "Function", name .. " não é Function")
	local rf = getRemote(name) :: RemoteFunction
	return rf:InvokeServer(...)
end

-- Escuta avisos do servidor (S2C).
function NetClient.On(name: string, callback: (...any) -> ()): RBXScriptConnection
	assert(NetDefs[name].Direction == "S2C", name .. " não é S2C")
	local re = getRemote(name) :: RemoteEvent
	return re.OnClientEvent:Connect(callback)
end

return NetClient
