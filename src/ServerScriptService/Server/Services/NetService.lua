--!strict
-- Camada de rede protegida.
-- Cria todos os remotes a partir de NetDefs e protege cada pedido do cliente com:
--   1. limite de frequência por jogador (balde de fichas);
--   2. validação de quantidade e tipo de argumentos;
--   3. exigência de perfil carregado (salvo BeforeLoad);
--   4. contagem de infrações, com expulsão de quem abusa;
--   5. pcall no handler, para um erro não derrubar o servidor.
-- Regra de ouro: o cliente só PEDE; quem decide é sempre o servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetDefs = require(ReplicatedStorage.Shared.Net.NetDefs)

local NetService = {}

local STRIKE_LIMIT = 25 -- infrações toleradas na janela
local STRIKE_WINDOW = 60 -- segundos
local DEFAULT_RATE = 5
local DEFAULT_MAX_STRING = 200

local remotesFolder: Folder
local remotes: { [string]: Instance } = {}
local handlers: { [string]: (Player, ...any) -> ...any } = {}

type Bucket = { tokens: number, last: number }
local buckets: { [Player]: { [string]: Bucket } } = {}
local strikes: { [Player]: { number } } = {}

local isLoaded: (Player) -> boolean = function()
	return true
end

-- DataService informa como saber se o perfil do jogador já carregou.
function NetService.SetLoadedCheck(fn: (Player) -> boolean)
	isLoaded = fn
end

