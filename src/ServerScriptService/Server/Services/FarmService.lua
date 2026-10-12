--!strict
-- Atribui uma fazenda a cada jogador ao entrar (até 18 por servidor) e o leva para ela ao nascer.
-- Regra aprovada (WORLD-DESIGN D3):
--   * quem ainda não tem dragão Jovem (ou maior) recebe a fazenda livre mais próxima do Hub;
--   * quem já tem pode escolher um bioma livre de sua preferência (salvo no perfil).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Growth = require(ReplicatedStorage.Shared.Config.Growth)
local Rules = require(ReplicatedStorage.Shared.Config.Rules)

local FarmService = {}

local plotsFolder: Folder
local plotOf: { [Player]: Model } = {}
local lastMove: { [Player]: number } = {}

local assignedEvent = Instance.new("BindableEvent")
FarmService.PlotAssigned = assignedEvent.Event -- (player, plot)
local releasingEvent = Instance.new("BindableEvent")
FarmService.PlotReleasing = releasingEvent.Event -- (player, plot)

local MOVE_COOLDOWN = Rules.World.FarmMoveCooldownSeconds

local function setSign(plot: Model, text: string)
	local sign = plot:FindFirstChild("Sign")
	if not sign then
		return
	end
	for _, gui in ipairs(sign:GetChildren()) do
		local label = gui:FindFirstChild("Owner")
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end
end

local function spawnCFrame(plot: Model): CFrame?
	local base = plot:FindFirstChild("Base")
	local att = base and base:FindFirstChild("Spawn")
	if att and att:IsA("Attachment") then
		return att.WorldCFrame
	end
	return nil
end

local function moveToFarm(player: Player, character: Model)
	local plot = plotOf[player]
	if not plot then
		return
	end
	local cf = spawnCFrame(plot)
	if not cf then
		return
	end
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		task.wait() -- deixa o personagem terminar de montar
		player:RequestStreamAroundAsync(cf.Position, 5)
		character:PivotTo(cf + Vector3.new(0, 3, 0))
	end
end

local function hubDistance(plot: Model): number
	local base = plot:FindFirstChild("Base") :: BasePart?
	if not base then
		return math.huge
	end
	local hub = Rules.World.HubPosition
	return (Vector3.new(base.Position.X, 0, base.Position.Z) - Vector3.new(hub.X, 0, hub.Z)).Magnitude
end

local function isFree(plot: Instance): boolean
	return plot:IsA("Model") and (plot:GetAttribute("OwnerUserId") or 0) == 0
end

-- Jogador "avançado": tem ao menos um dragão Jovem ou maior
function FarmService.IsAdvanced(data: { [string]: any }?): boolean
	if not data or type(data.Dragons) ~= "table" then
		return false
	end
	local young = Growth.StageIndex("Young")
	for _, d in pairs(data.Dragons) do
		if type(d) == "table" and type(d.Stage) == "string" and Growth.StageIndex(d.Stage) >= young then
			return true
		end
	end
	return false
end

local function freePlotsByDistance(): { Model }
	local list = {}
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if isFree(plot) then
			table.insert(list, plot :: Model)
		end
	end
	table.sort(list, function(a, b)
		return hubDistance(a) < hubDistance(b)
	end)
	return list
end

-- Biomas que têm fazenda livre agora (para a tela de escolha)
function FarmService.FreeBiomes(): { string }
	local seen, out = {}, {}
	for _, plot in ipairs(freePlotsByDistance()) do
		local b = plot:GetAttribute("Biome")
		if type(b) == "string" and not seen[b] then
			seen[b] = true
			table.insert(out, b)
		end
	end
	return out
end

function FarmService.GetPlot(player: Player): Model?
	return plotOf[player]
end

local function take(player: Player, plot: Model)
	plot:SetAttribute("OwnerUserId", player.UserId)
	-- posição da fazenda para a bússola do cliente (o modelo pode não estar carregado no cliente)
	local base = plot:FindFirstChild("Base") :: BasePart?
	if base then
		player:SetAttribute("FarmPosition", base.Position)
	end
	setSign(plot, "Fazenda de " .. player.DisplayName)
	plotOf[player] = plot
	assignedEvent:Fire(player, plot)
	if player.Character then
		task.spawn(moveToFarm, player, player.Character)
	end
end

function FarmService.Assign(player: Player, data: { [string]: any }?): Model?
	if plotOf[player] then
		return plotOf[player]
	end
	local free = freePlotsByDistance()
	if #free == 0 then
		warn("[Farm] Nenhum terreno livre para " .. player.Name)
		return nil
	end
	local chosen = free[1] -- o mais próximo do Hub
	if FarmService.IsAdvanced(data) and data then
		local farmData = data.Farm
		local want = type(farmData) == "table" and farmData.PreferredBiome or nil
		if type(want) == "string" and want ~= "" then
			for _, plot in ipairs(free) do
				if plot:GetAttribute("Biome") == want then
					chosen = plot
					break
				end
			end
		end
	end
	take(player, chosen)
	return chosen
end

function FarmService.Release(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	releasingEvent:Fire(player, plot)
	plotOf[player] = nil
	player:SetAttribute("FarmPosition", nil)
	plot:SetAttribute("OwnerUserId", 0)
	setSign(plot, "Fazenda livre")
end

-- Pedido do jogador para trocar de bioma (já validado pelo NetService quanto ao formato).
-- Devolve (ok, mensagem).
function FarmService.ChooseBiome(player: Player, data: { [string]: any }?, biome: string): (boolean, string)
	if not data then
		return false, "Perfil ainda não carregou."
	end
	if not FarmService.IsAdvanced(data) then
		return false, "Escolher o bioma da fazenda libera quando um dragão seu ficar Jovem."
	end
	local now = os.clock()
	if lastMove[player] and now - lastMove[player] < MOVE_COOLDOWN then
		return false, "Espere um pouco antes de mudar de fazenda de novo."
	end
	local current = plotOf[player]
	if current and current:GetAttribute("Biome") == biome then
		data.Farm.PreferredBiome = biome
		return true, "Sua fazenda já está nesse bioma."
	end
	local target: Model? = nil
	for _, plot in ipairs(freePlotsByDistance()) do
		if plot:GetAttribute("Biome") == biome then
			target = plot
			break
		end
	end
	data.Farm.PreferredBiome = biome -- vale também para os próximos servidores
	if not target then
		return false, "Não há fazenda livre nesse bioma neste servidor. Ela será usada quando houver."
	end
	lastMove[player] = now
	FarmService.Release(player)
	take(player, target :: Model)
	return true, "Fazenda mudou para " .. tostring(target:GetAttribute("FarmName")) .. "."
end

function FarmService.Init()
	plotsFolder = workspace:WaitForChild("Farms") :: Folder
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		plot:SetAttribute("OwnerUserId", 0)
		setSign(plot :: Model, "Fazenda livre")
	end

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			moveToFarm(player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		FarmService.Release(player)
		lastMove[player] = nil
	end)
end

return FarmService
