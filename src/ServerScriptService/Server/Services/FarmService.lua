--!strict
-- Atribui um terreno de fazenda a cada jogador ao entrar (até 18 por servidor)
-- e o leva para a sua fazenda ao nascer.

local Players = game:GetService("Players")

local FarmService = {}

local plotsFolder: Folder
local plotOf: { [Player]: Model } = {}

local assignedEvent = Instance.new("BindableEvent")
FarmService.PlotAssigned = assignedEvent.Event -- (player, plot)
local releasingEvent = Instance.new("BindableEvent")
FarmService.PlotReleasing = releasingEvent.Event -- (player, plot)

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
		-- o attachment já aponta para dentro da fazenda
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
		character:PivotTo(cf + Vector3.new(0, 3, 0))
	end
end

function FarmService.GetPlot(player: Player): Model?
	return plotOf[player]
end

function FarmService.Assign(player: Player): Model?
	if plotOf[player] then
		return plotOf[player]
	end
	local free: Model? = nil
	local plots = plotsFolder:GetChildren()
	table.sort(plots, function(a, b)
		return (a:GetAttribute("PlotIndex") or 99) < (b:GetAttribute("PlotIndex") or 99)
	end)
	for _, plot in ipairs(plots) do
		if plot:IsA("Model") and (plot:GetAttribute("OwnerUserId") or 0) == 0 then
			free = plot
			break
		end
	end
	if not free then
		warn("[Farm] Nenhum terreno livre para " .. player.Name)
		return nil
	end
	local plot = free :: Model
	plot:SetAttribute("OwnerUserId", player.UserId)
	setSign(plot, "Fazenda de " .. player.DisplayName)
	plotOf[player] = plot
	assignedEvent:Fire(player, plot)
	if player.Character then
		task.spawn(moveToFarm, player, player.Character)
	end
	return plot
end

function FarmService.Release(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	releasingEvent:Fire(player, plot)
	plotOf[player] = nil
	plot:SetAttribute("OwnerUserId", 0)
	setSign(plot, "Fazenda livre")
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
	Players.PlayerRemoving:Connect(FarmService.Release)
end

return FarmService