local function addStrike(player: Player, remoteName: string, reason: string)
	local list = strikes[player]
	if not list then
		list = {}
		strikes[player] = list
	end
	local now = os.clock()
	table.insert(list, now)
	while #list > 0 and now - list[1] > STRIKE_WINDOW do
		table.remove(list, 1)
	end
	if #list <= 3 or #list % 10 == 0 then
		warn(string.format("[Net] %s (%d) rejeitado em %s: %s [%d infrações/min]", player.Name, player.UserId, remoteName, reason, #list))
	end
	if #list >= STRIKE_LIMIT then
		warn(string.format("[Net] Expulsando %s por excesso de pedidos inválidos", player.Name))
		player:Kick("Conexão encerrada: muitos pedidos inválidos.")
	end
end

local function allowRate(player: Player, name: string, def: NetDefs.RemoteDef): boolean
	local rate = def.Rate or DEFAULT_RATE
	local burst = def.Burst or math.max(1, math.ceil(rate * 2))
	local perPlayer = buckets[player]
	if not perPlayer then
		perPlayer = {}
		buckets[player] = perPlayer
	end
	local now = os.clock()
	local b = perPlayer[name]
	if not b then
		b = { tokens = burst, last = now }
		perPlayer[name] = b
	end
	b.tokens = math.min(burst, b.tokens + (now - b.last) * rate)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

local function isFiniteNumber(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

local function checkArg(value: any, schema: NetDefs.ArgSchema): (boolean, string?)
	if value == nil then
		if schema.Optional then
			return true
		end
		return false, "argumento obrigatório ausente"
	end
	local t = schema.Type
	if t == "string" then
		if type(value) ~= "string" then
			return false, "esperava string"
		end
		if utf8.len(value) == nil then
			return false, "string com UTF-8 inválido"
		end
		if #value > (schema.MaxLen or DEFAULT_MAX_STRING) then
			return false, "string longa demais"
		end
	elseif t == "number" or t == "integer" then
		if not isFiniteNumber(value) then
			return false, "esperava número finito"
		end
		if t == "integer" and math.floor(value) ~= value then
			return false, "esperava inteiro"
		end
		if schema.Min and value < schema.Min then
			return false, "número abaixo do mínimo"
		end
		if schema.Max and value > schema.Max then
			return false, "número acima do máximo"
		end
	elseif t == "boolean" then
		if type(value) ~= "boolean" then
			return false, "esperava boolean"
		end
	elseif t == "enum" then
		if type(value) ~= "string" or not schema.Values or not table.find(schema.Values, value) then
			return false, "valor fora da lista permitida"
		end
	elseif t == "Vector3" then
		if typeof(value) ~= "Vector3" then
			return false, "esperava Vector3"
		end
		if not (isFiniteNumber(value.X) and isFiniteNumber(value.Y) and isFiniteNumber(value.Z)) then
			return false, "Vector3 com valores inválidos"
		end
		if schema.MaxMagnitude and value.Magnitude > schema.MaxMagnitude then
			return false, "Vector3 grande demais"
		end
	else
		return false, "tipo de esquema desconhecido: " .. tostring(t)
	end
	return true
end

-- Retorna true se o pedido pode seguir para o handler.
local function gate(player: Player, name: string, def: NetDefs.RemoteDef, ...: any): boolean
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
		return false
	end
	if not allowRate(player, name, def) then
		addStrike(player, name, "frequência acima do limite")
		return false
	end
	if not def.BeforeLoad and not isLoaded(player) then
		return false -- perfil ainda carregando: ignora sem punir
	end
	local schema = def.Args or {}
	local count = select("#", ...)
	if count > #schema then
		addStrike(player, name, "argumentos a mais")
		return false
	end
	for i, argSchema in ipairs(schema) do
		local ok, reason = checkArg((select(i, ...)), argSchema)
		if not ok then
			addStrike(player, name, "arg " .. i .. ": " .. (reason or "?"))
			return false
		end
	end
	return true
end

function NetService.Init()
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		existing:Destroy()
	end
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"

	for name, def in pairs(NetDefs) do
		local remote: Instance
		if def.Kind == "Function" then
			assert(def.Direction == "C2S", "RemoteFunction só pode ser cliente -> servidor: " .. name)
			local rf = Instance.new("RemoteFunction")
			rf.OnServerInvoke = function(player: Player, ...)
				if not gate(player, name, def, ...) then
					return nil
				end
				local handler = handlers[name]
				if not handler then
					return nil
				end
				local results = table.pack(pcall(handler, player, ...))
				if not results[1] then
					warn("[Net] Erro no handler de " .. name .. ": " .. tostring(results[2]))
					return nil
				end
				return table.unpack(results, 2, results.n)
			end
			remote = rf
		else
			local re = Instance.new("RemoteEvent")
			if def.Direction == "C2S" then
				re.OnServerEvent:Connect(function(player: Player, ...)
					if not gate(player, name, def, ...) then
						return
					end
					local handler = handlers[name]
					if handler then
						local ok, err = pcall(handler, player, ...)
						if not ok then
							warn("[Net] Erro no handler de " .. name .. ": " .. tostring(err))
						end
					end
				end)
			else
				-- Remote S2C: qualquer envio do cliente é suspeito.
				re.OnServerEvent:Connect(function(player: Player)
					addStrike(player, name, "cliente enviou em remote só do servidor")
				end)
			end
			remote = re
		end
		remote.Name = name
		remote.Parent = remotesFolder
		remotes[name] = remote
	end

	remotesFolder.Parent = ReplicatedStorage

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
		strikes[player] = nil
	end)
end

-- Registra o handler de um remote C2S.
function NetService.On(name: string, handler: (Player, ...any) -> ...any)
	local def = NetDefs[name]
	assert(def, "Remote não definido em NetDefs: " .. name)
	assert(def.Direction == "C2S", "Só se registra handler em remote C2S: " .. name)
	handlers[name] = handler
end

function NetService.Fire(player: Player, name: string, ...: any)
	local remote = remotes[name]
	assert(remote and remote:IsA("RemoteEvent") and NetDefs[name].Direction == "S2C", "Remote S2C inválido: " .. name)
	local re = remote :: RemoteEvent
	re:FireClient(player, ...)
end

function NetService.FireAll(name: string, ...: any)
	local remote = remotes[name]
	assert(remote and remote:IsA("RemoteEvent") and NetDefs[name].Direction == "S2C", "Remote S2C inválido: " .. name)
	local re = remote :: RemoteEvent
	re:FireAllClients(...)
end

return NetService
