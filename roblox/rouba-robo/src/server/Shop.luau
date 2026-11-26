--[[
	Loja com Robux: passes (compra única), produtos (pacotes de dinheiro,
	sorte do servidor, caixa surpresa) e o anúncio com prêmio.

	Só funciona depois que você cria os itens no Creator Hub e cola os
	números em Config.LOJA. Itens com id = 0 ficam desligados.

	Cada compra é entregue uma única vez: o número da compra (PurchaseId)
	fica guardado no save do jogador, então mesmo que o Roblox repita o
	aviso, ninguém recebe em dobro.
]]

local AdService = game:GetService("AdService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Textos = require(Shared:WaitForChild("Textos"))
local Game = require(script.Parent:WaitForChild("Game"))
local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
local Progresso = require(script.Parent:WaitForChild("Progresso"))

local Shop = {}

Shop.aoComprar = nil -- function(estado): o Main usa para salvar na hora

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

-- Passes ---------------------------------------------------------------------

-- Liga os efeitos dos passes que o jogador tem (vale também ao comprar agora)
local function aplicarPasses(estado)
	if estado.passes.vip and not estado.dados.vipPremiado then
		estado.dados.vipPremiado = true
		local def = Config.sortearDaRaridade(Config.LOJA.VIP_ROBO_RARIDADE, Game.aleatorio())
		Game.darRobo(estado, def, nil)
		Game.notificar(estado.player, "bom", "vip_robo", Game.nomeRobo(def, nil))
	end
	if Game.etiquetaVip then
		Game.etiquetaVip(estado)
	end
	Game.atualizarBase(estado)
	Game.atualizarAtributos(estado)
end

-- Confere no Roblox quais passes o jogador tem. Chamado ao entrar.
function Shop.verificarPasses(estado)
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

function Shop.aplicarPasses(estado)
	aplicarPasses(estado)
end

-- Países que proíbem sorteio pago não veem a caixa surpresa.
-- Se não der para saber, esconde (é o lado seguro).
function Shop.verificarPolitica(estado)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(estado.player)
	end)
	local restrito = true
	if ok and type(info) == "table" then
		restrito = info.ArePaidRandomItemsRestricted == true
	end
	estado.semCaixa = restrito
	estado.player:SetAttribute("SemCaixa", restrito)
end

-- Produtos -------------------------------------------------------------------

local function pacotePorId(id)
	for _, pacote in ipairs(Config.LOJA.PACOTES) do
		if pacote.id ~= 0 and pacote.id == id then
			return pacote
		end
	end
	return nil
end

-- Entrega o produto. Retorna false se o número não é de nenhum produto.
local function entregar(estado, produtoId)
	local player = estado.player
	local pacote = pacotePorId(produtoId)
	if pacote then
		local valor = Config.dinheiroDe(pacote, Game.rendaPorSegundo(estado))
		Game.adicionarDinheiro(estado, valor)
		Game.notificar(player, "bom", "compra_ok", Game.dinheiroTexto(valor))
		Game.remotos.Efeito:FireClient(player, "premio")
		return true
	end
	local loja = Config.LOJA
	if loja.SORTE.id ~= 0 and produtoId == loja.SORTE.id then
		Conveyor.iniciarSorte(loja.SORTE.minutos * 60, player.DisplayName)
		return true
	end
	if loja.CAIXA.id ~= 0 and produtoId == loja.CAIXA.id then
		local def, mut = Config.sortearCaixa(Game.aleatorio())
		Game.notificar(player, "bom", "caixa", Game.nomeRobo(def, mut), Game.nomeRaridade(def.raridade))
		Game.darRobo(estado, def, mut)
		Game.remotos.Efeito:FireClient(player, "caixa", nil, Config.Raridades[def.raridade].cor)
		return true
	end
	if loja.ANUNCIO.id ~= 0 and produtoId == loja.ANUNCIO.id then
		if estado.anuncioMotivo == "offline" and (estado.offlinePendente or 0) > 0 then
			Progresso.coletarOffline(estado, true)
		else
			estado.dobroAte = math.max(Game.agora(), estado.dobroAte) + loja.ANUNCIO.minutos * 60
			Game.atualizarAtributos(estado)
			Game.notificar(player, "bom", "anuncio_ok", Game.tempoTexto(estado.dobroAte - Game.agora()))
		end
		estado.anuncioMotivo = nil
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
	local estado = player and Game.estados[player]
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
	if Shop.aoComprar then
		Shop.aoComprar(estado)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Anúncio com prêmio -----------------------------------------------------------
-- motivo: "dobro" (x2 por 10 min) ou "offline" (dobra o dinheiro offline).
-- O prêmio chega pelo ProcessReceipt do produto do anúncio.
function Shop.verAnuncio(estado, motivo)
	local id = Config.LOJA.ANUNCIO.id
	if id == 0 or (motivo ~= "dobro" and motivo ~= "offline") then
		return false
	end
	estado.anuncioMotivo = motivo
	local ok, resultado = pcall(function()
		local premio = AdService:CreateAdRewardFromDevProductId(id)
		return AdService:ShowRewardedVideoAdAsync(estado.player, premio)
	end)
	if not ok or resultado ~= Enum.ShowAdResult.ShowCompleted then
		estado.anuncioMotivo = nil
		if not ok or resultado ~= Enum.ShowAdResult.ShowInterrupted then
			Game.notificar(estado.player, "info", "anuncio_indisponivel")
		end
		return false
	end
	return true
end

function Shop.iniciar()
	MarketplaceService.ProcessReceipt = processarCompra
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passeId, comprou)
		local estado = Game.estados[player]
		local chave = passePorId[passeId]
		if comprou and estado and chave then
			estado.passes[chave] = true
			aplicarPasses(estado)
			Game.notificar(player, "bom", "passe_ok", nomePasse(chave))
			Game.remotos.Efeito:FireClient(player, "premio")
		end
	end)
end

return Shop
