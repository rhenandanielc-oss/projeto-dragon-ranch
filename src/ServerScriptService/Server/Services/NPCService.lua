--!strict
-- Cria os NPCs do Hub nos marcadores de workspace.Hub.NPCs e abre a conversa ao interagir.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NPCs = require(ReplicatedStorage.Shared.Config.NPCs)
local NetService = require(ServerScriptService.Server.Services.NetService)
local ShopService = require(ServerScriptService.Server.Services.ShopService)
local QuestService = require(ServerScriptService.Server.Services.QuestService)

local NPCService = {}

local function buildNpc(marker: BasePart, id: string, def: any): Model?
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = def.Body.Skin
	desc.LeftArmColor = def.Body.Skin
	desc.RightArmColor = def.Body.Skin
	desc.TorsoColor = def.Body.Shirt
	desc.LeftLegColor = def.Body.Pants
	desc.RightLegColor = def.Body.Pants
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[NPC] Não foi possível criar " .. id .. ": " .. tostring(model))
		return nil
	end
	local npc = model :: Model
	npc.Name = "NPC_" .. id
	local humanoid = npc:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local hrp = npc:FindFirstChild("HumanoidRootPart") :: BasePart
	hrp.Anchored = true
	npc:PivotTo(marker.CFrame + Vector3.new(0, 2.6, 0))
	npc:SetAttribute("NpcId", id)

	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(200, 50)
	tag.StudsOffset = Vector3.new(0, 3.4, 0)
	tag.MaxDistance = 70
	tag.Parent = hrp
	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.6)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.4
	name.Text = def.Name
	name.Parent = tag
	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromScale(0, 0.6)
	title.Size = UDim2.fromScale(1, 0.4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(240, 170, 60)
	title.TextStrokeTransparency = 0.5
	title.Text = def.Title
	title.Parent = tag

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Talk"
	prompt.ActionText = "Conversar"
	prompt.ObjectText = def.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp
	prompt.Triggered:Connect(function(player: Player)
		NetService.Fire(player, "NpcDialog", id)
	end)
	if id == "QuestMaster" then
		local q = Instance.new("ProximityPrompt")
		q.Name = "Quests"
		q.ActionText = "Ver missões"
		q.ObjectText = def.Name
		q.KeyboardKeyCode = Enum.KeyCode.R
		q.UIOffset = Vector2.new(0, -72)
		q.MaxActivationDistance = 12
		q.RequiresLineOfSight = false
		q.Parent = hrp
		q.Triggered:Connect(function(player: Player)
			QuestService.Open(player)
		end)
	end
	if id == "Merchant" then
		local shop = Instance.new("ProximityPrompt")
		shop.Name = "Shop"
		shop.ActionText = "Comprar e vender"
		shop.ObjectText = def.Name
		shop.KeyboardKeyCode = Enum.KeyCode.R
		shop.UIOffset = Vector2.new(0, -72)
		shop.MaxActivationDistance = 12
		shop.RequiresLineOfSight = false
		shop.Parent = hrp
		shop.Triggered:Connect(function(player: Player)
			ShopService.Open(player)
		end)
	end

	npc.Parent = marker.Parent
	return npc
end

function NPCService.Init()
	local hub = workspace:FindFirstChild("Hub")
	local folder = hub and hub:FindFirstChild("NPCs")
	if not folder then
		warn("[NPC] workspace.Hub.NPCs não encontrado")
		return
	end
	for _, marker in ipairs(folder:GetChildren()) do
		local id = marker:GetAttribute("NpcId")
		if marker:IsA("BasePart") and type(id) == "string" and NPCs[id] then
			buildNpc(marker, id, NPCs[id])
		end
	end
end

return NPCService
