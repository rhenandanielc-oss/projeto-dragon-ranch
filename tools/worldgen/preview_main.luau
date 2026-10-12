-- Prévia do relevo: escreve um PPM (altura sombreada + materiais) em stdout-arquivo
local STEP = tonumber(PREVIEW_STEP) or 16
local gen = WorldGen.new(WorldData)
local AREA = tonumber(PREVIEW_AREA) or WorldData.SIZE
local CX, CY = tonumber(PREVIEW_CX) or 0, tonumber(PREVIEW_CY) or 0
local half = AREA / 2
local N = math.floor(AREA / STEP)
local CH = 50
local H = table.create(N * N, 0)
local WL = table.create(N * N, -1e9)
local MAT = table.create(N * N, 1)
local t0 = os.clock()
for cj = 0, N / CH - 1 do
	for ci = 0, N / CH - 1 do
		local x0 = CX - half + ci * CH * STEP
		local y0 = CY - half + cj * CH * STEP
		local c = gen:computeChunk(x0, y0, CH, STEP)
		for j = 0, CH - 1 do
			for i = 0, CH - 1 do
				local src = (j + 1) * c.W + (i + 1) + 1
				local dst = (cj * CH + j) * N + (ci * CH + i) + 1
				H[dst] = c.h[src]
				WL[dst] = c.wl[src]
				MAT[dst] = c.mat[src]
			end
		end
	end
end
local TIMING = string.format("# computed %d cols in %.1fs", N * N, os.clock() - t0)
-- saída binária simples: N, depois float h, float wl, byte mat por coluna (texto para facilitar)
local out = {}
table.insert(out, TIMING)
table.insert(out, tostring(N))
for k = 1, N * N do
	out[#out + 1] = string.format("%.1f %.1f %d", H[k], WL[k] > -1e8 and WL[k] or -999, MAT[k])
end
print(table.concat(out, "\n"))
