--!strict
-- Monta o "esqueleto" de um dragão gerado em peças nomeadas (body, head, left wing, right wing,
-- tail, front legs, back legs, legs, wings...). Cada peça vira uma junta Motor6D com o pivô no
-- lugar certo (asa na raiz junto ao corpo, cabeça na base do pescoço, cauda na base, patas no
-- quadril). Quem anima é o cliente (Client/Dragon/DragonAnimator), mexendo em Motor6D.Transform.
--
-- Os eixos de cada junta seguem o Root do dragão: -Z = frente, +X = lado direito, +Y = cima.

local DragonRig = {}

local function roleOf(name: string): string
	local n = string.lower(name)
	if string.find(n, "wing") then
		if string.find(n, "left") then
			return "WingL"
		elseif string.find(n, "right") then
			return "WingR"
		end
		return "Wings"
	elseif string.find(n, "head") or string.find(n, "mane") or string.find(n, "whisker") or string.find(n, "horn") then
		return "Head"
	elseif string.find(n, "tail") then
		return "Tail"
	elseif string.find(n, "front") and string.find(n, "leg") then
		return "LegsF"
	elseif (string.find(n, "back") or string.find(n, "hind") or string.find(n, "rear")) and string.find(n, "leg") then
		return "LegsB"
	elseif string.find(n, "leg") then
		return "Legs"
	elseif string.find(n, "body") then
		return "Body"
	end
	return "Other"
end

-- Caixa da peça no espaço do Root: centro e meia-extensão.
local function boxIn(root: BasePart, p: BasePart): (Vector3, Vector3)
	local cf = root.CFrame:ToObjectSpace(p.CFrame)
	local h = p.Size / 2
	local r = { cf.XVector, cf.YVector, cf.ZVector }
	local ex = math.abs(r[1].X) * h.X + math.abs(r[2].X) * h.Y + math.abs(r[3].X) * h.Z
	local ey = math.abs(r[1].Y) * h.X + math.abs(r[2].Y) * h.Y + math.abs(r[3].Y) * h.Z
	local ez = math.abs(r[1].Z) * h.X + math.abs(r[2].Z) * h.Y + math.abs(r[3].Z) * h.Z
	return cf.Position, Vector3.new(ex, ey, ez)
end

local function joint(name: string, root: BasePart, part0: BasePart, part1: BasePart, pivotLocal: Vector3)
	local pivotWorld = root.CFrame * CFrame.new(pivotLocal) -- orientação do Root
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = part0.CFrame:ToObjectSpace(pivotWorld)
	m.C1 = part1.CFrame:ToObjectSpace(pivotWorld)
	m.Parent = part1
end

-- `container` = Model/Folder com as peças da malha (já posicionadas sobre o Root).
-- Remove soldas antigas e cria as juntas. Retorna quantas juntas foram criadas.
function DragonRig.Rig(container: Instance, root: BasePart): number
	local parts: { BasePart } = {}
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			table.insert(parts, d)
		end
	end
	if #parts == 0 then
		return 0
	end
	-- corpo = peça "body" (ou a maior)
	local body: BasePart? = nil
	for _, p in ipairs(parts) do
		if roleOf(p.Name) == "Body" then
			body = p
		end
	end
	if not body then
		local best = 0
		for _, p in ipairs(parts) do
			local v = p.Size.X * p.Size.Y * p.Size.Z
			if v > best then
				best = v
				body = p
			end
		end
	end
	local b = body :: BasePart
	for _, p in ipairs(parts) do
		for _, w in ipairs(p:GetChildren()) do
			if w:IsA("WeldConstraint") or w:IsA("Weld") or w:IsA("Motor6D") then
				w:Destroy()
			end
		end
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
	end
	local bc = boxIn(root, b)
	joint("J_Body", root, root, b, bc)
	local n = 1
	for _, p in ipairs(parts) do
		if p == b then
			continue
		end
		local role = roleOf(p.Name)
		local c, h = boxIn(root, p)
		local pivot: Vector3
		if role == "WingL" or role == "WingR" then
			local side = if c.X >= bc.X then 1 else -1
			role = if side > 0 then "WingR" else "WingL"
			-- raiz da asa: borda interna, um pouco abaixo do meio
			pivot = Vector3.new(c.X - side * h.X * 0.92, c.Y - h.Y * 0.35, c.Z)
		elseif role == "Wings" then
			pivot = Vector3.new(c.X, c.Y - h.Y * 0.4, c.Z + h.Z * 0.2)
		elseif role == "Head" then
			-- base do pescoço: parte de trás e de baixo da peça da cabeça
			pivot = Vector3.new(c.X, c.Y - h.Y * 0.55, c.Z + h.Z * 0.6)
		elseif role == "Tail" then
			-- base da cauda: o ponto da caixa mais perto do corpo
			local toward = bc - c
			pivot = Vector3.new(c.X + math.clamp(toward.X, -h.X, h.X), c.Y + math.clamp(toward.Y, -h.Y, h.Y) * 0.6, c.Z + math.clamp(toward.Z, -h.Z, h.Z))
		elseif role == "LegsF" or role == "LegsB" or role == "Legs" then
			pivot = Vector3.new(c.X, c.Y + h.Y * 0.9, c.Z)
		else
			pivot = c
			role = "Other"
		end
		if role == "Other" then
			local w = Instance.new("WeldConstraint")
			w.Part0 = b
			w.Part1 = p
			w.Parent = p
		else
			joint("J_" .. role, root, b, p, pivot)
			n += 1
		end
	end
	return n
end

return DragonRig
