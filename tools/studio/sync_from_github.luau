-- Copia arquivos de src/ do GitHub (por commit) para o Studio.
-- Uso: substituir SHA e FILES e executar no modo Edit. Liga o HttpEnabled só durante a cópia.
local SHA = "__SHA__"
local FILES = { __FILES__ } -- caminhos relativos a src/, ex.: "ServerStorage/WorldGen/WorldGen.lua"
local HS = game:GetService("HttpService")
local base = "https://raw.githubusercontent.com/rhenandanielc-oss/projeto-dragon-ranch/" .. SHA .. "/src/"
local was = HS.HttpEnabled
HS.HttpEnabled = true
local done = {}
local ok, err = pcall(function()
	for _, rel in ipairs(FILES) do
		local src = HS:GetAsync(base .. rel, true)
		local parts = string.split(rel, "/")
		local parent: Instance = game:GetService(parts[1])
		for k = 2, #parts - 1 do
			local child = parent:FindFirstChild(parts[k])
			if not child then
				child = Instance.new("Folder")
				child.Name = parts[k]
				child.Parent = parent
			end
			parent = child
		end
		local file = parts[#parts]
		local cls, name = "ModuleScript", file:gsub("%.lua$", "")
		if file:match("%.server%.lua$") then
			cls, name = "Script", file:gsub("%.server%.lua$", "")
		elseif file:match("%.client%.lua$") then
			cls, name = "LocalScript", file:gsub("%.client%.lua$", "")
		end
		local inst = parent:FindFirstChild(name)
		if not inst or inst.ClassName ~= cls then
			if inst then inst:Destroy() end
			inst = Instance.new(cls)
			inst.Name = name
			inst.Parent = parent
		end
		(inst :: any).Source = src
		local h = 0
		for i = 1, #src do
			h = (h * 31 + string.byte(src, i)) % 2147483647
		end
		table.insert(done, rel .. " " .. h)
	end
end)
HS.HttpEnabled = was
return (ok and "ok\n" or ("ERRO " .. tostring(err) .. "\n")) .. table.concat(done, "\n")
