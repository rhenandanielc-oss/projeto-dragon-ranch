--!strict
-- Consultas rápidas sobre o mapa em tempo de jogo (usa ServerStorage.WorldGen.WorldData).
-- Coordenadas do mapa: x = leste, y = norte. No Roblox: X = x, Z = -y.

local ServerStorage = game:GetService("ServerStorage")

local WorldQuery = {}

local data: any = nil
local function D(): any
	if data == nil then
		local wg = ServerStorage:FindFirstChild("WorldGen")
		local m = wg and wg:FindFirstChild("WorldData")
		data = if m then require(m :: any) else false
	end
	return data
end

function WorldQuery.Data(): any
	local d = D()
	return if d then d else nil
end

local function inPolygon(x: number, y: number, pts: { { number } }): boolean
	local inside = false
	local j = #pts
	for i = 1, #pts do
		local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
		if (yi > y) ~= (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
			inside = not inside
		end
		j = i
	end
	return inside
end
WorldQuery.InPolygon = inPolygon

-- Região mais específica no ponto (a última da lista que contém o ponto vence: sub-regiões vêm depois).
function WorldQuery.RegionAt(pos: Vector3): any?
	local d = D()
	if not d then
		return nil
	end
	local x, y = pos.X, -pos.Z
	local found = nil
	for _, r in ipairs(d.REGIONS) do
		if inPolygon(x, y, r.pts) then
			found = r
		end
	end
	return found
end

-- Zonas protegidas: Hub, fazendas e acampamentos (inimigos não entram nem nascem ali).
function WorldQuery.IsSafe(pos: Vector3): boolean
	local d = D()
	if not d then
		return false
	end
	local x, y = pos.X, -pos.Z
	local h = d.HUB
	if (x - h.x) ^ 2 + (y - h.y) ^ 2 < (h.r1 + 40) ^ 2 then
		return true
	end
	local fr = (d.FARM_R1 or 330) + 20
	for _, f in ipairs(d.FARMS) do
		if (x - f.x) ^ 2 + (y - f.y) ^ 2 < fr * fr then
			return true
		end
	end
	local cr = d.CAMP_R1 or 160
	for _, c in ipairs(d.CAMPS) do
		if (x - c.x) ^ 2 + (y - c.y) ^ 2 < cr * cr then
			return true
		end
	end
	return false
end

-- Zona perigosa = região marcada danger no WorldData.
function WorldQuery.IsDanger(pos: Vector3): boolean
	local r = WorldQuery.RegionAt(pos)
	return r ~= nil and r.danger == true and not WorldQuery.IsSafe(pos)
end

return WorldQuery
