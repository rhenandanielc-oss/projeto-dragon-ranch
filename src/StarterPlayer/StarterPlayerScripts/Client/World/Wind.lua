--!strict
-- Vento no cliente: copas das árvores, arbustos e samambaias balançam perto da câmera.
-- As peças são marcadas pelo construtor do mundo (tags "WindLeaf" e "WindBush", atributos
-- SwayBase = base da planta e SwayH = altura). Só o cliente move as peças; o servidor não muda.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Wind = {}

type Item = { part: BasePart, orig: CFrame, base: Vector3, h: number, phase: number, bush: boolean }

local items: { [BasePart]: Item } = {}
local active: { Item } = {}
local enabled = true
local RADIUS = 260 -- studs: além disso o movimento não é perceptível
local strength = 1

local function add(inst: Instance, bush: boolean)
	if not inst:IsA("BasePart") or items[inst] then
		return
	end
	local base = inst:GetAttribute("SwayBase")
	local h = inst:GetAttribute("SwayH")
	if typeof(base) ~= "Vector3" or type(h) ~= "number" then
		return
	end
	items[inst] = {
		part = inst,
		orig = inst.CFrame,
		base = base,
		h = h,
		phase = (base.X * 0.013 + base.Z * 0.017) % (math.pi * 2),
		bush = bush,
	}
end

local function remove(inst: Instance)
	local it = items[inst :: BasePart]
	if it then
		items[inst :: BasePart] = nil
	end
end

local function restoreAll()
	local parts, cfs = {}, {}
	for _, it in ipairs(active) do
		if it.part.Parent then
			table.insert(parts, it.part)
			table.insert(cfs, it.orig)
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function Wind.SetEnabled(on: boolean)
	if not on and enabled then
		restoreAll()
		table.clear(active)
	end
	enabled = on
end

function Wind.Init()
	for _, tag in ipairs({ "WindLeaf", "WindBush" }) do
		local bush = tag == "WindBush"
		for _, inst in ipairs(CollectionService:GetTagged(tag)) do
			add(inst, bush)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
			add(inst, bush)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
	end

	-- a lista de peças perto da câmera é refeita a cada 0,5 s
	task.spawn(function()
		while true do
			task.wait(0.5)
			if enabled then
				local cam = workspace.CurrentCamera
				if cam then
					local cp = cam.CFrame.Position
					local list = {}
					local r2 = RADIUS * RADIUS
					for _, it in pairs(items) do
						local d = it.base - cp
						if d.X * d.X + d.Z * d.Z < r2 then
							table.insert(list, it)
						end
					end
					-- quem saiu do raio volta à posição original
					local keep = {}
					for _, it in ipairs(list) do
						keep[it] = true
					end
					local parts, cfs = {}, {}
					for _, it in ipairs(active) do
						if not keep[it] and it.part.Parent then
							table.insert(parts, it.part)
							table.insert(cfs, it.orig)
						end
					end
					if #parts > 0 then
						workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
					end
					active = list
				end
			end
		end
	end)

	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		if not enabled or #active == 0 then
			return
		end
		t += dt
		-- rajadas: força do vento varia devagar
		strength = 0.75 + 0.35 * math.sin(t * 0.37) + 0.15 * math.sin(t * 1.3)
		local parts = table.create(#active)
		local cfs = table.create(#active)
		for _, it in ipairs(active) do
			local p = it.part
			if p.Parent then
				local ph = it.phase
				local ax, az
				if it.bush then
					ax = math.rad(4) * strength * math.sin(t * 2.1 + ph)
					az = math.rad(3) * strength * math.sin(t * 1.7 + ph * 1.3)
				else
					-- árvores altas balançam menos em ângulo
					local k = math.clamp(30 / it.h, 0.25, 1)
					ax = math.rad(1.6) * k * strength * (math.sin(t * 1.1 + ph) + 0.35 * math.sin(t * 2.9 + ph * 2))
					az = math.rad(1.2) * k * strength * (math.sin(t * 0.9 + ph * 1.7) + 0.3 * math.sin(t * 3.3 + ph))
				end
				local pivot = CFrame.new(it.base)
				table.insert(parts, p)
				table.insert(cfs, pivot * CFrame.Angles(ax, 0, az) * pivot:Inverse() * it.orig)
			end
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

return Wind
