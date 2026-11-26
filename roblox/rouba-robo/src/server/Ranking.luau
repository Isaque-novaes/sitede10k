--[[
	Ranking global: os 10 jogadores que mais ganharam dinheiro no total
	(somando todas as partidas, mesmo depois de renascer). Fica no quadro
	ao lado da esteira e é atualizado a cada 2 minutos.

	Usa um OrderedDataStore. No Studio sem acesso às APIs, o quadro só
	mostra "Carregando...".
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Ranking = {}

local LINHAS = 10
local nomes = {} -- cache de userId -> nome

local ordenado = nil
pcall(function()
	ordenado = DataStoreService:GetOrderedDataStore("RankingTotal_v1")
end)

function Ranking.registrar(player, totalGanho)
	if not ordenado then
		return
	end
	local valor = math.floor(math.min(tonumber(totalGanho) or 0, 9e18))
	pcall(function()
		ordenado:SetAsync("u_" .. player.UserId, valor)
	end)
end

local function nomeDe(userId)
	if nomes[userId] then
		return nomes[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		nomes[userId] = player.DisplayName
		return nomes[userId]
	end
	local ok, nome = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(nome) == "string" then
		nomes[userId] = nome
		return nome
	end
	return "?"
end

-- Escreve os resultados como atributos no quadro; cada jogador desenha
-- no seu idioma (R1Nome, R1Valor, ..., RTotal).
function Ranking.atualizar(quadro)
	if not ordenado or not quadro then
		return
	end
	local ok, pagina = pcall(function()
		return ordenado:GetSortedAsync(false, LINHAS):GetCurrentPage()
	end)
	if not ok or type(pagina) ~= "table" then
		return
	end
	local total = 0
	for i, entrada in ipairs(pagina) do
		if i > LINHAS then
			break
		end
		local userId = tonumber(string.sub(tostring(entrada.key), 3))
		if userId then
			total = total + 1
			quadro:SetAttribute("R" .. total .. "Nome", nomeDe(userId))
			quadro:SetAttribute("R" .. total .. "Valor", tonumber(entrada.value) or 0)
		end
	end
	quadro:SetAttribute("RTotal", total)
end

return Ranking
