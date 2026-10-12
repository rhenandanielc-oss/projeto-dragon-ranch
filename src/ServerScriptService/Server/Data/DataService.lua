--!strict
-- Salvamento dos jogadores (B8).
--
-- Proteções:
--   * Trava de sessão: o perfil fica "travado" no servidor em que o jogador está.
--     Outro servidor não carrega nem sobrescreve enquanto a trava estiver ativa,
--     o que impede duplicar itens entrando em dois servidores.
--   * Trava expira após LOCK_TIMEOUT se um servidor cair sem liberar.
--   * Só salva perfis que carregaram com sucesso: nunca sobrescreve dados bons com dados vazios.
--   * Se a trava for perdida para outro servidor, este para de salvar e expulsa o jogador.
--   * Novas tentativas com espera crescente quando o DataStore falha.
--   * Autosave periódico, ao sair e ao fechar o servidor.
--   * No Studio sem acesso às APIs, usa um armazenamento em memória (com aviso).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileTemplate = require(script.Parent.ProfileTemplate)

local DataService = {}

local STORE_NAME = "PlayerData_v1"
local SESSION_ID = HttpService:GenerateGUID(false)
local LOCK_TIMEOUT = 600 -- segundos
local AUTOSAVE_INTERVAL = 150 -- segundos
local LOAD_ATTEMPTS = 6
local LOCKED_RETRY_WAIT = 6
local SAVE_ATTEMPTS = 4
local MAX_RECORD_BYTES = 3_500_000 -- limite do DataStore é 4 MB

type Profile = {
	Data: { [string]: any },
	Loaded: boolean,
	Released: boolean,
	SessionStart: number,
	Saving: boolean,
}

type Store = {
	UpdateAsync: (self: any, key: string, transform: (any) -> any) -> any,
}

local profiles: { [Player]: Profile } = {}
local store: Store
local usingMock = false

local loadedEvent = Instance.new("BindableEvent")
DataService.ProfileLoaded = loadedEvent.Event -- (player, data)

--------------------------------------------------------------------------
-- Armazenamento em memória para o Studio sem acesso às APIs
--------------------------------------------------------------------------
local MockStore = {}
MockStore.__index = MockStore
local mockData: { [string]: any } = {}
function MockStore:UpdateAsync(key: string, transform: (any) -> any): any
	local current = mockData[key]
	local copy = current and HttpService:JSONDecode(HttpService:JSONEncode(current)) or nil
	local result = transform(copy)
	if result ~= nil then
		mockData[key] = HttpService:JSONDecode(HttpService:JSONEncode(result))
	end
	return result
end

local function pickStore(): Store
	local real = DataStoreService:GetDataStore(STORE_NAME)
	if RunService:IsStudio() then
		local ok, err = pcall(function()
			real:GetAsync("__probe")
		end)
		if not ok then
			warn("[Data] DataStore indisponível no Studio (" .. tostring(err) .. "). Usando armazenamento em memória: nada será salvo de verdade.")
			warn("[Data] Para testar o salvamento real: Game Settings > Security > Enable Studio Access to API Services.")
			usingMock = true
			return setmetatable({}, MockStore) :: any
		end
	end
	return real :: any
end

--------------------------------------------------------------------------
-- Utilidades
--------------------------------------------------------------------------
local function keyFor(player: Player): string
	return "u_" .. tostring(player.UserId)
end

local function waitForBudget()
	if usingMock then
		return
	end
	local tries = 0
	while DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync) < 1 and tries < 60 do
		tries += 1
		task.wait(1)
	end
end

-- Migrações entre versões do formato do perfil.
local MIGRATIONS: { [number]: (data: { [string]: any }) -> () } = {
	-- [1] = function(data) ... leva da versão 1 para a 2 ... end,
}

local function migrate(data: { [string]: any })
	local v = tonumber(data.Version) or 1
	while v < ProfileTemplate.VERSION do
		local step = MIGRATIONS[v]
		if step then
			step(data)
		end
		v += 1
	end
	data.Version = ProfileTemplate.VERSION
end

--------------------------------------------------------------------------
-- Carregar
--------------------------------------------------------------------------
local function loadProfile(player: Player)
	local key = keyFor(player)
	local loadedData: { [string]: any }? = nil
	local lastProblem = "desconhecido"

	for attempt = 1, LOAD_ATTEMPTS do
		if player.Parent ~= Players then
			return
		end
		waitForBudget()

		local lockedElsewhere = false
		local corrupted = false
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(old: any)
				lockedElsewhere = false
				corrupted = false
				local now = os.time()
				if old ~= nil and type(old) ~= "table" then
					corrupted = true
					return nil
				end
				if old and type(old.Lock) == "table" and old.Lock.Session ~= SESSION_ID and now - (tonumber(old.Lock.Time) or 0) < LOCK_TIMEOUT then
					lockedElsewhere = true
					return nil -- não mexe: outro servidor está usando
				end
				local data = (old and type(old.Data) == "table") and old.Data or ProfileTemplate.New()
				loadedData = data
				return {
					Data = data,
					Lock = { Session = SESSION_ID, Time = now, JobId = game.JobId },
					SavedAt = now,
				}
			end)
		end)

		if ok and corrupted then
			lastProblem = "registro corrompido"
			loadedData = nil
			break
		elseif ok and lockedElsewhere then
			lastProblem = "dados abertos em outro servidor"
			loadedData = nil
			task.wait(LOCKED_RETRY_WAIT)
		elseif ok and loadedData then
			break
		else
			lastProblem = tostring(err)
			loadedData = nil
			task.wait(math.min(2 ^ attempt, 20))
		end
	end

	if not loadedData then
		warn(string.format("[Data] Falha ao carregar %s: %s", player.Name, lastProblem))
		if player.Parent == Players then
			if lastProblem == "dados abertos em outro servidor" then
				player:Kick("Seus dados ainda estão abertos em outro servidor. Tente entrar de novo em alguns instantes.")
			else
				player:Kick("Não foi possível carregar seus dados. Seu progresso está seguro; tente entrar de novo.")
			end
		end
		return
	end

	local data = loadedData :: { [string]: any }
	migrate(data)
	ProfileTemplate.Reconcile(data)
	data.Stats.Sessions = (tonumber(data.Stats.Sessions) or 0) + 1

	local profile: Profile = {
		Data = data,
		Loaded = true,
		Released = false,
		SessionStart = os.clock(),
		Saving = false,
	}
	profiles[player] = profile

	if player.Parent ~= Players then
		-- Saiu enquanto carregava: libera a trava agora.
		DataService.Save(player, true)
		profiles[player] = nil
		return
	end

	print(string.format("[Data] Perfil de %s carregado (sessão %d)%s", player.Name, data.Stats.Sessions, usingMock and " [memória]" or ""))
	loadedEvent:Fire(player, data)
