--!native
--!optimize 2
-- Escreve o relevo do WorldGen no Terrain do Studio, em blocos de 256 x 256 studs.
-- Roda em segundo plano (task.spawn) e publica o progresso em atributos da pasta WorldGen:
--   TerrainProgress (blocos feitos), TerrainTotal, TerrainStatus ("running" | "done" | "error: ...")

local TerrainWriter = {}

local CHUNK = 64 -- colunas por lado (64 x 4 = 256 studs)
local VOX = 4

local function materialEnums(WorldGen)
	local map = {}
	for id, name in pairs(WorldGen.MATERIAL_NAMES) do
		map[id] = (Enum.Material :: any)[name]
	end
	return map
end

-- Escreve um bloco; ci, cj = índices do bloco (0..)
function TerrainWriter.writeChunk(gen, WorldGen, mats, ci: number, cj: number)
	local data = gen.data
	local half = data.SIZE / 2
	local x0 = -half + ci * CHUNK * VOX
	local y0 = -half + cj * CHUNK * VOX
	-- amostra no centro de cada voxel
	local c = gen:computeChunk(x0 + VOX / 2, y0 + VOX / 2, CHUNK)
	local W = c.W
	local hA, wlA, matA, subA = c.h, c.wl, c.mat, c.sub
	local lo, hi = math.huge, -math.huge
	for j = 1, CHUNK do
		for i = 1, CHUNK do
			local idx = j * W + i + 1
			local h = hA[idx]
			if h < lo then lo = h end
			local top = math.max(h, wlA[idx])
			if top > hi then hi = top end
		end
	end
	local yMin = math.floor((lo - 16) / VOX) * VOX
	local yMax = math.ceil((hi + 2) / VOX) * VOX
	local ny = (yMax - yMin) // VOX
	local rock = Enum.Material.Rock
	local air = Enum.Material.Air
	local solidMat, solidOcc, liquidOcc = table.create(CHUNK), table.create(CHUNK), table.create(CHUNK)
	for kx = 1, CHUNK do
		local mx, ox, lx = table.create(ny), table.create(ny), table.create(ny)
		for ky = 1, ny do
			mx[ky], ox[ky], lx[ky] = table.create(CHUNK, air), table.create(CHUNK, 0), table.create(CHUNK, 0)
		end
		solidMat[kx], solidOcc[kx], liquidOcc[kx] = mx, ox, lx
		local i = kx -- coluna i (1..CHUNK) na borda +1
		for kz = 1, CHUNK do
			-- Z do Roblox cresce para o sul; kz = 1 é o lado norte do bloco
			local j = CHUNK - kz + 1
			local idx = j * W + i + 1
			local h = hA[idx]
			local wl = wlA[idx]
			local surf = mats[matA[idx]]
			local sub = mats[subA[idx]]
			for ky = 1, ny do
				local yb = yMin + (ky - 1) * VOX
				local occ = (h - yb) / VOX
				if occ > 0.04 then
					if occ > 1 then occ = 1 end
					local depth = h - yb - VOX
					mx[ky][kz] = if depth < 5 then surf elseif depth < 14 then sub else rock
					ox[ky][kz] = occ
				end
				if wl > yb then
					local liq = (wl - yb) / VOX
					if liq > 1 then liq = 1 end
					if liq > 0.04 then
						lx[ky][kz] = liq
					end
				end
				if yb > h and yb > wl then
					break
				end
			end
		end
	end
	local region = Region3.new(Vector3.new(x0, yMin, -(y0 + CHUNK * VOX)), Vector3.new(x0 + CHUNK * VOX, yMax, -y0))
	workspace.Terrain:WriteVoxelChannels(region, VOX, { SolidMaterial = solidMat, SolidOccupancy = solidOcc, LiquidOccupancy = liquidOcc })
	-- limpa terreno antigo acima do novo (quando o relevo baixou, ex.: a baía)
	local clearTo = TerrainWriter.ClearTo
	if clearTo and clearTo > yMax then
		local span = CHUNK * VOX
		workspace.Terrain:FillBlock(CFrame.new(x0 + span / 2, (yMax + clearTo) / 2, -(y0 + span / 2)), Vector3.new(span, clearTo - yMax, span), Enum.Material.Air)
	end
	return ny
end

-- Blocos que cobrem um círculo do mapa (x, y, raio): devolve índices lineares
function TerrainWriter.chunksAround(size: number, x: number, y: number, r: number): { number }
	local per = math.floor(size / (CHUNK * VOX) + 0.5)
	local span = CHUNK * VOX
	local list = {}
	for ci = math.floor((x - r + size / 2) / span), math.floor((x + r + size / 2) / span) do
		for cj = math.floor((y - r + size / 2) / span), math.floor((y + r + size / 2) / span) do
			if ci >= 0 and cj >= 0 and ci < per and cj < per then
				table.insert(list, cj * per + ci)
			end
		end
	end
	return list
end

-- Gera o mundo inteiro (ou os blocos de first..last na ordem linear, ou a lista `only`) em segundo plano
TerrainWriter.ClearTo = nil :: number?

function TerrainWriter.start(folder: Instance, first: number?, last: number?, only: { number }?, clearTo: number?)
	TerrainWriter.ClearTo = clearTo
	local WorldData = require(folder:FindFirstChild("WorldData"):Clone())
	local WorldGen = require(folder:FindFirstChild("WorldGen"):Clone())
	local per = math.floor(WorldData.SIZE / (CHUNK * VOX) + 0.5)
	local total = per * per
	first = first or 0
	last = last or total - 1
	local order = {}
	if only then
		order = only
	else
		for k = first :: number, last :: number do
			table.insert(order, k)
		end
	end
	folder:SetAttribute("TerrainTotal", #order)
	folder:SetAttribute("TerrainProgress", 0)
	folder:SetAttribute("TerrainStatus", "building grid")
	task.spawn(function()
		local ok, err = pcall(function()
			local gen = WorldGen.new(WorldData, function()
				task.wait()
			end)
			local mats = materialEnums(WorldGen)
			folder:SetAttribute("TerrainStatus", "running")
			local t0 = os.clock()
			local budget = os.clock()
			for n, k in ipairs(order) do
				if folder:GetAttribute("TerrainCancel") then
					folder:SetAttribute("TerrainStatus", "cancelled at " .. k)
					return
				end
				local ci = k % per
				local cj = k // per
				TerrainWriter.writeChunk(gen, WorldGen, mats, ci, cj)
				folder:SetAttribute("TerrainProgress", n)
				if os.clock() - budget > 0.25 then
					task.wait()
					budget = os.clock()
				end
			end
			folder:SetAttribute("TerrainSeconds", math.floor(os.clock() - t0))
			folder:SetAttribute("TerrainStatus", "done")
		end)
		if not ok then
			folder:SetAttribute("TerrainStatus", "error: " .. tostring(err))
		end
	end)
	return total
end

return TerrainWriter
