--!strict
-- Ponto de entrada do cliente.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Client = script.Parent

local NetClient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("NetClient"))
local State = require(Client:WaitForChild("State"))
local UI = Client:WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local Notify = require(UI:WaitForChild("Notify"))
local StarterChooser = require(UI:WaitForChild("StarterChooser"))
local DragonPanel = require(UI:WaitForChild("DragonPanel"))
local Dialog = require(UI:WaitForChild("Dialog"))
local FarmChooser = require(UI:WaitForChild("FarmChooser"))
local Compass = require(UI:WaitForChild("Compass"))
local GraphicsSettings = require(UI:WaitForChild("GraphicsSettings"))
local InventoryPanel = require(UI:WaitForChild("InventoryPanel"))
local ShopPanel = require(UI:WaitForChild("ShopPanel"))
local TravelPanel = require(UI:WaitForChild("TravelPanel"))
local Wind = require(Client:WaitForChild("World"):WaitForChild("Wind"))
local MountController = require(Client:WaitForChild("Dragon"):WaitForChild("MountController"))
local CombatFolder = Client:WaitForChild("Combat")
local Fx = require(CombatFolder:WaitForChild("Fx"))
local CombatController = require(CombatFolder:WaitForChild("CombatController"))
local CombatHud = require(UI:WaitForChild("CombatHud"))

-- Tela principal
local screen = Theme.new("ScreenGui", {
	Name = "DragonRanchUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

Notify.Init(screen)
DragonPanel.Init(screen)
StarterChooser.Init(screen)
Dialog.Init(screen)
FarmChooser.Init(screen)
Compass.Init(screen)
Wind.Init()
GraphicsSettings.Init(screen)
InventoryPanel.Init(screen)
ShopPanel.Init(screen)
TravelPanel.Init(screen)
MountController.Init()
Fx.Init()
CombatController.Init(MountController.IsMounted)
CombatHud.Init(screen, CombatController.Charging)

-- Cada jogador só vê as ações dos próprios dragões.
local function filterPrompt(inst: Instance)
	if inst:IsA("ProximityPrompt") then
		local owner = inst:GetAttribute("OwnerUserId")
		if owner ~= nil and owner ~= player.UserId then
			inst.Enabled = false
		end
	end
end
for _, d in ipairs(workspace:GetDescendants()) do
	filterPrompt(d)
end
workspace.DescendantAdded:Connect(filterPrompt)

-- Dados do servidor
NetClient.On("ProfileSnapshot", function(data: { [string]: any })
	State.SetAll(data)
	local saved = type(data.Settings) == "table" and data.Settings.Graphics or ""
	if type(saved) == "string" and saved ~= "" and saved ~= GraphicsSettings.Current() then
		GraphicsSettings.Apply(saved)
	end
end)

NetClient.On("ProfileChanged", function(key: string, value: any)
	State.Set(key, value)
end)

NetClient.On("Notify", function(text: string, kind: string?)
	Notify.Show(text, kind)
end)

NetClient.On("NpcDialog", function(npcId: string)
	Dialog.Open(npcId)
end)

NetClient.On("OpenStorage", function()
	InventoryPanel.OpenStorage()
end)

NetClient.On("Fx", function(kind: string, data: { [string]: any })
	Fx.Play(kind, data)
end)

NetClient.On("SkillUsed", function(name: string, cooldown: number)
	CombatHud.SkillUsed(name, cooldown)
end)

NetClient.On("DragonPowers", function(unlocked: { [string]: any }, canFight: boolean)
	CombatHud.SetDragonPowers(unlocked, canFight)
end)

NetClient.On("OpenShop", function()
	ShopPanel.Open()
end)

NetClient.On("OpenWaypoints", function(currentId: number, dests: { any })
	TravelPanel.Open(currentId, dests)
end)

NetClient.On("ChannelStarted", function(seconds: number, text: string)
	TravelPanel.Channel(seconds, text)
end)

NetClient.On("FarmChooser", function(free: { string }, current: string, canChoose: boolean)
	FarmChooser.Open(free, current, canChoose)
end)

NetClient.Fire("ClientReady")
