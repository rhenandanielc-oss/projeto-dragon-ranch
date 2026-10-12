--!strict
-- Cópia somente-leitura do perfil no cliente. A interface lê daqui.
-- Alterações reais só acontecem no servidor.

local State = {}

State.Data = nil :: { [string]: any }?

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event -- (key | "*")

function State.SetAll(data: { [string]: any })
	State.Data = data
	changed:Fire("*")
end

function State.Set(key: string, value: any)
	if State.Data then
		State.Data[key] = value
		changed:Fire(key)
	end
end

return State
