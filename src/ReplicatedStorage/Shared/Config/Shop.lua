--!strict
-- Fase 4: loja do Tobias (mercador do Hub). Preços vêm de Items (BuyPrice/SellPrice);
-- aqui fica só a ordem de exibição e limites. O mercador paga preço fixo (GAME-DESIGN §13).

local Shop = {}

Shop.Buy = { "Meat", "WaterFlask", "HealthPotion", "Arrow" }
Shop.MaxPerPurchase = 50
Shop.InteractDistance = 18 -- distância máxima do mercador para comprar/vender

-- Ovo do mercador: espécie aleatória, raridade Comum/Incomum (Rarity.MerchantChances).
Shop.EggEnabled = true

return table.freeze(Shop)
