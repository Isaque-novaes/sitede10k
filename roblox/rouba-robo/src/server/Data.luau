--[[
	Salva e carrega o progresso com DataStore.

	No Roblox Studio, o salvamento só funciona se você ativar
	"Game Settings > Security > Enable Studio Access to API Services".
	Sem isso o jogo roda normal, só não guarda o progresso.

	Se a leitura falhar, o jogador fica marcado para NÃO salvar, assim um
	erro passageiro do Roblox nunca apaga o progresso verdadeiro.
]]

local DataStoreService = game:GetService("DataStoreService")

local Data = {}

local NOME_DO_COFRE = "RoubaRobo_v1"
local TENTATIVAS = 3

local cofre = nil
local okCofre, erroCofre = pcall(function()
	cofre = DataStoreService:GetDataStore(NOME_DO_COFRE)
end)
if not okCofre then
	warn("[Rouba Robô] DataStore indisponível: " .. tostring(erroCofre))
end

local function chave(player)
	return "jogador_" .. player.UserId
end

function Data.padrao()
	return {
		versao = 1,
		dinheiro = nil, -- nil = usa o dinheiro inicial
		renascimentos = 0,
		robos = {}, -- { { id = "parafusinho", mut = "dourado", vaga = 1 }, ... }
		descobertos = {}, -- { parafusinho = true, ... }
	}
end

-- Retorna (dados, podeSalvar)
function Data.carregar(player)
	if not cofre then
		return Data.padrao(), false
	end
	for tentativa = 1, TENTATIVAS do
		local ok, resultado = pcall(function()
			return cofre:GetAsync(chave(player))
		end)
		if ok then
			if type(resultado) == "table" then
				local dados = Data.padrao()
				for k, v in pairs(resultado) do
					dados[k] = v
				end
				return dados, true
			end
			return Data.padrao(), true
		end
		warn(string.format("[Rouba Robô] Falha ao carregar %s (tentativa %d): %s",
			player.Name, tentativa, tostring(resultado)))
		if string.find(tostring(resultado), "Studio", 1, true) then
			-- Studio sem acesso às APIs: não adianta tentar de novo
			break
		end
		if tentativa < TENTATIVAS then
			task.wait(1.5 * tentativa)
		end
	end
	return Data.padrao(), false
end

function Data.salvar(player, dados)
	if not cofre then
		return false
	end
	for tentativa = 1, TENTATIVAS do
		local ok, erro = pcall(function()
			cofre:SetAsync(chave(player), dados, { player.UserId })
		end)
		if ok then
			return true
		end
		warn(string.format("[Rouba Robô] Falha ao salvar %s (tentativa %d): %s",
			player.Name, tentativa, tostring(erro)))
		if tentativa < TENTATIVAS then
			task.wait(1.5 * tentativa)
		end
	end
	return false
end

return Data
