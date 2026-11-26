--[[
	Loja com Robux (opcional). Só funciona depois que você cria o Passe e
	os Produtos no site do Roblox e coloca os números em Config.Loja.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Game = require(script.Parent:WaitForChild("Game"))

local Shop = {}

Shop.aoComprar = nil -- function(estado): o Main usa para salvar na hora

local function pacotePorId(id)
	for _, pacote in ipairs(Config.Loja.PACOTES) do
		if pacote.id ~= 0 and pacote.id == id then
			return pacote
		end
	end
	return nil
end

function Shop.recompensaDe(estado, pacote)
	return math.max(pacote.minimo, Game.rendaPorSegundo(estado) * 60 * pacote.minutos)
end

function Shop.verificarPasse(estado)
	local passe = Config.Loja.PASSE_DINHEIRO_EM_DOBRO
	if passe == 0 then
		return
	end
	local ok, tem = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(estado.player.UserId, passe)
	end)
	if ok and tem then
		estado.dobro = true
		Game.atualizarAtributos(estado)
	end
end

local function processarCompra(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local estado = player and Game.estados[player]
	local pacote = pacotePorId(info.ProductId)
	if not estado or not pacote then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if estado.compras[info.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local valor = Shop.recompensaDe(estado, pacote)
	Game.adicionarDinheiro(estado, valor)
	estado.compras[info.PurchaseId] = true
	if Shop.aoComprar then
		Shop.aoComprar(estado)
	end
	Game.notificar(player, "Obrigado pela compra! +" .. Format.dinheiro(valor), "bom")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Shop.iniciar()
	MarketplaceService.ProcessReceipt = processarCompra
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passeId, comprou)
		local estado = Game.estados[player]
		if comprou and estado and passeId == Config.Loja.PASSE_DINHEIRO_EM_DOBRO then
			estado.dobro = true
			Game.atualizarAtributos(estado)
			Game.notificar(player, "Dinheiro em dobro ativado!", "bom")
		end
	end)
end

return Shop
