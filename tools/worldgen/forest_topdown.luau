-- Saída por célula de 30 studs: tipo de região, ruído da floresta, altura natural, exclusão (1 = área de jogo, 2 = estrada)
local g = WorldGen.new(WorldData)
local D = WorldData
local function segd(px, py, ax, ay, bx, by)
	local dx, dy = bx - ax, by - ay
	local l = dx * dx + dy * dy
	local t = l > 0 and math.clamp(((px - ax) * dx + (py - ay) * dy) / l, 0, 1) or 0
	local qx, qy = ax + dx * t - px, ay + dy * t - py
	return math.sqrt(qx * qx + qy * qy)
end
local segs = {}
for _, r in ipairs(D.ROADS) do
	for i = 1, #r - 1 do
		table.insert(segs, { r[i][1], r[i][2], r[i + 1][1], r[i + 1][2] })
	end
end
local function excluded(x, y)
	for _, p in ipairs(g.pads) do
		local dx, dy = x - p.x, y - p.y
		local r = p.kind == "farm" and p.r1 + 15 or p.kind == "hub" and p.r1 + 30 or p.r1
		if dx * dx + dy * dy < r * r then
			return 1
		end
	end
	for _, s in ipairs(segs) do
		if segd(x, y, s[1], s[2], s[3], s[4]) < 16 then
			return 2
		end
	end
	return 0
end
local out = {}
local half = D.SIZE / 2
for y = -half, half - 1, 30 do
	for x = -half, half - 1, 30 do
		local cx, cy = x + 15, y + 15
		local m = math.noise(cx / 650, cy / 650, 51.3) * 1.5 + math.noise(cx / 210, cy / 210, 52.9) * 0.6
		out[#out + 1] = string.format("%s %.3f %.0f %d", g.types[g:domAt(cx, cy)], m, g:naturalHeight(cx, cy), excluded(cx, cy))
	end
end
print(table.concat(out, "\n"))
