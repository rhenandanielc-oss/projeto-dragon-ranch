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
end)

NetClient.On("ProfileChanged", function(key: string, value: any)
	State.Set(key, value)
end)

NetClient.On("Notify", function(text: string, kind: string?)
	Notify.Show(text, kind)
end)

NetClient.Fire("ClientReady")
