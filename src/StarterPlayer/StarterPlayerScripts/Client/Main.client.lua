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
local Wind = require(Client:WaitForChild("World"):WaitForChild("Wind"))

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

NetClient.On("FarmChooser", function(free: { string }, current: string, canChoose: boolean)
	FarmChooser.Open(free, current, canChoose)
end)

NetClient.Fire("ClientReady")
