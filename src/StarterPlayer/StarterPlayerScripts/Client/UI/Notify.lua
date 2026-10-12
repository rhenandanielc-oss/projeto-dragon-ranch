--!strict
-- Avisos curtos no topo da tela.

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)

local Notify = {}

local container: Frame

function Notify.Init(screen: ScreenGui)
	container = Theme.new("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.new(0.9, 0, 0.4, 0),
		Parent = screen,
	}, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		Theme.new("UISizeConstraint", { MaxSize = Vector2.new(520, math.huge) }),
	})
end

local order = 0
function Notify.Show(text: string, kind: string?)
	if not container then
		return
	end
	order += 1
	local color = Theme.Colors.PanelLight
	local strokeColor = Theme.Colors.Stroke
	if kind == "success" then
		strokeColor = Theme.Colors.Good
	elseif kind == "warning" then
		strokeColor = Theme.Colors.Warn
	elseif kind == "error" then
		strokeColor = Theme.Colors.Bad
	end
	local toast = Theme.new("TextLabel", {
		LayoutOrder = order,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Theme.BoldFont,
		TextSize = 17,
		TextWrapped = true,
		TextColor3 = Theme.Colors.Text,
		Text = text,
		Parent = container,
	}, { Theme.corner(10), Theme.stroke(strokeColor, 2), Theme.padding(10) })
	task.delay(4, function()
		local tween = TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		toast:Destroy()
	end)
	-- no máximo 4 avisos ao mesmo tempo
	local toasts = {}
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("TextLabel") then
			table.insert(toasts, c)
		end
	end
	if #toasts > 4 then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end
end

return Notify
