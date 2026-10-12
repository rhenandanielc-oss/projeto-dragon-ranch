-- Importa modelos de dragão gerados por IA (soltos no Workspace) para
-- ServerStorage.DragonAssets.<Espécie>.<Egg|Baby|Adult>.
-- Para cada modelo:
--   * renomeia e guarda na pasta certa (substitui o anterior);
--   * calcula YawDegrees: o giro que deixa a cabeça apontando para -Z (frente do Root);
--   * remove tags de geração e deixa as peças ancoradas na origem.
-- Uso: preencher MAP com { prefixo do nome no Workspace = "Espécie/Estágio" } e executar no modo Edit.

local ServerStorage = game:GetService("ServerStorage")

local MAP = {
	-- ["Realistic fantasy wyvern dragon, adult"] = "Wyvern/Adult",
}

local root = ServerStorage:FindFirstChild("DragonAssets") or Instance.new("Folder")
root.Name = "DragonAssets"
root.Parent = ServerStorage

local function centerOf(model: Instance): Vector3?
	local parts = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	if model:IsA("BasePart") then
		table.insert(parts, model)
	end
	if #parts == 0 then
		return nil
	end
	local sum = Vector3.zero
	for _, p in ipairs(parts) do
		sum += p.Position
	end
	return sum / #parts
end

local function findChild(model: Model, word: string): Instance?
	for _, c in ipairs(model:GetChildren()) do
		if string.find(string.lower(c.Name), word, 1, true) then
			return c
		end
	end
	return nil
end

local done = {}
for _, m in ipairs(workspace:GetChildren()) do
	if m:IsA("Model") then
		for prefix, path in pairs(MAP) do
			if string.sub(m.Name, 1, #prefix) == prefix then
				local species, stage = string.match(path, "^(%w+)/(%w+)$")
				local folder = root:FindFirstChild(species) or Instance.new("Folder")
				folder.Name = species
				folder.Parent = root
				local old = folder:FindFirstChild(stage)
				if old then
					old:Destroy()
				end

				-- direção da cabeça em relação ao corpo -> giro para olhar para -Z
				local yaw = 0
				local head = findChild(m, "head")
				local body = findChild(m, "body")
				if head and body then
					local hc, bc = centerOf(head), centerOf(body)
					if hc and bc then
						local f = Vector3.new(hc.X - bc.X, 0, hc.Z - bc.Z)
						if f.Magnitude > 0.1 then
							f = f.Unit
							-- CFrame.Angles(0, t, 0).LookVector = (-sin t, 0, -cos t)
							local current = math.atan2(-f.X, -f.Z)
							yaw = -math.deg(current)
						end
					end
				end

				for _, tag in ipairs(m:GetTags()) do
					m:RemoveTag(tag)
				end
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = false
					end
				end
				-- pivô sem rotação (a geometria não muda); assim o YawDegrees vale em relação ao mundo
				m.WorldPivot = CFrame.new(m:GetBoundingBox().Position)
				m:PivotTo(CFrame.new(0, 0, 0))
				m.Name = stage
				m:SetAttribute("YawDegrees", math.floor(yaw + 0.5))
				m.Parent = folder
				local _, size = m:GetBoundingBox()
				table.insert(done, string.format("%s yaw=%d tamanho=%.1fx%.1fx%.1f", path, math.floor(yaw + 0.5), size.X, size.Y, size.Z))
			end
		end
	end
end
return "Importados:\n" .. table.concat(done, "\n")
