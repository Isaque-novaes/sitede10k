--[[
	Loja com Robux: passes (compra única), pacotes de moedas e o anúncio
	com prêmio.

	Regra do jogo: nada aqui deixa o jogador mais forte na luta. Só XP e
	moedas mais rápido, e visual. Num jogo de PvP, vender poder faz quem
	não paga ir embora, e aí não sobra ninguém para pagar.

	Só funciona depois que você cria os itens no Creator Hub e cola os
	números em Config.LOJA. Itens com id = 0 ficam desligados.
]]

local AdService = game:GetService("AdService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Textos = require(Shared:WaitForChild("Textos"))
local Jogador = require(script.Parent:WaitForChild("Jogador"))

local Robux = {}

Robux.aoComprar = nil -- o Main usa para salvar na hora

local MAX_COMPRAS_GUARDADAS = 50

local passePorId = {}
for _, passe in ipairs(Config.LOJA.PASSES) do
	if passe.id ~= 0 then
		passePorId[passe.id] = passe.chave
	end
end

local function nomePasse(chave)
	return function(idioma)
		return Textos.t(idioma, "passe_" .. chave)
	end
end

-- Passes -----------------------------------------------------------------------
function Robux.verificarPasses(estado)
	for _, passe in ipairs(Config.LOJA.PASSES) do
		if passe.id ~= 0 then
			local ok, tem = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(estado.player.UserId, passe.id)
			end)
			if ok and tem then
				estado.passes[passe.chave] = true
			end
		end
	end
end

-- O VIP ganha a aura dourada na hora (se ainda estiver sem aura)
function Robux.aplicarPasses(estado)
	if estado.passes.vip and estado.aura == "nenhuma" then
		estado.aura = "dourada"
		Jogador.aplicarAura(estado)
	end
	Jogador.atualizarAtributos(estado)
end

-- Produtos ------------------------------------------------------------------------
local function pacotePorId(id)
	for _, pacote in ipairs(Config.LOJA.PACOTES) do
		if pacote.id ~= 0 and pacote.id == id then
			return pacote
		end
	end
	return nil
end

local function entregar(estado, produtoId)
	local player = estado.player
	local pacote = pacotePorId(produtoId)
	if pacote then
		local valor = Jogador.darMoedas(estado, pacote.moedas, true)
		Jogador.avisar(player, "bom", "compra_ok", function(idioma)
			return Textos.t(idioma, "premio_moedas", valor)
		end)
		Jogador.remotos.Efeito:FireClient(player, "premio")
		Jogador.atualizarAtributos(estado)
		return true
	end
	local anuncio = Config.LOJA.ANUNCIO
	if anuncio.id ~= 0 and produtoId == anuncio.id then
		estado.xp2Ate = math.max(Jogador.agora(), estado.xp2Ate) + anuncio.minutos * 60
		Jogador.atualizarAtributos(estado)
		Jogador.avisar(player, "bom", "anuncio_ok", anuncio.minutos .. " min")
		return true
	end
	return false
end

local function jaEntregue(estado, compraId)
	for _, id in ipairs(estado.dados.compras) do
		if id == compraId then
			return true
		end
	end
	return false
end

local function processarCompra(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local estado = player and Jogador.estados[player]
	if not estado then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local compraId = tostring(info.PurchaseId)
	if jaEntregue(estado, compraId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if not entregar(estado, info.ProductId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local compras = estado.dados.compras
	table.insert(compras, compraId)
	while #compras > MAX_COMPRAS_GUARDADAS do
		table.remove(compras, 1)
	end
	if Robux.aoComprar then
		Robux.aoComprar(estado)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Anúncio com prêmio ---------------------------------------------------------------
function Robux.verAnuncio(estado)
	local id = Config.LOJA.ANUNCIO.id
	if id == 0 then
		return false
	end
	local ok, resultado = pcall(function()
		local premio = AdService:CreateAdRewardFromDevProductId(id)
		return AdService:ShowRewardedVideoAdAsync(estado.player, premio)
	end)
	if not ok or resultado ~= Enum.ShowAdResult.ShowCompleted then
		if not ok or resultado ~= Enum.ShowAdResult.ShowInterrupted then
			Jogador.avisar(estado.player, "info", "anuncio_indisponivel")
		end
		return false
	end
	return true
end

function Robux.iniciar()
	MarketplaceService.ProcessReceipt = processarCompra
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passeId, comprou)
		local estado = Jogador.estados[player]
		local chave = passePorId[passeId]
		if comprou and estado and chave then
			estado.passes[chave] = true
			Robux.aplicarPasses(estado)
			Jogador.avisar(player, "bom", "passe_ok", nomePasse(chave))
			Jogador.remotos.Efeito:FireClient(player, "premio")
		end
	end)
end

return Robux
