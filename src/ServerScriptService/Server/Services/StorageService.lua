--!strict
-- Fase 4: armazém da fazenda (baú de 100 espaços, seguro contra PvP) e pedidos da mochila.
-- Guardar/retirar só funciona perto do baú da PRÓPRIA fazenda (conferido no servidor).

local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService.Server
local NetService = require(Server.Services.NetService)
local FarmService = require(Server.Services.FarmService)
local InventoryService = require(Server.Services.InventoryService)
local GatherService = require(Server.Services.GatherService)


local StorageService = {}

local CHEST_DISTANCE = 16

local function notify(player: Player, text: string, kind: string?)
	NetService.Fire(player, "Notify", text, kind or "info")
end

local function chestOf(player: Player): BasePart?
	local plot = FarmService.GetPlot(player)
	local chest = plot and plot:FindFirstChild("StorageChest")
	return if chest and chest:IsA("BasePart") then chest else nil
end

local function nearChest(player: Player): boolean
	local chest = chestOf(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	return chest ~= nil and hrp ~= nil and (hrp.Position - chest.Position).Magnitude <= CHEST_DISTANCE
end

local function setupPlot(player: Player)
	local plot = FarmService.GetPlot(player)
	if not plot then
		return
	end
	GatherService.SetupFarm(player, plot)
	local chest = chestOf(player)
	if not chest then
		return
	end
	local old = chest:FindFirstChild("OpenStorage")
	if old then
		old:Destroy()
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenStorage"
	prompt.ActionText = "Abrir armazém"
	prompt.ObjectText = "Baú da fazenda"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OwnerUserId", player.UserId)
	prompt.Parent = chest
	prompt.Triggered:Connect(function(who: Player)
		if who == player and nearChest(player) then
			NetService.Fire(player, "OpenStorage")
		end
	end)
end

function StorageService.Init()
	FarmService.PlotAssigned:Connect(setupPlot)
	FarmService.PlotReleasing:Connect(function(player: Player)
		local chest = chestOf(player)
		local prompt = chest and chest:FindFirstChild("OpenStorage")
		if prompt then
			prompt:Destroy()
		end
	end)

	NetService.On("StorageDeposit", function(player: Player, slotIndex: number, count: number)
		if not nearChest(player) then
			notify(player, "Vá até o baú da sua fazenda.")
			return
		end
		local ok, msg = InventoryService.Deposit(player, slotIndex, count)
		if not ok and msg then
			notify(player, msg, "warning")
		end
	end)
	NetService.On("StorageWithdraw", function(player: Player, slotIndex: number, count: number)
		if not nearChest(player) then
			notify(player, "Vá até o baú da sua fazenda.")
			return
		end
		local ok, msg = InventoryService.Withdraw(player, slotIndex, count)
		if not ok and msg then
			notify(player, msg, "warning")
		end
	end)
	NetService.On("DiscardItem", function(player: Player, slotIndex: number, count: number)
		InventoryService.Discard(player, slotIndex, count)
	end)
	NetService.On("ExpandBackpack", function(player: Player)
		local ok, msg = InventoryService.ExpandBackpack(player)
		if msg ~= "" then
			notify(player, msg, if ok then "success" else "warning")
		end
	end)
	NetService.On("SetHotbar", function(player: Player, index: number, itemId: string)
		InventoryService.SetHotbar(player, index, itemId)
	end)
end

return StorageService