end

--------------------------------------------------------------------------
-- Salvar
--------------------------------------------------------------------------
function DataService.Save(player: Player, release: boolean?): boolean
	local profile = profiles[player]
	if not profile or not profile.Loaded or profile.Released then
		return false -- nunca salva perfil que não carregou
	end
	if type(profile.Data) ~= "table" or profile.Data.Version == nil then
		warn("[Data] Perfil inválido, salvamento cancelado para " .. player.Name)
		return false
	end
	while profile.Saving do
		task.wait(0.2)
	end
	if profile.Released then
		return false
	end
	profile.Saving = true

	-- Atualiza tempo de jogo.
	local now = os.clock()
	profile.Data.Stats.PlayTimeSeconds = (tonumber(profile.Data.Stats.PlayTimeSeconds) or 0) + math.floor(now - profile.SessionStart)
	profile.SessionStart = now

	local encodedOk, encoded = pcall(HttpService.JSONEncode, HttpService, profile.Data)
	if not encodedOk then
		warn("[Data] Perfil não serializável para " .. player.Name .. ": " .. tostring(encoded))
		profile.Saving = false
		return false
	end
	if #encoded > MAX_RECORD_BYTES then
		warn("[Data] Perfil grande demais (" .. #encoded .. " bytes) para " .. player.Name)
		profile.Saving = false
		return false
	end

	local key = keyFor(player)
	local lostLock = false
	local saved = false
	for attempt = 1, SAVE_ATTEMPTS do
		waitForBudget()
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(old: any)
				lostLock = false
				local t = os.time()
				if type(old) == "table" and type(old.Lock) == "table" and old.Lock.Session ~= SESSION_ID then
					lostLock = true
					return nil -- outro servidor assumiu: não sobrescrever
				end
				return {
					Data = profile.Data,
					Lock = (not release) and { Session = SESSION_ID, Time = t, JobId = game.JobId } or nil,
					SavedAt = t,
				}
			end)
		end)
		if ok then
			saved = not lostLock
			break
		end
		warn(string.format("[Data] Erro ao salvar %s (tentativa %d): %s", player.Name, attempt, tostring(err)))
		task.wait(math.min(2 ^ attempt, 10))
	end

	profile.Saving = false

	if lostLock then
		warn("[Data] Trava perdida para outro servidor: " .. player.Name .. ". Parando de salvar aqui.")
		profile.Released = true
		if player.Parent == Players then
			player:Kick("Sua conta foi aberta em outro servidor.")
		end
		return false
	end
	if release and saved then
		profile.Released = true
	end
	return saved
end

--------------------------------------------------------------------------
-- API pública
--------------------------------------------------------------------------
function DataService.IsLoaded(player: Player): boolean
	local p = profiles[player]
	return p ~= nil and p.Loaded and not p.Released
end

-- Dados do jogador (somente no servidor). Retorna nil se ainda não carregou.
function DataService.Get(player: Player): { [string]: any }?
	local p = profiles[player]
	if p and p.Loaded and not p.Released then
		return p.Data
	end
	return nil
end

-- Gera um código único dentro do perfil (dragões, equipamentos).
function DataService.NewUid(player: Player, prefix: string): string?
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local n = tonumber(data.NextUid) or 1
	data.NextUid = n + 1
	return prefix .. tostring(n)
end

function DataService.IsUsingMemoryStore(): boolean
	return usingMock
end

function DataService.Init()
	store = pickStore()

	Players.PlayerAdded:Connect(function(player)
		loadProfile(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadProfile, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if profiles[player] then
			DataService.Save(player, true)
			profiles[player] = nil
		end
	end)

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player, profile in pairs(profiles) do
				if profile.Loaded and not profile.Released then
					task.spawn(DataService.Save, player, false)
					task.wait(0.5) -- espalha as chamadas
				end
			end
		end
	end)

	-- Fechamento do servidor: salva todos e libera as travas.
	game:BindToClose(function()
		local pending = 0
		for player, profile in pairs(profiles) do
			if profile.Loaded and not profile.Released then
				pending += 1
				task.spawn(function()
					DataService.Save(player, true)
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
